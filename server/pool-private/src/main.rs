use std::sync::Arc;
use std::time::Duration;
use futures_util::{SinkExt, StreamExt};
use tokio::io::{AsyncReadExt, AsyncWriteExt, split};
use tokio::net::TcpListener;
use tokio::sync::Mutex;
use tokio::time::sleep;
use tokio_tungstenite::{connect_async};
use tokio_tungstenite::tungstenite::http::Request;
use tokio_tungstenite::tungstenite::{Message};
use pool_shared::types::InternalMessage;

fn checked_sub(num: usize, sub: usize) -> usize {
    if num < sub {
        0
    } else {
        num - sub
    }
}

async fn process(socket: tokio::net::TcpStream) {
    let (read, write) = split(socket);
    let arc_read = Arc::new(Mutex::new(read));
    let arc_write = Arc::new(Mutex::new(write));


    let (ws, _) = connect_async(
        Request::builder().uri("wss://pool.chaoscaot.de/api/v1/ws")
            .header("X-Token", include_str!("../../pool-public/src/api/token.txt"))
            .header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
            .header("host", "pool.chaoscaot.de")
            .header("upgrade", "websocket")
            .header("connection", "upgrade")
            .header("sec-websocket-version", 13)
            .body(())
            .unwrap(),
    ).await.unwrap();
    let (mut ws_write, mut ws_read) = ws.split();

    let mut t1 = tokio::spawn(async move {
        let mut index = 0;
        let mut buffer = [0; 1024];
        loop {
            while buffer[checked_sub(index, 1)] != b'\n' {
                let n = match arc_read.lock().await.read(&mut buffer[index..]).await {
                    Ok(x) => x,
                    Err(_) => return,
                };
                index += n;
            }

            let str = String::from_utf8_lossy(&buffer[..index]).to_string();

            println!("Received: {:?}", str);
            if str.trim() != "Connected!" {
                let msg = InternalMessage::try_from(str).unwrap();
                ws_write.send(Message::Text(serde_json::to_string(&msg).unwrap())).await.unwrap();
            }
            index = 0;
        }
    });

    let arc_write_copy = arc_write.clone();

    let mut t2 = tokio::spawn(async move {
        while let Some(message) = ws_read.next().await {
            let message = match message {
                Ok(x) => x,
                Err(e) => return
            };
            match message {
                Message::Text(text) => {
                    let msg = serde_json::from_str(text.as_str()).unwrap();
                    println!("Internal: {:?}", msg);
                    match msg {
                        InternalMessage::RequestTemperature => {
                            arc_write_copy.lock().await.write_all(b"send\n").await.unwrap()
                        }
                        InternalMessage::TogglePump => {
                            arc_write_copy.lock().await.write_all(b"pump\n").await.unwrap()
                        }
                        _ => {}
                    }
                }
                _ => {}
            }
        }
    });

    let mut t3 = tokio::spawn(async move {
        loop {
            arc_write.lock().await.write_all(b"send\n").await.expect("Failed to write to socket");
            sleep(Duration::from_secs(10)).await;
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
    }
}

#[tokio::main]
async fn main() {
    let listener = TcpListener::bind("0.0.0.0:8090").await.unwrap();

    println!("Listening");

    loop {
        let (socket, _) = listener.accept().await.unwrap();

        tokio::spawn(async move {
            process(socket).await;
        });
    }
}