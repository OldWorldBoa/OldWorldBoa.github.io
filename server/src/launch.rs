use libsql::Database;
use rocket::{Build, Rocket};

use crate::{
    comments::{
        create_comment, delete_comments, get_comments, get_comments_by_post, update_comment,
    },
    index,
    members::get_member_by_id,
    posts::{create_post, delete_post, get_posts, update_post},
};

pub fn rocket(db: Database) -> Rocket<Build> {
    let base = "/";
    rocket::build()
        .mount(base, routes![index])
        .mount(
            base,
            routes![
                get_comments_by_post,
                create_comment,
                get_comments,
                update_comment,
                delete_comments
            ],
        )
        .mount(base, routes![get_member_by_id])
        .mount(
            base,
            routes![get_posts, create_post, update_post, delete_post],
        )
        .manage(db)
}
