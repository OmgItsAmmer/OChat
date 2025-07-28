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
use actix_cors::Cors;
use std::env;

// 📦 INTERNAL MODULES  
// These declare our internal modules - each corresponds to a .rs file
mod config;     // Configuration management
mod database;   // Database connection and models
mod auth;       // Authentication middleware
mod websocket;  // WebSocket handling
mod messages;   // Message operations
mod errors;     // Custom error types

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
    
    // 🗄️ SETUP DATABASE CONNECTION
    // Create a connection pool to PostgreSQL
    let db_pool: sqlx::Pool<sqlx::Postgres> = database::create_pool(&config.database_url).await?;
    
    // 🏃‍♂️ RUN DATABASE MIGRATIONS
    // This creates our tables if they don't exist
    database::run_migrations(&db_pool).await?;
    
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
        // This allows our Flutter app to connect to the backend
        let cors = Cors::default()
            .allowed_origin(&config.allowed_origins)
            .allowed_methods(vec!["GET", "POST", "PUT", "DELETE"])
            .allowed_headers(vec!["Authorization", "Content-Type"])
            .max_age(3600);
        
        // 🏗️ BUILD APPLICATION
        App::new()
            // Add CORS middleware
            .wrap(cors)
            // Add logging middleware (logs all requests)
            .wrap(Logger::default())
            // 📊 SHARE APPLICATION STATE
            // These are shared across all request handlers
            .app_data(web::Data::new(db_pool.clone()))           // Database pool
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
                    // Message-related endpoints (protected by JWT)
                    .configure(messages::configure_routes)
            ).service(
                web::scope("/api/v1")
                    .route("/ws", web::get().to(websocket::websocket_handler))
                    .route("/health", web::get().to(health_check))
                    .configure(messages::configure_routes)
                    .service(auth::auth_routes::auth_routes()) // ✅ ADD THIS LINE
            )
    })
    .bind(format!("{}:{}", config_clone.server_host, config_clone.server_port))?
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
