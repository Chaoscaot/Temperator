use diesel::{Connection, MysqlConnection};

pub fn establish_connection() -> MysqlConnection {
    let database_url = std::env::var("DATABASE_URL").unwrap_or("mysql://root@localhost:3306/new_pool".to_owned());
    MysqlConnection::establish(&database_url).expect("Failed to connect to database")
}