use libsql::Builder;
use rocket::serde::json::Json;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct Member {
    id: i64,
    name: String,
    user_name: String,
    email: String,
}

#[get("/admin/member/<member_id>")]
pub async fn get_member_by_id(member_id: i64) -> Json<Member> {
    Json(db_get_member_by_id(member_id).await.unwrap())
}

async fn db_get_member_by_id(user_id: i64) -> libsql::Result<Member> {
    let db = Builder::new_local("blog.db").build().await?;
    let conn = db.connect()?;

    let mut rows = conn
        .query(
            r#"
        SELECT id, name, username, email
        FROM members
        WHERE id=?1"#,
            libsql::params![user_id],
        )
        .await?;

    if let Some(row) = rows.next().await? {
        let id: i64 = row.get(0)?;
        let name: String = row.get(1)?;
        let user_name: String = row.get(2)?;
        let email: String = row.get(3)?;

        Ok(Member {
            id,
            name,
            user_name,
            email,
        })
    } else {
        panic!("Unable to find user {user_id}")
    }
}
