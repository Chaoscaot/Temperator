// @generated automatically by Diesel CLI.

diesel::table! {
    datapoints (time) {
        time -> Timestamp,
        humidity -> Float,
        air_temp -> Float,
        water_temp -> Float,
    }
}
