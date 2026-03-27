use rocket::serde::json::Json;

use crate::comments::comment_list;
use crate::comments::get_comments;
use crate::comments::Comment;

#[macro_use]
extern crate rocket;

mod comments;
mod schema;

#[get("/ping")]
async fn index() -> &'static str {
    "pong"
}

#[launch]
async fn rocket() -> _ {
    match schema::migrate().await {
        Ok(_) => println!("Database migrated."),
        Err(e) => println!("{}", e),
    }

    rocket::build()
        .mount("/", routes![index])
        .mount("/", routes![comment_list])
}
