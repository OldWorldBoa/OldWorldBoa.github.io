use libsql::Database;
use rocket::{State, serde::json::Json};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct Member {
    id: i64,
    name: String,
    user_name: String,
    email: String,
}

#[get("/admin/member/<member_id>")]
pub async fn get_member_by_id(member_id: i64, db: &State<Database>) -> Json<Member> {
    Json(db_get_member_by_id(member_id, db).await.unwrap())
}

async fn db_get_member_by_id(user_id: i64, db: &State<Database>) -> libsql::Result<Member> {
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

#[cfg(test)]
mod tests {
    use crate::launch::rocket;
    use crate::schema;

    use super::Member;
    use libsql::{Builder, Result};
    use rocket::http::Status;
    use rocket::local::asynchronous::Client;

    #[tokio::test]
    async fn when_get_member_returns_member() -> Result<()> {
        let db = Builder::new_local("members_tests.db")
            .build()
            .await
            .unwrap();
        schema::migrate(&db).await.unwrap();

        let client = Client::tracked(rocket(db))
            .await
            .expect("valid rocket instance");

        let response = client
            .get(uri!(super::get_member_by_id(1)))
            .dispatch()
            .await;

        assert_eq!(response.status(), Status::Ok);
        let member: Member = serde_json::from_str(&response.into_string().await.unwrap()).unwrap();

        assert_eq!("anon", member.name);
        assert_eq!("anon", member.user_name);
        assert_eq!("anon", member.email);

        Ok(())
    }
}
