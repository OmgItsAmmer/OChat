/*
👥 USERS MODULE
===============

This module handles all user-related operations for the OChat backend.
It provides endpoints to fetch user information from Supabase database.

RUST CONCEPTS EXPLAINED:
- `async fn`: Functions that can be "awaited" - they don't block the thread
- `web::Data<T>`: Shared application state (dependency injection)
- `web::ReqData<T>`: Request-specific data extracted by middleware
- `Result<T, E>`: Rust's way of handling success/error cases

AUTHENTICATION FLOW:
1. Flutter sends JWT token in Authorization header
2. Middleware extracts and validates JWT
3. Claims are passed to handler functions
4. Handler verifies user permissions and processes request
*/

use actix_web::{web, HttpRequest, HttpResponse, HttpMessage};
use serde_json::json;
use uuid::Uuid;
use crate::auth::auth::{Claims, jwt_middleware};
use crate::supabase_api::SupabaseClient;
use crate::errors::AppResult;

/// 👥 GET ALL USERS ENDPOINT (NO AUTHENTICATION)
/// 
/// 🚨 TEMPORARY: No authentication required - for testing only!
/// =============================================================
/// 
/// 🔰 BEGINNER EXPLANATION: What this does now
/// ===========================================
/// 1. ✅ No JWT token required
/// 2. ✅ Fetches all users from Supabase database  
/// 3. ✅ Returns user list directly
/// 4. ✅ No security checks (TEMPORARY!)
pub async fn get_all_users(
    req: HttpRequest,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    log::info!("🔍 Fetching all users (NO AUTH MODE)");

    // 🗄️ QUERY SUPABASE FOR USERS - NO AUTH REQUIRED
    match supabase_client.get_all_users().await {
        Ok(users) => {
            log::info!("✅ Successfully retrieved {} users", users.len());
            
            // 📤 RETURN RESPONSE IN EXPECTED FORMAT
            Ok(HttpResponse::Ok().json(json!({
                "users": users,
                "status": "success", 
                "message": format!("Retrieved {} users", users.len())
            })))
        }
        Err(e) => {
            log::error!("❌ Failed to fetch users from Supabase: {}", e);
            
            Ok(HttpResponse::InternalServerError().json(json!({
                "error": "failed_to_fetch_users",
                "message": "Unable to retrieve users from database",
                "details": e.to_string()
            })))
        }
    }
}

/// 👤 GET USER BY ID ENDPOINT (NO AUTHENTICATION)
/// 
/// This endpoint retrieves a specific user by their ID.
/// No authentication required for testing.
pub async fn get_user_by_id(
    path: web::Path<String>,
    req: HttpRequest,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let target_user_id = path.into_inner();
    let user_uuid = Uuid::parse_str(&target_user_id)
        .map_err(|_| crate::errors::AppError::bad_request("Invalid user ID format"))?;

    log::info!("🔍 Fetching user: {} (NO AUTH MODE)", user_uuid);

    // 🗄️ QUERY SUPABASE FOR SPECIFIC USER - NO AUTH REQUIRED
    match supabase_client.get_user(user_uuid, "dummy_token").await {
        Ok(Some(user)) => {
            log::info!("✅ Successfully retrieved user: {}", user.id);
            
            Ok(HttpResponse::Ok().json(json!({
                "user": user,
                "status": "success"
            })))
        }
        Ok(None) => {
            log::warn!("⚠️ User not found: {}", user_uuid);
            
            Ok(HttpResponse::NotFound().json(json!({
                "error": "user_not_found",
                "message": "User with specified ID does not exist",
                "user_id": target_user_id
            })))
        }
        Err(e) => {
            log::error!("❌ Failed to fetch user from Supabase: {}", e);
            
            Ok(HttpResponse::InternalServerError().json(json!({
                "error": "failed_to_fetch_user",
                "message": "Unable to retrieve user from database",
                "details": e.to_string()
            })))
        }
    }
}

// 🛤️ CONFIGURE ROUTES
// This function sets up all the user-related routes
/// RUST PATTERN: Configuration functions keep route setup organized
/// This is called from main.rs to register our endpoints
pub fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/users")
            .route("", web::get().to(get_all_users))          // GET /users - Get all users
            .route("/{user_id}", web::get().to(get_user_by_id)) // GET /users/{id} - Get specific user
    );
}