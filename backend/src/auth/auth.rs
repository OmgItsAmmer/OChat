/*
🔐 AUTHENTICATION MODULE
========================

This module handles JWT token verification with Supabase.

RUST CONCEPTS EXPLAINED:
- `async/await`: Rust's way of handling asynchronous operations
- `Option<T>`: Either Some(value) or None (like nullable types)
- `Result<T, E>`: Either Ok(value) or Err(error)
- `reqwest`: HTTP client library for making requests

AUTHENTICATION FLOW:
1. Client connects with JWT token in Authorization header
2. We verify the token signature using Supabase's public keys
3. We extract user information from the token claims
4. We allow or deny the connection based on verification result
*/

use jsonwebtoken::{decode, decode_header, Algorithm, DecodingKey, Validation};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;
use actix_web::{dev::ServiceRequest, web, Error, HttpMessage};
use actix_web_httpauth::extractors::bearer::BearerAuth;
use crate::errors::{AppError, AppResult};
use crate::config::Config;
use chrono::{DateTime, Utc};
use std::sync::{Arc, Mutex};



// 🎫 JWT CLAIMS STRUCTURE
// This represents the data inside a Supabase JWT token
// RUST CONCEPT: We use serde to automatically parse JSON into this struct
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: String,                    // Subject (user ID)
    pub email: String,                  // User's email
    pub aud: String,                    // Audience
    pub iss: String,                    // Issuer (Supabase URL)
    pub iat: i64,                       // Issued at (timestamp)
    pub exp: i64,                       // Expires at (timestamp)
    pub role: Option<String>,           // User role (optional)
    pub user_metadata: Option<serde_json::Value>, // Additional user data
    
    // 🛡️ ZERO TRUST ADDITIONS
    pub session_id: Option<String>,     // Session tracking
    pub device_id: Option<String>,      // Device fingerprinting
    pub ip_address: Option<String>,     // IP tracking
}

// 📊 AUDIT LOG ENTRY
#[derive(Debug, Serialize)]
pub struct AuditLog {
    pub timestamp: DateTime<Utc>,
    pub user_id: Option<Uuid>,
    pub action: String,
    pub resource: String,
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
    pub success: bool,
    pub error_message: Option<String>,
    pub session_id: Option<String>,
}

// 🚦 RATE LIMITER
#[derive(Debug)]
struct RateLimitEntry {
    count: u32,
    window_start: DateTime<Utc>,
}

#[derive(Debug)]
pub struct RateLimiter {
    requests: Arc<Mutex<HashMap<String, RateLimitEntry>>>,
    max_requests: u32,
    window_duration_seconds: i64,
}

impl RateLimiter {
    pub fn new(max_requests: u32, window_duration_seconds: i64) -> Self {
        Self {
            requests: Arc::new(Mutex::new(HashMap::new())),
            max_requests,
            window_duration_seconds,
        }
    }
    
    // 🚦 Check if request is allowed under rate limit
    pub fn is_allowed(&self, identifier: &str) -> bool {
        let mut requests = self.requests.lock().unwrap();
        let now = Utc::now();
        
        match requests.get_mut(identifier) {
            Some(entry) => {
                // Check if window has expired
                if (now - entry.window_start).num_seconds() > self.window_duration_seconds {
                    entry.count = 1;
                    entry.window_start = now;
                    true
                } else if entry.count < self.max_requests {
                    entry.count += 1;
                    true
                } else {
                    false // Rate limit exceeded
                }
            }
            None => {
                requests.insert(identifier.to_string(), RateLimitEntry {
                    count: 1,
                    window_start: now,
                });
                true
            }
        }
    }
}

// 🔑 JWKS (JSON Web Key Set) STRUCTURES
// These represent the public keys from Supabase used to verify JWTs
#[derive(Debug, Deserialize)]
struct JwksResponse {
    keys: Vec<Jwk>,
}

#[derive(Debug, Deserialize)]
struct Jwk {
    kty: String,        // Key type
    use_: Option<String>, // Key use
    #[serde(rename = "use")]
    key_use: Option<String>,
    kid: String,        // Key ID
    x5c: Option<Vec<String>>, // X.509 certificate chain
    n: Option<String>,  // RSA modulus
    e: Option<String>,  // RSA exponent
}

// 🔐 JWT VALIDATOR
// This struct handles all JWT verification logic
#[derive(Debug, Clone)]
pub struct JwtValidator {
    client: Client,
    supabase_url: String,
    validation: Validation,
    rate_limiter: Arc<RateLimiter>,
    audit_logger: Arc<Mutex<Vec<AuditLog>>>, // In production, use proper logging
}

impl JwtValidator {
    // 🏗️ Constructor
    pub fn new(config: &Config) -> Self {
        let mut validation = Validation::new(Algorithm::RS256);
        validation.set_audience(&["authenticated"]); // Supabase uses "authenticated" audience
        validation.set_issuer(&[&config.supabase_url]);
        
        // 🛡️ ZERO TRUST: Strict validation
        validation.validate_exp = true;
        validation.validate_nbf = true;
        validation.leeway = 0; // No clock skew tolerance for maximum security
        
        Self {
            client: Client::new(),
            supabase_url: config.supabase_url.clone(),
            validation,
            rate_limiter: Arc::new(RateLimiter::new(100, 3600)), // 100 requests per hour
            audit_logger: Arc::new(Mutex::new(Vec::new())),
        }
    }
    
    // 🔍 VERIFY JWT TOKEN
    // This is the main function that verifies a JWT token
    pub async fn verify_token(&self, token: &str, ip_address: Option<String>, user_agent: Option<String>) -> AppResult<Claims> {
        let start_time = Utc::now();
        let mut audit = AuditLog {
            timestamp: start_time,
            user_id: None,
            action: "jwt_verification".to_string(),
            resource: "auth".to_string(),
            ip_address: ip_address.clone(),
            user_agent,
            success: false,
            error_message: None,
            session_id: None,
        };
        
        // 🚦 ZERO TRUST: Rate limiting by IP
        if let Some(ip) = &ip_address {
            if !self.rate_limiter.is_allowed(ip) {
                audit.error_message = Some("Rate limit exceeded".to_string());
                self.log_audit(audit).await;
                return Err(AppError::auth_failed("Rate limit exceeded".to_string()));
            }
        }
        
        // 🔍 Basic token format validation
        if token.is_empty() || token.len() > 2048 {
            audit.error_message = Some("Invalid token format".to_string());
            self.log_audit(audit).await;
            return Err(AppError::InvalidToken { 
                reason: "Invalid token format".to_string() 
            });
        }
        
        let result = self.verify_token_internal(token).await;
        
        match &result {
            Ok(claims) => {
                audit.success = true;
                audit.user_id = Uuid::parse_str(&claims.sub).ok();
                audit.session_id = claims.session_id.clone();
            }
            Err(e) => {
                audit.error_message = Some(e.to_string());
            }
        }
        
        self.log_audit(audit).await;
        result
    }
    
    // 🔍 VERIFY JWT TOKEN
    // This is the main function that verifies a JWT token
    async fn verify_token_internal(&self, token: &str) -> AppResult<Claims> {
        // Step 1: Decode the JWT header to get the key ID (kid)
        let header = decode_header(token)
            .map_err(|e| AppError::InvalidToken { 
                reason: format!("Invalid token header: {}", e) 
            })?;
        
        let kid = header.kid.ok_or_else(|| AppError::InvalidToken {
            reason: "Token missing key ID".to_string(),
        })?;
        
        // Step 2: Fetch the public key from Supabase JWKS endpoint
        let jwks_url = format!("{}/auth/v1/keys", self.supabase_url);
        let jwks_response = self.client
            .get(&jwks_url)
            .timeout(std::time::Duration::from_secs(10)) // 🛡️ Timeout protection
            .send()
            .await
            .map_err(|e| AppError::Http(e))?
            .json::<JwksResponse>()
            .await
            .map_err(|e| AppError::Http(e))?;
        
        // Step 3: Find the correct key by key ID
        let jwk = jwks_response
            .keys
            .iter()
            .find(|key| key.kid == kid)
            .ok_or_else(|| AppError::InvalidToken {
                reason: "Key not found in JWKS".to_string(),
            })?;
        
        // Step 4: Convert JWK to DecodingKey
        let decoding_key = self.jwk_to_decoding_key(jwk)?;
        
        // Step 5: Verify and decode the token
        let token_data = decode::<Claims>(token, &decoding_key, &self.validation)
            .map_err(|e| AppError::from(e))?;
        
        // Step 6: Additional validation
        let claims = token_data.claims;
        self.validate_claims(&claims)?;
        
        log::debug!("✅ JWT token verified for user: {}", claims.sub);
        Ok(claims)
    }
    
    // 🔑 Convert JWK to DecodingKey
    // This converts the JSON Web Key format to what jsonwebtoken crate expects
    fn jwk_to_decoding_key(&self, jwk: &Jwk) -> AppResult<DecodingKey> {
        if let Some(x5c) = &jwk.x5c {
            if let Some(cert) = x5c.first() {
                let cert_der = base64::decode(cert)
                    .map_err(|e| AppError::InvalidToken {
                        reason: format!("Invalid certificate format: {}", e),
                    })?;
                
                return Ok(DecodingKey::from_rsa_der(&cert_der));
            }
        }
    
        Err(AppError::InvalidToken {
            reason: "Unsupported key format".to_string(),
        })
    }
    
    
    // ✅ Validate JWT claims
    // Additional validation beyond what jsonwebtoken crate does
    fn validate_claims(&self, claims: &Claims) -> AppResult<()> {
        // Check if token is expired (jsonwebtoken crate already does this, but let's be explicit)
        let now = chrono::Utc::now().timestamp();
        if claims.exp < now {
            return Err(AppError::TokenExpired);
        }
        
        // Validate issuer
        if !claims.iss.starts_with(&self.supabase_url) {
            return Err(AppError::InvalidToken {
                reason: "Invalid issuer".to_string(),
            });
        }
        
        // Validate subject (user ID) format
        if Uuid::parse_str(&claims.sub).is_err() {
            return Err(AppError::InvalidToken {
                reason: "Invalid user ID format".to_string(),
            });
        }
        
        Ok(())
    }
    
    // 📊 AUDIT LOGGING
    async fn log_audit(&self, audit: AuditLog) {
        if let Ok(mut logger) = self.audit_logger.lock() {
            logger.push(audit);
            
            // In production, send to external audit system
            // For now, just log important events
            // if !audit.success {
            //     log::warn!("🚨 SECURITY EVENT: {} - {} - {:?}", 
            //               audit.action, audit.error_message.unwrap_or_default(), audit.ip_address);
            // }
        }
    }
    
    // // 📊 Get audit logs (for admin interface)
    // pub fn get_audit_logs(&self) -> Vec<AuditLog> {
    //     self.audit_logger.lock().unwrap().clone()
    // }
}

// 🛡️ AUTHENTICATION MIDDLEWARE
// This function can be used as middleware to protect routes
pub async fn jwt_middleware(
    mut req: ServiceRequest,
    credentials: BearerAuth,
) -> Result<ServiceRequest, (Error, ServiceRequest)> {
    let validator_data = req.app_data::<web::Data<JwtValidator>>();
    if validator_data.is_none() {
        log::error!("JWT validator not found in app data");
        return Err((AppError::internal("JWT validator not configured").into(), req));
    }
    let jwt_validator = validator_data.unwrap();

    // 🛡️ ZERO TRUST: Extract request context
    let ip_address = req.connection_info().peer_addr().map(|s| s.to_string());
    let user_agent = req.headers()
        .get("user-agent")
        .and_then(|h| h.to_str().ok())
        .map(|s| s.to_string());
    
    match jwt_validator.verify_token(credentials.token(), ip_address, user_agent).await {
        Ok(claims) => {
            req.extensions_mut().insert(claims);
            Ok(req)
        }
        Err(e) => {
            log::warn!("Authentication failed: {}", e);
            Err((e.into(), req))
        }
    }
}


// 🎯 EXTRACT USER FROM REQUEST
// Helper function to get authenticated user information from request
pub fn extract_user_from_request(req: &ServiceRequest) -> AppResult<Uuid> {
    let extensions = req.extensions(); // now the Extensions outlive the borrow
    
    let claims = extensions
        .get::<Claims>()
        .ok_or_else(|| AppError::auth_failed("No authentication information found".to_string()))?;
    
    let user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::auth_failed("Invalid user ID in token".to_string()))?;
    
    Ok(user_id)
}


// 🔍 EXTRACT TOKEN FROM WEBSOCKET REQUEST
// Helper function to extract JWT token from WebSocket connection request
// WebSocket connections can pass the token in query parameters or headers
pub fn extract_token_from_ws_request(req: &actix_web::HttpRequest) -> AppResult<String> {
    // First, try to get token from Authorization header
    if let Some(auth_header) = req.headers().get("Authorization") {
        if let Ok(auth_str) = auth_header.to_str() {
            if auth_str.starts_with("Bearer ") {
                return Ok(auth_str[7..].to_string());
            }
        }
    }
    
    // If not in header, try query parameter
    if let Some(token) = req
        .query_string()
        .split('&')
        .find_map(|part| {
            let mut split = part.split('=');
            if split.next()? == "token" {
                split.next()
            } else {
                None
            }
        })
    {
        return Ok(urlencoding::decode(token)
            .map_err(|_| AppError::InvalidToken {
                reason: "Invalid token encoding".to_string(),
            })?
            .into_owned());
    }
    
    Err(AppError::auth_failed("No authentication token provided"))
}

// 📊 USER INFO RESPONSE
// This struct is returned when getting user information
#[derive(Serialize)]
pub struct UserInfo {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub avatar_url: Option<String>,
}

impl From<Claims> for UserInfo {
    fn from(claims: Claims) -> Self {
        let id = Uuid::parse_str(&claims.sub)
            .expect("Valid UUID already verified");
        
        Self {
            id,
            email: claims.email,
            username: None, // Will be loaded from database if needed
            avatar_url: None, // Will be loaded from database if needed
        }
    }
}

// 🛡️ ZERO TRUST PERMISSION CHECKING
#[derive(Debug, Clone)]
pub enum Permission {
    ReadMessages,
    SendMessages,
    ManageUsers,
    ViewAnalytics,
}

pub fn check_permission(claims: &Claims, permission: Permission) -> bool {
    // 🛡️ ZERO TRUST: Implement fine-grained permissions
    match permission {
        Permission::ReadMessages | Permission::SendMessages => {
            // All authenticated users can read/send messages
            true
        }
        Permission::ManageUsers | Permission::ViewAnalytics => {
            // Only admin role can manage users or view analytics
            claims.role.as_ref().map_or(false, |role| role == "admin")
        }
    }
} 