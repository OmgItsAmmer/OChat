/*
🚀 OCHAT BACKEND - MAIN SERVER ENTRY POINT
===========================================

This is the main entry point for our real-time messaging backend.
We use a modular architecture to keep code organized and maintainable.

RUST CONCEPT: Modules
- In Rust, we organize code into modules using the `mod` keyword
- Each module can be in its own file (like `auth.rs`) or folder (like `auth/mod.rs`)
- This helps us separate concerns and makes the code easier to understand

ARCHITECTURE OVERVIEW:
📦 main.rs         -> Server startup and configuration
📦 auth.rs         -> JWT verification and user authentication  
📦 websocket.rs    -> WebSocket connection handling
📦 database.rs     -> Database models and operations
📦 messages.rs     -> Message routing and storage
📦 config.rs       -> Environment configuration
📦 errors.rs       -> Custom error types
*/

// 🔧 EXTERNAL DEPENDENCIES
// These are the external crates (libraries) we're using
use actix_web::{web, App, HttpServer, middleware::Logger};
use actix_web_httpauth::middleware::HttpAuthentication;
use actix_cors::Cors;
use std::env;

// 📦 INTERNAL MODULES  
// These declare our internal modules - each corresponds to a .rs file
mod config;         // Configuration management
mod database;       // Database connection and models (COMMENTED OUT - Using Supabase API)
mod auth;           // Authentication middleware
mod websocket;      // WebSocket handling
mod messages;       // Message operations
mod users;          // User management operations (NEW!)
mod errors;         // Custom error types
mod supabase_api;   // Supabase HTTP API wrapper (ZERO TRUST)
mod encryption;     // End-to-end encryption for messages
mod encrypted_messaging; // Encrypted messaging workflow 

// 🎯 MAIN FUNCTION
// In Rust, async main requires the #[tokio::main] attribute
// This tells Rust to use the Tokio async runtime
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 📝 INITIALIZE LOGGING
    // This sets up logging so we can see what's happening in our app
    env_logger::init();
    
    // ⚙️ LOAD CONFIGURATION
    // Load environment variables from .env file
    dotenvy::dotenv().ok(); // .ok() means "ignore errors if .env doesn't exist"
    
    // Load our configuration struct
    let config = config::Config::from_env()?;
    
    // Validate configuration
    config.validate()?;
    config.display_safe();
    
    // 🗄️ SETUP SUPABASE API CLIENT (ZERO TRUST ARCHITECTURE)
    // Using Supabase HTTP APIs instead of direct database connections
    // This follows Zero Trust principles: never trust, always verify
    let supabase_client = supabase_api::SupabaseClient::new(&config)?;
    
    // 🚫 DIRECT DATABASE CONNECTION (COMMENTED OUT)
    // We no longer use direct database connections for security reasons
    // All database operations now go through Supabase's HTTP APIs
    // let db_pool: sqlx::Pool<sqlx::Postgres> = database::create_pool(&config.database_url).await?;
    // database::run_migrations(&db_pool).await?;
    
    // 🔐 SETUP JWT VALIDATOR
    // This will verify Supabase JWT tokens
    let jwt_validator = auth::auth::JwtValidator::new(&config);
    
    // 📊 SETUP WEBSOCKET SESSION MANAGER
    // This will keep track of all connected users
    let session_manager = websocket::SessionManager::new();
    
    log::info!("🚀 Starting OChat backend server on {}:{}", 
               config.server_host, config.server_port);
    
    let config_clone = config.clone();   
    // 🌐 START HTTP SERVER
    // HttpServer::new() creates a new server instance
    // move || captures variables so they can be used inside the closure
    HttpServer::new(move || {
        // 🛡️ SETUP CORS (Cross-Origin Resource Sharing)
        // 
        // 🔰 BEGINNER EXPLANATION: What is CORS?
        // ====================================
        // CORS controls which websites can call your API from a browser.
        // Without proper CORS setup, browsers will block your Flutter app's requests.
        // 
        // 🚨 COMMON CORS ERRORS:
        // - "Access to fetch blocked by CORS policy"
        // - "No 'Access-Control-Allow-Origin' header"
        // 
        // 🔧 WHY WE NEED THIS:
        // Your Flutter app runs on one domain (ngrok), but your Rust API runs on another.
        // Browsers require explicit permission for cross-domain requests.
        
        let cors = Cors::default()
            // 🌍 ALLOW ALL ORIGINS (Development Only!)
            // In production, you should specify exact domains for security
            // For now, allowing all origins to fix the ngrok connection issue
            .allowed_origin_fn(|origin, _req_head| {
                // Log the origin for debugging
                log::info!("🌐 CORS request from origin: {:?}", origin);
                
                // Allow all origins during development
                // 🚨 SECURITY NOTE: In production, replace this with specific domains!
                true
            })
            
            // 📝 ALLOWED HTTP METHODS
            // These are the HTTP verbs your Flutter app can use
            .allowed_methods(vec!["GET", "POST", "PUT", "DELETE", "OPTIONS"])
            
            // 📋 ALLOWED HEADERS
            // These headers are required for authentication and JSON requests
            .allowed_headers(vec![
                "Authorization",        // For JWT tokens
                "Content-Type",         // For JSON requests
                "Accept",              // For response format
                "Origin",              // Required by CORS
                "X-Requested-With",    // Common header
                "ngrok-skip-browser-warning", // For ngrok development
            ])
            
            // 🔓 EXPOSE HEADERS TO FRONTEND
            // These headers will be accessible to your Flutter app
            .expose_headers(vec!["Content-Length", "X-Request-Id"])
            
            // ⏱️ CACHE PREFLIGHT REQUESTS
            // Browsers send OPTIONS requests before actual requests
            // This caches the permission for 1 hour to improve performance
            .max_age(3600)
            
            // 🍪 ALLOW CREDENTIALS (if needed for cookies/auth)
            .supports_credentials();
        
        // 🏗️ BUILD APPLICATION
        App::new()
            // Add CORS middleware
            .wrap(cors)
            // Add logging middleware (logs all requests)
            .wrap(Logger::default())
            // 📊 SHARE APPLICATION STATE
            // These are shared across all request handlers
            .app_data(web::Data::new(supabase_client.clone()))   // Supabase API client (ZERO TRUST)
            .app_data(web::Data::new(session_manager.clone()))   // WebSocket sessions
            .app_data(web::Data::new(config.clone()))            // Configuration
            .app_data(web::Data::new(jwt_validator.clone()))     // JWT validator
            // 🛤️ SETUP ROUTES
            .service(
                web::scope("/api/v1")
                    // WebSocket endpoint: ws://localhost:8080/api/v1/ws
                    .route("/ws", web::get().to(websocket::websocket_handler))
                    // Health check endpoint: GET /api/v1/health
                    .route("/health", web::get().to(health_check))
                    // Test endpoints (no authentication required for testing)
                    .route("/test", web::get().to(test_endpoint))
                    .route("/test/send", web::post().to(test_send_message))
                    .route("/test/conversations/{userId}", web::get().to(test_get_conversations))
                    .route("/test/messages/{conversationId}", web::get().to(test_get_messages))
                    
                    // 🧪 TEMPORARY: Non-authenticated users endpoint for testing
                    // 🔰 BEGINNER EXPLANATION: Why do we need this?
                    // =====================================================
                    // Authentication can be complex to set up initially.
                    // This endpoint lets us test the basic functionality first,
                    // then add authentication once everything else works.
                    //
                    // 🚨 IMPORTANT: Remove this in production!
                    .route("/test/users", web::get().to(test_get_users))
                    
                    // Message-related endpoints (NO AUTH FOR NOW)
                    .configure(messages::configure_routes)
                    
                    // 🚨 ALL ENDPOINTS WITHOUT AUTHENTICATION (TEMPORARY!)
                    // Removing all JWT middleware so everything works immediately
                    // User-related endpoints (NO AUTH REQUIRED)
                    .configure(users::configure_routes)
                    
                    // Conversation endpoints (NO AUTH REQUIRED)
                    .service(
                        web::scope("/conversations")
                            .route("/create", web::post().to(messages::create_conversation))
                            .route("/{userId}", web::get().to(messages::get_conversations_by_user))
                    )
            )
    })
    .bind("0.0.0.0:8080")?
    .run()
    .await?;
    
    Ok(())
}

// 🏥 HEALTH CHECK ENDPOINT
// This is a simple endpoint to check if the server is running
// RUST CONCEPT: Result<T, E> is Rust's way of handling errors
// Instead of exceptions, we return Ok(value) or Err(error)
async fn health_check() -> Result<actix_web::HttpResponse, actix_web::Error> {
    Ok(actix_web::HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "ochat-backend",
        "timestamp": chrono::Utc::now()
    })))
}

// 🧪 TEST ENDPOINTS (No authentication required)
// These endpoints are for testing the Flutter app connection

async fn test_endpoint() -> Result<actix_web::HttpResponse, actix_web::Error> {
    Ok(actix_web::HttpResponse::Ok().json(serde_json::json!({
        "message": "Test endpoint working!",
        "timestamp": chrono::Utc::now()
    })))
}

async fn test_send_message(request: actix_web::web::Json<serde_json::Value>) -> Result<actix_web::HttpResponse, actix_web::Error> {
    Ok(actix_web::HttpResponse::Ok().json(serde_json::json!({
        "message": {
            "id": uuid::Uuid::new_v4(),
            "conversation_id": request["conversation_id"],
            "sender_id": request["sender_id"],
            "text": request["text"],
            "timestamp": chrono::Utc::now(),
            "status": "sent"
        },
        "status": "success"
    })))
}

async fn test_get_conversations(path: actix_web::web::Path<String>) -> Result<actix_web::HttpResponse, actix_web::Error> {
    let user_id = path.into_inner();
    Ok(actix_web::HttpResponse::Ok().json(serde_json::json!({
        "conversations": [
            {
                "id": uuid::Uuid::new_v4(),
                "name": "Test Conversation",
                "participants": [user_id],
                "last_message": {
                    "text": "Hello!",
                    "timestamp": chrono::Utc::now()
                },
                "unread_count": 0
            }
        ]
    })))
}

async fn test_get_messages(path: actix_web::web::Path<String>) -> Result<actix_web::HttpResponse, actix_web::Error> {
    let conversation_id = path.into_inner();
    Ok(actix_web::HttpResponse::Ok().json(serde_json::json!({
        "messages": [
            {
                "id": uuid::Uuid::new_v4(),
                "conversation_id": conversation_id,
                "sender_id": "user1",
                "text": "Hello! This is a test message.",
                "timestamp": chrono::Utc::now(),
                "status": "read"
            }
        ]
    })))
}

/// 🧪 TEMPORARY TEST ENDPOINT: Get Users (No Authentication)
/// 
/// 🔰 BEGINNER EXPLANATION: Why do we need this?
/// =============================================
/// This is a simplified version of the users endpoint that:
/// 1. Doesn't require JWT authentication (easier to test)
/// 2. Returns dummy data (no database required)
/// 3. Helps us verify the Flutter <-> Rust connection works
/// 
/// 🚨 IMPORTANT: This is only for testing! Remove in production.
/// 
/// TESTING URLS:
/// - GET https://your-ngrok-url.ngrok-free.app/api/v1/test/users
async fn test_get_users() -> Result<actix_web::HttpResponse, actix_web::Error> {
    Ok(actix_web::HttpResponse::Ok().json(serde_json::json!({
        "users": [
            {
                "id": "test_user_1",
                "email": "user1@test.com",
                "display_name": "Test User 1",
                "avatar_url": null,
                "is_online": true,
                "created_at": chrono::Utc::now(),
                "updated_at": chrono::Utc::now()
            },
            {
                "id": "test_user_2", 
                "email": "user2@test.com",
                "display_name": "Test User 2",
                "avatar_url": null,
                "is_online": false,
                "created_at": chrono::Utc::now(),
                "updated_at": chrono::Utc::now()
            }
        ],
        "status": "success",
        "message": "Test users retrieved successfully (no auth required)"
    })))
}
