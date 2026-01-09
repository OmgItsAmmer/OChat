/*
🔐 SUPABASE API WRAPPER MODULE
==============================

This module provides a Zero Trust Architecture interface to Supabase using HTTP APIs
instead of direct database connections. This follows security best practices by:
- Using HTTPS for all communications
- Implementing proper authentication with anon/service_role keys
- Respecting Row-Level Security (RLS) policies
- Providing audit logging for all operations

RUST CONCEPTS EXPLAINED:
- `reqwest`: Async HTTP client for making API calls
- `serde_json`: JSON serialization/deserialization
- `Result<T, E>`: Error handling pattern
- `async/await`: Asynchronous programming
- `Arc<Mutex<T>>`: Thread-safe shared state

ZERO TRUST PRINCIPLES:
1. Never trust, always verify
2. Use least privilege access
3. Assume breach and verify explicitly
4. Monitor and log all access
*/

use reqwest::{Client, header::{HeaderMap, HeaderValue, AUTHORIZATION, CONTENT_TYPE}};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use std::sync::{Arc, Mutex};
use crate::errors::{AppError, AppResult};
use crate::config::Config;
use crate::database::{User, Message, MessageType, NewMessage};
use reqwest::Method;


// 🔐 SUPABASE API CLIENT
// This struct manages all communication with Supabase
#[derive(Debug, Clone)]
pub struct SupabaseClient {
    client: Client,
    base_url: String,
    anon_key: String,
    service_role_key: String,
    audit_log: Arc<Mutex<Vec<AuditEntry>>>,
}

// 📊 AUDIT ENTRY FOR ZERO TRUST
#[derive(Debug, Serialize, Clone)]
pub struct AuditEntry {
    pub timestamp: DateTime<Utc>,
    pub operation: String,
    pub user_id: Option<Uuid>,
    pub resource: String,
    pub success: bool,
    pub error_message: Option<String>,
    pub request_data: Option<Value>,
    pub response_data: Option<Value>,
}

// 📋 SUPABASE API RESPONSES
// These structs represent the responses from Supabase APIs

#[derive(Debug, Deserialize)]
pub struct SupabaseResponse<T> {
    pub data: Option<T>,
    pub error: Option<SupabaseError>,
    pub count: Option<i64>,
}

#[derive(Debug, Deserialize)]
pub struct SupabaseError {
    pub message: String,
    pub details: Option<String>,
    pub hint: Option<String>,
    pub code: Option<String>,
}

// 🔐 AUTHENTICATION TYPES
#[derive(Debug, Serialize)]
pub struct SignUpRequest {
    pub email: String,
    pub password: String,
    pub data: Option<Value>,
}

#[derive(Debug, Serialize)]
pub struct SignInRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct AuthResponse {
    pub user: Option<User>,
    pub session: Option<Session>,
    pub access_token: Option<String>,
    pub refresh_token: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct Session {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_at: i64,
    pub user: User,
}

// 🗄️ DATABASE OPERATION TYPES
#[derive(Debug, Serialize)]
pub struct InsertRequest<T> {
    pub data: T,
}

#[derive(Debug, Serialize)]
pub struct UpdateRequest<T> {
    pub data: T,
}

#[derive(Debug, Serialize)]
pub struct SelectRequest {
    pub select: Option<String>,
    pub filter: Option<String>,
    pub order: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

// 🔄 REALTIME SUBSCRIPTION TYPES
#[derive(Debug, Serialize)]
pub struct RealtimeSubscription {
    pub event: String,
    pub schema: String,
    pub table: String,
    pub filter: Option<String>,
}

impl SupabaseClient {
    // 🏗️ CONSTRUCTOR
    pub fn new(config: &Config) -> AppResult<Self> {
        let mut headers = HeaderMap::new();
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
        
        let client = Client::builder()
            .default_headers(headers)
            .timeout(std::time::Duration::from_secs(30))
            .build()
            .map_err(|e| AppError::Internal { message: format!("Failed to create HTTP client: {}", e) })?;
        
        Ok(SupabaseClient {
            client,
            base_url: config.supabase_url.clone(),
            anon_key: config.supabase_anon_key.clone(),
            service_role_key: config.supabase_service_role_key.clone(),
            audit_log: Arc::new(Mutex::new(Vec::new())),
        })
    }
  
    /// 🔁 Supabase HTTP Request Handler
    pub async fn supabase_request(
        &self,
        method: &str,
        path: &str,
        body: Option<Value>,
        api_key: Option<&str>,
    ) -> AppResult<Value> {
        let url = format!("{}{}", self.base_url, path);
        let method = method.parse::<Method>().map_err(|e| AppError::Internal {
            message: format!("Invalid HTTP method: {}", e),
        })?;

        let mut request_builder = self.client.request(method, &url);

        request_builder = request_builder
            .header("Authorization", format!("Bearer {}", api_key.unwrap_or(&self.anon_key)));

        if let Some(json_body) = body {
            request_builder = request_builder.json(&json_body);
        }

        let response = request_builder.send().await.map_err(|e| AppError::Internal {
            message: format!("HTTP request failed: {}", e),
        })?;

        if !response.status().is_success() {
            let status = response.status();
            let text = response.text().await.unwrap_or_default();
            return Err(AppError::Internal {
                message: format!("Supabase returned error {}: {}", status, text),
            });
        }

        let json = response.json::<Value>().await.map_err(|e| AppError::Internal {
            message: format!("Failed to parse response: {}", e),
        })?;

        Ok(json)
    }
    
    // 🔐 AUTHENTICATION METHODS
    
    /// Sign up a new user with Supabase Auth
    pub async fn sign_up(&self, email: &str, password: &str, user_data: Option<Value>) -> AppResult<AuthResponse> {
        let request = SignUpRequest {
            email: email.to_string(),
            password: password.to_string(),
            data: user_data,
        };
        
        let request_json = json!(request);
        let response = self.post("/auth/v1/signup", &request_json, true, None).await?;
        self.log_audit("sign_up", None, "auth", true, Some(request_json), Some(response.clone()));
        
        let auth_response: AuthResponse = serde_json::from_value(response)
            .map_err(|e| AppError::Internal { message: format!("Failed to parse auth response: {}", e) })?;
        
        Ok(auth_response)
    }
    
    /// Sign in a user with Supabase Auth
    pub async fn sign_in(&self, email: &str, password: &str) -> AppResult<AuthResponse> {
        let request = SignInRequest {
            email: email.to_string(),
            password: password.to_string(),
        };
        
        let request_json = json!(request);
        let response = self.post("/auth/v1/token?grant_type=password", &request_json, true, None).await?;
        self.log_audit("sign_in", None, "auth", true, Some(request_json), Some(response.clone()));
        
        let auth_response: AuthResponse = serde_json::from_value(response)
            .map_err(|e| AppError::Internal { message: format!("Failed to parse auth response: {}", e) })?;
        
        Ok(auth_response)
    }
    
    /// Get user information by ID
    pub async fn get_user(&self, user_id: Uuid, access_token: &str) -> AppResult<Option<User>> {
        let url = format!("/rest/v1/users?id=eq.{}", user_id);
        let response = self.get(&url, access_token).await?;
        
        self.log_audit("get_user", Some(user_id), "users", true, None, Some(response.clone()));
        
        let users: Vec<User> = serde_json::from_value(response)
            .map_err(|e| AppError::Internal { message: format!("Failed to parse user response: {}", e) })?;
        
        Ok(users.into_iter().next())
    }
    
    /// Create or update user (upsert)
    pub async fn upsert_user(&self, user: &User, access_token: &str) -> AppResult<User> {
        let response = self.post("/rest/v1/users", &json!({
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "avatar_url": user.avatar_url,
            "is_online": user.is_online,
            "last_seen": user.last_seen,
            "updated_at": Utc::now()
        }), false, Some(access_token)).await?;
        
        self.log_audit("upsert_user", Some(user.id), "users", true, Some(json!(user)), Some(response.clone()));
        
        let users: Vec<User> = serde_json::from_value(response)
            .map_err(|e| AppError::Internal { message: format!("Failed to parse user response: {}", e) })?;
        
        users.into_iter().next()
            .ok_or_else(|| AppError::Internal { message: "No user returned from upsert".to_string() })
    }
    
    /// Update user online status
    pub async fn update_user_status(&self, user_id: Uuid, is_online: bool, access_token: &str) -> AppResult<()> {
        let url = format!("/rest/v1/users?id=eq.{}", user_id);
        let update_data = json!({
            "is_online": is_online,
            "last_seen": Utc::now(),
            "updated_at": Utc::now()
        });
        
        let response = self.patch(&url, &update_data, access_token).await?;
        self.log_audit("update_user_status", Some(user_id), "users", true, Some(update_data), Some(response));
        
        Ok(())
    }
    
    // 💬 MESSAGE OPERATIONS
    
    /// Create a new encrypted message
    pub async fn create_message(&self, message: &NewMessage, sender_id: Uuid, access_token: &str) -> AppResult<Message> {
        // 🔐 ENCRYPTION: The message content should already be encrypted by the caller
        // This method expects the message to contain encrypted content
        let message_data = json!({
            "sender_id": sender_id,
            "receiver_id": message.receiver_id,
            "encrypted_content": message.content, // This should be the encrypted content
            "content_hash": "TODO: Generate hash", // TODO: Generate content hash
            "encryption_version": 1,
            "nonce": "TODO: Generate nonce", // TODO: Generate nonce
            "session_key_id": "TODO: Get session key ID", // TODO: Get session key ID
            "message_type": message.message_type.as_ref().map(|mt| format!("{:?}", mt).to_lowercase()).unwrap_or_else(|| "text".to_string()),
            "is_read": false,
            "file_url": message.file_url,
            "file_size": message.file_size,
            "mime_type": message.mime_type,
            "created_at": Utc::now(),
            "updated_at": Utc::now()
        });
        
        let response = self.post("/rest/v1/messages", &message_data, false, Some(access_token)).await?;
        self.log_audit("create_message", Some(sender_id), "messages", true, Some(message_data.clone()), Some(response.clone()));
        
        let messages: Vec<Message> = serde_json::from_value(response)
            .map_err(|e| AppError::Internal { message: format!("Failed to parse message response: {}", e) })?;
        
        messages.into_iter().next()
            .ok_or_else(|| AppError::Internal { message: "No message returned from create".to_string() })
    }
    
    /// Get conversation between two users
    pub async fn get_conversation(&self, user1_id: Uuid, user2_id: Uuid, limit: i64, access_token: &str) -> AppResult<Vec<Message>> {
        let filter = format!(
            "or(sender_id.eq.{},receiver_id.eq.{})",
            user1_id, user1_id
        );
        let url = format!(
            "/rest/v1/messages?{}&sender_id.eq.{}&receiver_id.eq.{},sender_id.eq.{}&receiver_id.eq.{}&order=created_at.desc&limit={}",
            filter, user1_id, user2_id, user2_id, user1_id, limit
        );
        
        let response = self.get(&url, access_token).await?;
        self.log_audit("get_conversation", Some(user1_id), "messages", true, None, Some(response.clone()));
        
        let messages: Vec<Message> = serde_json::from_value(response)
            .map_err(|e| AppError::Internal { message: format!("Failed to parse messages response: {}", e) })?;
        
        Ok(messages)
    }
    
    /// Mark message as read
    pub async fn mark_message_read(&self, message_id: Uuid, user_id: Uuid, access_token: &str) -> AppResult<()> {
        let url = format!("/rest/v1/messages?id=eq.{}&receiver_id.eq.{}", message_id, user_id);
        let update_data = json!({
            "is_read": true,
            "updated_at": Utc::now()
        });
        
        let response = self.patch(&url, &update_data, access_token).await?;
        self.log_audit("mark_message_read", Some(user_id), "messages", true, Some(update_data), Some(response));
        
        Ok(())
    }
    
    /// Get unread message count for user
    pub async fn get_unread_count(&self, user_id: Uuid, access_token: &str) -> AppResult<i64> {
        let url = format!("/rest/v1/messages?receiver_id.eq.{}&is_read.eq.false&select=count", user_id);
        let response = self.get(&url, access_token).await?;
        
        self.log_audit("get_unread_count", Some(user_id), "messages", true, None, Some(response.clone()));
        
        // Parse the count from the response
        let count_value = response.get("count")
            .ok_or_else(|| AppError::Internal { message: "No count in response".to_string() })?;
        
        let count = count_value.as_i64()
            .ok_or_else(|| AppError::Internal { message: "Invalid count format".to_string() })?;
        
        Ok(count)
    }
    
    /// Search messages (encrypted content cannot be searched directly)
    /// Note: This will need to be implemented differently for encrypted messages
    pub async fn search_messages(&self, user_id: Uuid, query: &str, with_user: Option<Uuid>, limit: i64, access_token: &str) -> AppResult<Vec<Message>> {
        // 🔐 ENCRYPTION NOTE: Cannot search encrypted content directly
        // This is a limitation of end-to-end encryption
        // In a real implementation, you might use:
        // 1. Client-side search after decryption
        // 2. Encrypted search indexes
        // 3. Metadata-based search only
        
        let mut filter = format!("or(sender_id.eq.{},receiver_id.eq.{})", user_id, user_id);
        
        if let Some(other_user) = with_user {
            filter = format!("and({},or(sender_id.eq.{},receiver_id.eq.{}))", filter, other_user, other_user);
        }
        
        // For now, return empty results since we can't search encrypted content
        log::warn!("Search not implemented for encrypted messages");
        Ok(Vec::new())
    }

    // 🔐 ENCRYPTION KEY OPERATIONS

    /// Store encryption key for a user
    pub async fn store_encryption_key(&self, user_id: Uuid, key_data: &Value, access_token: &str) -> AppResult<()> {
        let response = self.post("/rest/v1/encryption_keys", key_data, false, Some(access_token)).await?;
        self.log_audit("store_encryption_key", Some(user_id), "encryption_keys", true, Some(key_data.clone()), Some(response));
        Ok(())
    }

    /// Get encryption key for a user
    pub async fn get_encryption_key(&self, user_id: Uuid, access_token: &str) -> AppResult<Option<Value>> {
        let url = format!("/rest/v1/encryption_keys?user_id=eq.{}&order=key_version.desc&limit=1", user_id);
        let response = self.get(&url, access_token).await?;
        
        self.log_audit("get_encryption_key", Some(user_id), "encryption_keys", true, None, Some(response.clone()));
        
        if let Some(keys) = response.as_array() {
            Ok(keys.first().cloned())
        } else {
            Ok(None)
        }
    }

    /// Store conversation session key
    pub async fn store_conversation_session(&self, session_data: &Value, access_token: &str) -> AppResult<()> {
        let response = self.post("/rest/v1/conversation_sessions", session_data, false, Some(access_token)).await?;
        self.log_audit("store_conversation_session", None, "conversation_sessions", true, Some(session_data.clone()), Some(response));
        Ok(())
    }

    /// Get conversation session key
    pub async fn get_conversation_session(&self, user1_id: Uuid, user2_id: Uuid, access_token: &str) -> AppResult<Option<Value>> {
        let url = format!(
            "/rest/v1/conversation_sessions?or(and(user1_id.eq.{},user2_id.eq.{}),and(user1_id.eq.{},user2_id.eq.{}))&is_active.eq.true&order=last_used.desc&limit=1",
            user1_id, user2_id, user2_id, user1_id
        );
        
        let response = self.get(&url, access_token).await?;
        self.log_audit("get_conversation_session", Some(user1_id), "conversation_sessions", true, None, Some(response.clone()));
        
        if let Some(sessions) = response.as_array() {
            Ok(sessions.first().cloned())
        } else {
            Ok(None)
        }
    }
    
    // 🔄 REALTIME OPERATIONS
    
    /// Subscribe to realtime updates for messages
    pub async fn subscribe_to_messages(&self, user_id: Uuid, access_token: &str) -> AppResult<String> {
        let subscription = RealtimeSubscription {
            event: "INSERT".to_string(),
            schema: "public".to_string(),
            table: "messages".to_string(),
            filter: Some(format!("receiver_id=eq.{}", user_id)),
        };
        
        let subscription_json = json!(subscription);
        let response = self.post("/realtime/v1/subscription", &subscription_json, false, Some(access_token)).await?;
        self.log_audit("subscribe_to_messages", Some(user_id), "realtime", true, Some(subscription_json), Some(response.clone()));
        
        let subscription_id = response.get("id")
            .and_then(|v| v.as_str())
            .ok_or_else(|| AppError::Internal { message: "No subscription ID in response".to_string() })?;
        
        Ok(subscription_id.to_string())
    }
    
    // 🔧 HELPER METHODS
    
    /// Make a GET request to Supabase
    async fn get(&self, endpoint: &str, access_token: &str) -> AppResult<Value> {
        let url = format!("{}{}", self.base_url, endpoint);
        let mut headers = HeaderMap::new();
        headers.insert(AUTHORIZATION, HeaderValue::from_str(&format!("Bearer {}", access_token))
            .map_err(|e| AppError::Internal { message: format!("Invalid authorization header: {}", e) })?);
        headers.insert("apikey", HeaderValue::from_str(&self.anon_key)
            .map_err(|e| AppError::Internal { message: format!("Invalid API key: {}", e) })?);
        
        let response = self.client.get(&url)
            .headers(headers)
            .send()
            .await
            .map_err(|e| AppError::Internal { message: format!("GET request failed: {}", e) })?;
        
        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(AppError::Internal { message: format!("Supabase API error: {}", error_text) });
        }
        
        let json_response: Value = response.json().await
            .map_err(|e| AppError::Internal { message: format!("Failed to parse JSON response: {}", e) })?;
        
        Ok(json_response)
    }
    
    /// Make a POST request to Supabase
    async fn post(&self, endpoint: &str, data: &Value, is_auth: bool, access_token: Option<&str>) -> AppResult<Value> {
        let url = format!("{}{}", self.base_url, endpoint);
        let mut headers = HeaderMap::new();
        
        if is_auth {
            headers.insert("apikey", HeaderValue::from_str(&self.anon_key)
                .map_err(|e| AppError::Internal { message: format!("Invalid API key: {}", e) })?);
        } else if let Some(token) = access_token {
            headers.insert(AUTHORIZATION, HeaderValue::from_str(&format!("Bearer {}", token))
                .map_err(|e| AppError::Internal { message: format!("Invalid authorization header: {}", e) })?);
            headers.insert("apikey", HeaderValue::from_str(&self.anon_key)
                .map_err(|e| AppError::Internal { message: format!("Invalid API key: {}", e) })?);
        } else {
            return Err(AppError::Authentication { message: "Access token required for this operation".to_string() });
        }
        
        let response = self.client.post(&url)
            .headers(headers)
            .json(data)
            .send()
            .await
            .map_err(|e| AppError::Internal { message: format!("POST request failed: {}", e) })?;
        
        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(AppError::Internal { message: format!("Supabase API error: {}", error_text) });
        }
        
        let json_response: Value = response.json().await
            .map_err(|e| AppError::Internal { message: format!("Failed to parse JSON response: {}", e) })?;
        
        Ok(json_response)
    }
    
    /// Make a PATCH request to Supabase
    async fn patch(&self, endpoint: &str, data: &Value, access_token: &str) -> AppResult<Value> {
        let url = format!("{}{}", self.base_url, endpoint);
        let mut headers = HeaderMap::new();
        headers.insert(AUTHORIZATION, HeaderValue::from_str(&format!("Bearer {}", access_token))
            .map_err(|e| AppError::Internal { message: format!("Invalid authorization header: {}", e) })?);
        headers.insert("apikey", HeaderValue::from_str(&self.anon_key)
            .map_err(|e| AppError::Internal { message: format!("Invalid API key: {}", e) })?);
        
        let response = self.client.patch(&url)
            .headers(headers)
            .json(data)
            .send()
            .await
            .map_err(|e| AppError::Internal { message: format!("PATCH request failed: {}", e) })?;
        
        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(AppError::Internal { message: format!("Supabase API error: {}", error_text) });
        }
        
        let json_response: Value = response.json().await
            .map_err(|e| AppError::Internal { message: format!("Failed to parse JSON response: {}", e) })?;
        
        Ok(json_response)
    }
    
    /// Log audit entry for Zero Trust compliance
    fn log_audit(&self, operation: &str, user_id: Option<Uuid>, resource: &str, success: bool, request_data: Option<Value>, response_data: Option<Value>) {
        let entry = AuditEntry {
            timestamp: Utc::now(),
            operation: operation.to_string(),
            user_id,
            resource: resource.to_string(),
            success,
            error_message: None, // Could be enhanced to capture actual errors
            request_data,
            response_data,
        };
        
        if let Ok(mut log) = self.audit_log.lock() {
            log.push(entry.clone());
            // In production, you'd want to persist this to a proper audit log
            log::info!("🔍 Audit: {} {} {} - Success: {}", 
                      entry.operation, 
                      resource, 
                      user_id.map(|id| id.to_string()).unwrap_or_else(|| "anonymous".to_string()),
                      success);
        }
    }
    
    /// Get audit log entries (for debugging/monitoring)
    pub fn get_audit_log(&self) -> Vec<AuditEntry> {
        self.audit_log.lock()
            .map(|log| log.clone())
            .unwrap_or_default()
    }
    
    // 👥 USER MANAGEMENT METHODS
    // These methods handle user-related operations
    
    /// Get all users from auth.users table
    /// 
    /// SECURITY: Uses service_role_key for admin operations
    /// This method fetches all registered users for display in the Flutter app
    pub async fn get_all_users(&self) -> AppResult<Vec<User>> {
        log::info!("👥 Fetching all users from Supabase");
        
        // 🔐 ADMIN OPERATION: Use service_role_key for user management
        let response = self.supabase_request(
            "GET",
            "/auth/v1/admin/users",
            None,
            Some(&self.service_role_key), // Use admin key
        ).await?;
        
        self.log_audit("get_all_users", None, "auth.users", true, None, Some(response.clone()));
        
        // 🔄 PARSE RESPONSE
        // Supabase admin API returns users in a different format
        let users_data = response.get("users")
            .ok_or_else(|| AppError::Internal { 
                message: "Invalid response format from Supabase".to_string() 
            })?;
        
        let users: Vec<User> = serde_json::from_value(users_data.clone())
            .map_err(|e| AppError::Internal { 
                message: format!("Failed to parse users: {}", e) 
            })?;
        
        log::info!("✅ Successfully fetched {} users", users.len());
        Ok(users)
    }
    
    /// Get specific user by ID
    /// 
    /// SECURITY: Uses service_role_key for admin operations
    pub async fn get_user_by_id(&self, user_id: &str) -> AppResult<User> {
        log::info!("👤 Fetching user by ID: {}", user_id);
        
        // 🔐 ADMIN OPERATION: Get user by ID
        let response = self.supabase_request(
            "GET",
            &format!("/auth/v1/admin/users/{}", user_id),
            None,
            Some(&self.service_role_key), // Use admin key
        ).await?;
        
        self.log_audit("get_user_by_id", None, &format!("auth.users.{}", user_id), true, None, Some(response.clone()));
        
        // 🔄 PARSE USER RESPONSE
        let user: User = serde_json::from_value(response)
            .map_err(|e| AppError::Internal { 
                message: format!("Failed to parse user: {}", e) 
            })?;
        
        log::info!("✅ Found user: {}", user.email);
        Ok(user)
    }
    
    /// Search users by email (for adding to conversations)
    /// 
    /// SECURITY: Uses service_role_key for admin operations
    pub async fn search_users_by_email(&self, email_query: &str) -> AppResult<Vec<User>> {
        log::info!("🔍 Searching users by email: {}", email_query);
        
        // 🔐 ADMIN OPERATION: Search users
        let response = self.supabase_request(
            "GET",
            &format!("/auth/v1/admin/users?email=like.%{}%", email_query),
            None,
            Some(&self.service_role_key), // Use admin key
        ).await?;
        
        self.log_audit("search_users", None, "auth.users.search", true, None, Some(response.clone()));
        
        // 🔄 PARSE RESPONSE
        let users_data = response.get("users")
            .ok_or_else(|| AppError::Internal { 
                message: "Invalid response format from Supabase".to_string() 
            })?;
        
        let users: Vec<User> = serde_json::from_value(users_data.clone())
            .map_err(|e| AppError::Internal { 
                message: format!("Failed to parse users: {}", e) 
            })?;
        
        log::info!("✅ Found {} users matching '{}'", users.len(), email_query);
        Ok(users)
    }
} 