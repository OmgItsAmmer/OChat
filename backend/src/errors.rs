/*
❌ ERROR HANDLING MODULE
========================

This module defines custom error types for our application.

RUST CONCEPTS EXPLAINED:
- `thiserror`: A crate that makes it easy to define custom error types
- `enum`: In Rust, enums can hold different types of data (like union types)
- Error handling in Rust is explicit - no hidden exceptions!

WHY CUSTOM ERRORS?
- Better error messages for debugging
- Type safety - compiler ensures we handle all error cases
- Clear API - callers know exactly what can go wrong
*/

use thiserror::Error;

// 🎯 MAIN APPLICATION ERROR TYPE
// This enum represents all possible errors in our application
// RUST BEST PRACTICE: Use descriptive error variants with context
#[derive(Error, Debug)]
pub enum AppError {
    // 🗄️ Database errors
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    // 🔐 Authentication errors
    #[error("Authentication failed: {message}")]
    Authentication { message: String },
    
    #[error("Invalid JWT token: {reason}")]
    InvalidToken { reason: String },
    
    #[error("Token expired")]
    TokenExpired,
    
    // 📡 WebSocket errors
    #[error("WebSocket error: {message}")]
    WebSocket { message: String },
    
    #[error("User not connected")]
    UserNotConnected,
    
    // 📨 Message errors
    #[error("Invalid message format: {reason}")]
    InvalidMessage { reason: String },
    
    #[error("Message delivery failed: recipient '{recipient}' not found")]
    MessageDeliveryFailed { recipient: String },
    
    // ⚙️ Configuration errors
    #[error("Configuration error: {message}")]
    Config { message: String },
    
    // 🌐 HTTP/Network errors
    #[error("HTTP request failed: {0}")]
    Http(#[from] reqwest::Error),
    
    // 🔧 General errors
    #[error("Internal server error: {message}")]
    Internal { message: String },
    
    #[error("Bad request: {message}")]
    BadRequest { message: String },
    
    #[error("Not found: {resource}")]
    NotFound { resource: String },
    
    // 🔐 Encryption errors
    #[error("Encryption error: {message}")]
    Encryption { message: String },
}

// 🔄 CONVERSION IMPLEMENTATIONS
// These help convert common error types to our custom error type
// RUST CONCEPT: The `From` trait allows automatic conversions with `?` operator

impl From<anyhow::Error> for AppError {
    fn from(error: anyhow::Error) -> Self {
        AppError::Internal {
            message: error.to_string(),
        }
    }
}

impl From<jsonwebtoken::errors::Error> for AppError {
    fn from(error: jsonwebtoken::errors::Error) -> Self {
        match error.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => AppError::TokenExpired,
            _ => AppError::InvalidToken {
                reason: error.to_string(),
            },
        }
    }
}

impl From<crate::encryption::EncryptionError> for AppError {
    fn from(error: crate::encryption::EncryptionError) -> Self {
        AppError::Encryption {
            message: error.to_string(),
        }
    }
}

// 🌐 ACTIX-WEB INTEGRATION
// This allows our errors to be returned from web handlers
// Actix-web will automatically convert them to HTTP responses
impl actix_web::ResponseError for AppError {
    fn error_response(&self) -> actix_web::HttpResponse {
        use actix_web::HttpResponse;
        
        match self {
            // 🔐 Authentication errors -> 401 Unauthorized
            AppError::Authentication { .. } | 
            AppError::InvalidToken { .. } | 
            AppError::TokenExpired => {
                HttpResponse::Unauthorized().json(ErrorResponse {
                    error: "unauthorized".to_string(),
                    message: self.to_string(),
                })
            }
            
            // 🔍 Not found errors -> 404 Not Found
            AppError::NotFound { .. } => {
                HttpResponse::NotFound().json(ErrorResponse {
                    error: "not_found".to_string(),
                    message: self.to_string(),
                })
            }
            
            // 📝 Bad request errors -> 400 Bad Request
            AppError::BadRequest { .. } | 
            AppError::InvalidMessage { .. } => {
                HttpResponse::BadRequest().json(ErrorResponse {
                    error: "bad_request".to_string(),
                    message: self.to_string(),
                })
            }
            
            // 🚨 All other errors -> 500 Internal Server Error
            _ => {
                log::error!("Internal server error: {}", self);
                HttpResponse::InternalServerError().json(ErrorResponse {
                    error: "internal_server_error".to_string(),
                    message: "An internal error occurred".to_string(),
                })
            }
        }
    }
    
    fn status_code(&self) -> actix_web::http::StatusCode {
        use actix_web::http::StatusCode;
        
        match self {
            AppError::Authentication { .. } | 
            AppError::InvalidToken { .. } | 
            AppError::TokenExpired => StatusCode::UNAUTHORIZED,
            
            AppError::NotFound { .. } => StatusCode::NOT_FOUND,
            
            AppError::BadRequest { .. } | 
            AppError::InvalidMessage { .. } => StatusCode::BAD_REQUEST,
            
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }
}

// 📄 ERROR RESPONSE FORMAT
// This struct defines how errors are sent back to clients as JSON
// RUST BEST PRACTICE: Consistent error response format
#[derive(serde::Serialize)]
struct ErrorResponse {
    error: String,
    message: String,
}

// 🛠️ HELPER FUNCTIONS
// These make it easier to create specific error types

impl AppError {
    // 🔐 Authentication helper
    pub fn auth_failed(message: impl Into<String>) -> Self {
        AppError::Authentication {
            message: message.into(),
        }
    }
    
    // 📡 WebSocket helper
    pub fn websocket_error(message: impl Into<String>) -> Self {
        AppError::WebSocket {
            message: message.into(),
        }
    }
    
    // 📨 Message helper
    pub fn invalid_message(reason: impl Into<String>) -> Self {
        AppError::InvalidMessage {
            reason: reason.into(),
        }
    }
    
    // 🔧 Internal error helper
    pub fn internal(message: impl Into<String>) -> Self {
        AppError::Internal {
            message: message.into(),
        }
    }
    
    // 📝 Bad request helper
    pub fn bad_request(message: impl Into<String>) -> Self {
        AppError::BadRequest {
            message: message.into(),
        }
    }
}

// 📊 RESULT TYPE ALIAS
// This makes our function signatures cleaner
// Instead of writing Result<T, AppError> everywhere, we just write AppResult<T>
pub type AppResult<T> = Result<T, AppError>; 