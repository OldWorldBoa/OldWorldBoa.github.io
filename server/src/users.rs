use libsql::Builder;
use rocket::serde::json::Json;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct User {
    id: i64,
    name: String,
    user_name: String,
    email: String,
}

#[get("/user/<user_id>")]
pub async fn get_user_by_id(user_id: i64) -> Json<User> {
    Json(db_get_user_by_id(user_id).await.unwrap())
}

async fn db_get_user_by_id(user_id: i64) -> libsql::Result<User> {
    let db = Builder::new_local("blog.db").build().await?;
    let conn = db.connect()?;

    let mut rows = conn
        .query(
            r#"
        SELECT id, name, username, email
        FROM user
        WHERE id=?1"#,
            libsql::params![user_id],
        )
        .await?;

    if let Some(row) = rows.next().await? {
        let id: i64 = row.get(0)?;
        let name: String = row.get(1)?;
        let user_name: String = row.get(2)?;
        let email: String = row.get(3)?;

        Ok(User {
            id,
            name,
            user_name,
            email,
        })
    } else {
        panic!("Unable to find user {user_id}")
    }
}
