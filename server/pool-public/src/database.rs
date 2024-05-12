use diesel::{MysqlConnection};
use diesel::r2d2::{ConnectionManager, Pool};

pub fn establish_connection() -> Pool<ConnectionManager<MysqlConnection>> {
    let database_url = std::env::var("DATABASE_URL").unwrap_or("mysql://root@localhost:3306/new_pool".to_owned());
    Pool::builder()
        .min_idle(Some(1))
        .build(ConnectionManager::<MysqlConnection>::new(database_url)).expect("TODO: panic message")
}