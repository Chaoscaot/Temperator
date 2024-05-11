use std::sync::Arc;
use axum::extract::{Request, State, WebSocketUpgrade};
use axum::extract::ws::{Message, WebSocket};
use axum::http::{StatusCode};
use axum::response::{IntoResponse, Response};
use axum::{Error, Json, middleware, Router};
use axum::middleware::Next;
use axum::routing::{get, post};
use chrono::{DateTime, Local, NaiveDateTime};
use diesel::{ExpressionMethods, insert_into, MysqlConnection, QueryDsl, RunQueryDsl, sql_query};
use diesel::prelude::*;
use diesel::query_dsl::methods::OrderDsl;
use diesel::query_dsl::positional_order_dsl::IntoOrderColumn;
use futures_util::{SinkExt, StreamExt};
use serde::Serialize;
use serde_json::Value;
use tokio::sync::{watch, Mutex};
use tokio::sync::watch::error::RecvError;
use tokio::sync::watch::Ref;
use tokio::time::sleep;
use pool_shared::types::{InternalMessage, Temperature};
use crate::{database, schema};

const TOKEN: &str = include_str!("token.txt");

#[derive(Clone)]
struct AppState {
    db: Arc<Mutex<MysqlConnection>>,
    connected: Arc<Mutex<bool>>,
    to_tx: Arc<Mutex<watch::Sender<InternalMessage>>>,
    to_rx: Arc<Mutex<watch::Receiver<InternalMessage>>>,
    from_tx: Arc<Mutex<watch::Sender<InternalMessage>>>,
    from_rx: Arc<Mutex<watch::Receiver<InternalMessage>>>,

    last_pump_toggle: Arc<Mutex<NaiveDateTime>>,
}

#[derive(Serialize, Debug)]
struct Datapoint {
    time: i64,
    humidity: Option<f32>,
    air_temp: Option<f32>,
    water_temp: Option<f32>,
    pump: Option<bool>,
    last_pump_toggle: Option<i64>,
}

impl Datapoint {
    fn from(value: Temperature, last_pump_toggle: i64) -> Self {
        Datapoint {
            time: chrono::Utc::now().timestamp_millis(),
            humidity: value.humidity,
            air_temp: value.air_temp,
            water_temp: value.water_temp,
            pump: value.pump_state,
            last_pump_toggle: Some(last_pump_toggle),
        }
    }
}

async fn index_handler(State(state): State<Arc<AppState>>) -> Result<Json<Value>, StatusCode> {
    let connected = *state.connected.lock().await;
    if connected {
        state.to_tx.lock().await.send(InternalMessage::RequestTemperature).unwrap();
        let mut from_rx = state.from_tx.lock().await.subscribe();
        let mut temp = None;
        while let Ok(_) = from_rx.changed().await {
            let message = *from_rx.borrow_and_update();
            if let InternalMessage::Temperature(tmp) = message {
                temp = Some(tmp);
                break;
            }
        }

        Ok(Json(serde_json::to_value(Datapoint::from(temp.ok_or(StatusCode::INTERNAL_SERVER_ERROR)?, state.last_pump_toggle.lock().await.and_utc().timestamp_millis())).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?))
    } else {
        let db = &mut *state.db.lock().await;
        use schema::datapoints::dsl::*;

        let dp = OrderDsl::order(datapoints.select(crate::models::Datapoint::as_select()), time.desc()).first(db).map_err(|e| {
            println!("Error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

        Ok(Json(serde_json::to_value(Datapoint {
            time: dp.time.and_utc().timestamp_millis(),
            humidity: Some(dp.humidity),
            air_temp: Some(dp.air_temp),
            water_temp: Some(dp.water_temp),
            pump: None,
            last_pump_toggle: None,
        }).map_err(|e| {
            println!("Error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?))
    }
}

async fn websocket_handler(ws: WebSocketUpgrade, State(state): State<Arc<AppState>>) -> impl IntoResponse {
    ws.on_upgrade(|socket| websocket(socket, state))
}

async fn websocket(ws: WebSocket, state: Arc<AppState>) {
    *state.connected.lock().await = true;
    *state.last_pump_toggle.lock().await = Local::now().naive_local();
    let (mut sender, mut receiver) = ws.split();

    let mut to_rx = state.to_tx.lock().await.subscribe();

    let state_clone = state.clone();
    let state_clone2 = state.clone();

    let mut t1 = tokio::spawn(async move {
        while let Some(message) = receiver.next().await {
            let message = match message {
                Ok(x) => x,
                Err(_) => return
            };
            tracing::info!("Received message: {:?}", message);
            match message {
                Message::Text(text) => {
                    tracing::info!("Received text message: {:?}", text);
                    state.from_tx.lock().await.send(serde_json::from_str(text.as_str()).unwrap()).unwrap();
                }
                _ => {
                    tracing::warn!("Received non-text message");
                }
            }
        }
    });

    let mut t2 = tokio::spawn(async move {
        while let Ok(_) = to_rx.changed().await {
            let message = *to_rx.borrow_and_update();
            tracing::info!("Sending message: {:?}", message);
            match sender.send(Message::Text(serde_json::to_string(&message).unwrap())).await {
                Ok(_) => {}
                Err(_) => return
            };
        }
    });

    let mut t3 = tokio::spawn(async move {
        loop {
            let msg = *match state_clone.from_rx.lock().await.wait_for(|v| if let InternalMessage::Temperature(_) = v { true } else { false }).await {
                Ok(x) => x,
                Err(_) => return
            };
            let dp = if let InternalMessage::Temperature(temp) = msg { Datapoint::from(temp, 0) } else { return; };

            use schema::datapoints::dsl::*;

            insert_into(datapoints)
                .values((time.eq(DateTime::from_timestamp_millis(dp.time).unwrap().naive_utc()), humidity.eq(dp.humidity.unwrap_or(0f32)), air_temp.eq(dp.air_temp.unwrap_or(0f32)), water_temp.eq(dp.water_temp.unwrap_or(0f32))))
                .execute(&mut *state_clone.db.lock().await).unwrap();

            sleep(tokio::time::Duration::from_secs(60 * 10)).await;
        }
    });

    tokio::select! {
        _ = &mut t1 => {
            t2.abort();
            t3.abort();
        },
        _ = &mut t2 => {
            t1.abort();
            t3.abort();
        },
        _ = &mut t3 => {
            t1.abort();
            t2.abort();
        },
    };

    *state_clone2.connected.lock().await = false;
}

async fn pump_handler(State(state): State<Arc<AppState>>) -> Result<Json<Value>, StatusCode> {
    state.to_tx.lock().await.send(InternalMessage::TogglePump).unwrap();
    *state.last_pump_toggle.lock().await = Local::now().naive_local();
    let mut from_rx = state.from_rx.lock().await;
    let msg = from_rx.wait_for(|m| {
        if let InternalMessage::PumpState(_) = m {
            true
        } else {
            false
        }
    }).await.unwrap();
    let pump_state = if let InternalMessage::PumpState(pump_state) = *msg { pump_state } else { unreachable!() };

    Ok(Json(serde_json::to_value(pump_state).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?))
}

async fn chart_data(State(state): State<Arc<AppState>>) -> Result<Json<Value>, StatusCode> {
    let db = &mut *state.db.lock().await;

    let data = sql_query("SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(time) - MOD(UNIX_TIMESTAMP(time), 3600)) as hour, AVG(humidity) as humidity, AVG(air_temp) as air_temp, AVG(water_temp) as water_temp FROM datapoints WHERE TIMESTAMPDIFF(hour, time, NOW()) < 24 GROUP BY hour")
        .load::<crate::models::ChartData>(db);

    #[derive(Serialize)]
    struct ChartDataResponse {
        hour: i64,
        humidity: f32,
        air_temp: f32,
        water_temp: f32,
    }

    let data = data.map(|data| {
        data.into_iter().map(|data| {
            ChartDataResponse {
                hour: data.hour.and_utc().timestamp_millis(),
                humidity: data.humidity,
                air_temp: data.air_temp,
                water_temp: data.water_temp,
            }
        }).collect::<Vec<_>>()
    });

    match data {
        Ok(data) => {
            Ok(Json(serde_json::to_value(data).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?))
        },
        Err(e) => {
            println!("Error: {:?}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

async fn request_validator(
    request: Request,
    next: Next,
) -> Response {
    let token = request.headers().get("X-Token");
    if token.is_none() || token.unwrap() != TOKEN {
        return Response::builder().status(StatusCode::UNAUTHORIZED).body("Unauthorized".into()).unwrap();
    }

    let response = next.run(request).await;

    response
}

pub fn get_app() -> Router {
    let db = database::establish_connection();
    let (to_tx, to_rx) = watch::channel(InternalMessage::RequestTemperature);
    let (from_tx, from_rx) = watch::channel(InternalMessage::PumpState(false));

    let from_rx = Arc::new(Mutex::new(from_rx));
    let to_rx = Arc::new(Mutex::new(to_rx));
    let from_tx = Arc::new(Mutex::new(from_tx));
    let to_tx = Arc::new(Mutex::new(to_tx));

    let state = Arc::new(AppState { db: Arc::new(Mutex::new(db)), connected: Arc::new(Mutex::new(false)), to_tx, to_rx, from_tx, from_rx, last_pump_toggle: Arc::new(Mutex::new(Local::now().naive_utc())) });

    Router::new()
        .route("/ws", get(websocket_handler))
        .route("/current", get(index_handler))
        .route("/pump", post(pump_handler))
        .route("/chart", get(chart_data))
        .route_layer(middleware::from_fn(request_validator))
        .with_state(state)
}