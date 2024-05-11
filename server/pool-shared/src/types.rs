use serde::{Deserialize, Serialize};

#[derive(Debug, Copy, Clone, Serialize, Deserialize)]
pub enum InternalMessage {
    Temperature(Temperature),
    RequestTemperature,
    PumpState(bool),
    TogglePump,
    NOOP,
}

impl TryFrom<String> for InternalMessage {
    type Error = ();

    fn try_from(value: String) -> Result<Self, Self::Error> {
        if value.trim_end().len() == 1 {
            match value.trim_end() {
                "0" => Ok(InternalMessage::PumpState(false)),
                "1" => Ok(InternalMessage::PumpState(true)),
                _ => Err(()),
            }
        } else {
            Ok(InternalMessage::Temperature(Temperature::try_from(value)?))
        }
    }
}

#[derive(Debug, Copy, Clone, Serialize, Deserialize)]
pub struct Temperature {
    pub air_temp: Option<f32>,
    pub water_temp: Option<f32>,
    pub humidity: Option<f32>,
    pub pump_state: Option<bool>,
}

impl TryFrom<String> for Temperature {
    type Error = ();

    fn try_from(value: String) -> Result<Self, Self::Error> {
        println!("Value: {:?}", value);
        let keys = value.trim().split(";").map(|s| s.split(":").collect::<Vec<&str>>()).map(|v| (v[0].to_string(), v[1].parse::<f32>().ok())).collect::<Vec<(String, Option<f32>)>>();

        let mut dp = Temperature {
            humidity: None,
            air_temp: None,
            water_temp: None,
            pump_state: None,
        };

        for (key, value) in keys {
            match key.as_str() {
                "Hum" => dp.humidity = value,
                "TempPool" => dp.water_temp = value,
                "TempAir" => dp.air_temp = value,
                "Pump" => dp.pump_state = value.map(|v| v > 0.0),
                _ => {}
            }
        }

        Ok(dp)
    }
}