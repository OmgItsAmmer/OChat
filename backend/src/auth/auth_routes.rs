use actix_web::{get, post, web, HttpResponse, Responder, Scope};
use serde::Deserialize;
use serde_json::json;


#[derive(Deserialize)]
pub struct AuthPayload {
    pub email: String,
    pub password: String,
}


#[post("/login")]
async fn login(payload: web::Json<AuthPayload>) -> impl Responder {
    HttpResponse::Ok().json(json!({
        "token": "example-token",
        "email": payload.email.clone(),
    }))
}


#[post("/signup")]
async fn signup(payload: web::Json<AuthPayload>) -> impl Responder {
    // Call Supabase signup API
    HttpResponse::Ok().body(format!("User {} signed up", payload.email))
}

#[get("/ping")]
async fn ping() -> impl Responder {
    HttpResponse::Ok().json({
        serde_json::json!({
            "status": "ok",
            "message": "Rust backend is reachable ✅"
        })
    })
}

pub fn auth_routes() -> Scope {
    web::scope("/auth")
        .service(login)
        .service(signup)
        .service(ping)  // 👈 Add this line
}

