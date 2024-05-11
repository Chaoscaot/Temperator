use chrono::NaiveDateTime;
use diesel::prelude::*;
use diesel::sql_types::{Float};
use diesel::mysql::sql_types::Datetime;

use crate::schema::datapoints;

#[derive(Queryable, Selectable, Insertable)]
#[diesel(table_name = datapoints)]
#[diesel(check_for_backend(diesel::mysql::Mysql))]
pub struct Datapoint {
    pub time: NaiveDateTime,
    pub humidity: f32,
    pub air_temp: f32,
    pub water_temp: f32,
}

#[derive(QueryableByName, PartialEq, Debug)]
#[diesel(check_for_backend(diesel::mysql::Mysql))]
pub struct ChartData {
    #[diesel(sql_type = Datetime)]
    pub hour: NaiveDateTime,
    #[diesel(sql_type = Float)]
    pub humidity: f32,
    #[diesel(sql_type = Float)]
    pub air_temp: f32,
    #[diesel(sql_type = Float)]
    pub water_temp: f32,
}