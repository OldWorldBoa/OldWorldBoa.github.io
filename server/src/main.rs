#[macro_use]
extern crate rocket;

mod schema;
mod comments;

#[get("/ping")]
async fn index() -> &'static str {
    "pong"
}

#[get("/comments")]
async fn comment_list() -> {
}

#[launch]
async fn rocket() -> _ {
    match schema::migrate().await {
        Ok(_) => println!("Database migrated."),
        Err(e) => println!("{}", e),
    }

    rocket::build().mount("/", routes![index])
}
