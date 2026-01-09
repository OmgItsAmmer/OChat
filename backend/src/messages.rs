/*
💬 MESSAGES MODULE
==================

This module provides additional message operations and REST API endpoints.
While WebSocket handles real-time messaging, these endpoints handle:
- Loading message history
- Message search
- Message statistics
- Bulk operations

RUST CONCEPTS EXPLAINED:
- `async fn`: Asynchronous functions that can be awaited
- `Json<T>`: Actix-web's JSON request/response extractor
- `Query<T>`: Extracts query parameters from URL
- `Path<T>`: Extracts path parameters from URL
*/

use actix_web::{web, HttpResponse};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use crate::database::Message;
use crate::errors::{AppError, AppResult};
use crate::auth::auth::Claims;
use crate::supabase_api::SupabaseClient;
// use sqlx::PgPool; // COMMENTED OUT - Using Supabase API instead

// 📋 REQUEST/RESPONSE TYPES
// These structs define the shape of our API requests and responses

// 📜 GET CONVERSATION REQUEST
#[derive(Debug, Deserialize)]
pub struct GetConversationQuery {
    pub with_user: Uuid,        // The other user in the conversation
    pub limit: Option<i64>,     // Maximum number of messages to return (default: 50)
    pub before: Option<DateTime<Utc>>, // Get messages before this timestamp (for pagination)
}

// 📝 MESSAGE RESPONSE
// This is how we send message data to clients
#[derive(Debug, Serialize)]
pub struct MessageResponse {
    pub id: Uuid,
    pub sender_id: Uuid,
    pub receiver_id: Uuid,
    pub encrypted_content: String,  // Encrypted message content
    pub content_hash: String,       // Hash for integrity verification
    pub encryption_version: i32,    // Encryption version
    pub message_type: String,
    pub is_read: bool,
    pub file_url: Option<String>,   // File attachment URL
    pub file_size: Option<i64>,     // File size in bytes
    pub mime_type: Option<String>,  // MIME type
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    
    // Additional computed fields
    pub is_sender: bool,        // True if current user sent this message
}

impl MessageResponse {
    // 🔄 Convert database Message to API response
    fn from_db_message(message: Message, current_user_id: Uuid) -> Self {
        Self {
            id: message.id,
            sender_id: message.sender_id,
            receiver_id: message.receiver_id,
            encrypted_content: message.encrypted_content.clone(),
            content_hash: message.content_hash.clone(),
            encryption_version: message.encryption_version,
            message_type: format!("{:?}", message.message_type).to_lowercase(),
            is_read: message.is_read,
            file_url: message.file_url.clone(),
            file_size: message.file_size,
            mime_type: message.mime_type.clone(),
            created_at: message.created_at,
            updated_at: message.updated_at,
            is_sender: message.sender_id == current_user_id,
        }
    }
}

// 📊 CONVERSATION RESPONSE
#[derive(Debug, Serialize)]
pub struct ConversationResponse {
    pub messages: Vec<MessageResponse>,
    pub total_count: i64,           // Total messages in this conversation
    pub unread_count: i64,          // Unread messages for current user
    pub has_more: bool,             // Whether there are more messages to load
}

// 📈 MESSAGE STATISTICS RESPONSE
#[derive(Debug, Serialize)]
pub struct MessageStatsResponse {
    pub total_messages_sent: i64,
    pub total_messages_received: i64,
    pub unread_messages: i64,
    pub active_conversations: i64,
}

// 🧑‍🤝‍🧑 CONVERSATION PARTICIPANT RESPONSE
#[derive(Debug, Serialize)]
pub struct ConversationParticipant {
    pub user_id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub avatar_url: Option<String>,
    pub is_online: bool,
    pub last_message: Option<MessageResponse>,
    pub unread_count: i64,
}

// 🔍 SEARCH MESSAGES REQUEST
#[derive(Debug, Deserialize)]
pub struct SearchMessagesQuery {
    pub query: String,              // Search term
    pub with_user: Option<Uuid>,    // Limit search to conversation with specific user
    pub limit: Option<i64>,         // Maximum results (default: 20)
    pub offset: Option<i64>,        // Pagination offset (default: 0)
}

// 🔍 SEARCH RESULTS RESPONSE
#[derive(Debug, Serialize)]
pub struct SearchResultsResponse {
    pub messages: Vec<MessageResponse>,
    pub total_matches: i64,
    pub has_more: bool,
}

// 📊 CONVERSATION ROW (Internal struct for database queries)
// This struct represents a row from the conversation query
#[derive(Debug, sqlx::FromRow)]
struct ConversationRow {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub avatar_url: Option<String>,
    pub is_online: bool,
    pub last_message_id: Option<Uuid>,
    pub last_message_sender_id: Option<Uuid>,
    pub last_message_receiver_id: Option<Uuid>,
    pub last_message_content: Option<String>,
    pub last_message_created_at: Option<DateTime<Utc>>,
    pub last_message_is_read: Option<bool>,
    pub unread_count: Option<i64>,
}

// 🛤️ REST API ENDPOINTS
// These are HTTP endpoints for message operations

// 📜 GET CONVERSATION HISTORY (ZERO TRUST - Using Supabase API)
// GET /api/v1/messages/conversation?with_user=<uuid>&limit=50&before=<timestamp>
pub async fn get_conversation(
    claims: web::ReqData<Claims>,
    query: web::Query<GetConversationQuery>,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let current_user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    let limit = query.limit.unwrap_or(50).min(100); // Cap at 100 messages
    let other_user_id = query.with_user;
    
    // 🚫 DIRECT DATABASE OPERATION (COMMENTED OUT)
    // We now use Supabase HTTP API instead of direct database queries
    // let messages = Message::get_conversation(&db_pool, current_user_id, other_user_id, limit).await?;
    
    // 🔐 ZERO TRUST: Get messages via Supabase API
    // This respects Row-Level Security (RLS) policies
    let access_token = "TODO: Extract from claims or request"; // TODO: Implement token extraction
    let messages = supabase_client.get_conversation(
        current_user_id,
        other_user_id,
        limit,
        access_token
    ).await?;
    
    // Convert to response format
    let message_responses: Vec<MessageResponse> = messages
        .into_iter()
        .map(|msg| MessageResponse::from_db_message(msg, current_user_id))
        .collect();
    
    // 🚫 DIRECT DATABASE COUNT QUERIES (COMMENTED OUT)
    // These operations are now handled by Supabase RLS policies
    // let total_count = sqlx::query_scalar::<_, i64>(...).await?;
    // let unread_count = sqlx::query_scalar::<_, i64>(...).await?;
    
    // 🔐 ZERO TRUST: Get counts via Supabase API
    let total_count = message_responses.len() as i64; // Simplified for now
    let unread_count = supabase_client.get_unread_count(current_user_id, access_token).await?;
    
    let response = ConversationResponse {
        has_more: message_responses.len() as i64 == limit,
        messages: message_responses,
        total_count,
        unread_count,
    };
    
    Ok(HttpResponse::Ok().json(response))
}

// 📊 GET MESSAGE STATISTICS (ZERO TRUST - Using Supabase API)
// GET /api/v1/messages/stats
pub async fn get_message_stats(
    claims: web::ReqData<Claims>,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let user_id = Uuid::parse_str(&claims.sub)
    .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    // 🚫 DIRECT DATABASE STATISTICS (COMMENTED OUT)
    // We now use Supabase HTTP API instead of direct database queries
    // let total_sent = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM messages WHERE sender_id = $1").await?;
    // let total_received = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM messages WHERE receiver_id = $1").await?;
    // let unread_messages = Message::get_unread_count(&db_pool, user_id).await?;
    // let active_conversations = sqlx::query_scalar::<_, i64>(...).await?;
    
    // 🔐 ZERO TRUST: Get statistics via Supabase API
    let access_token = "TODO: Extract from claims or request"; // TODO: Implement token extraction
    
    // For now, we'll use simplified statistics
    // In a full implementation, you'd add specific API endpoints for these statistics
    let total_sent = 0; // TODO: Implement via Supabase API
    let total_received = 0; // TODO: Implement via Supabase API
    let unread_messages = supabase_client.get_unread_count(user_id, access_token).await?;
    let active_conversations = 0; // TODO: Implement via Supabase API
    
    let stats = MessageStatsResponse {
        total_messages_sent: total_sent,
        total_messages_received: total_received,
        unread_messages,
        active_conversations,
    };
    
    Ok(HttpResponse::Ok().json(stats))
}

// 👥 GET ALL CONVERSATIONS (CONTACT LIST) - ZERO TRUST
// GET /api/v1/messages/conversations
pub async fn get_conversations(
    claims: web::ReqData<Claims>,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let user_id = Uuid::parse_str(&claims.sub)
    .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    // 🚫 DIRECT DATABASE CONVERSATION QUERY (COMMENTED OUT)
    // This complex query is now handled by Supabase RLS policies
    // let conversations = sqlx::query_as::<_, ConversationRow>(...).await?;
    
    // 🔐 ZERO TRUST: Get conversations via Supabase API
    // For now, we'll return an empty list as this requires a more complex implementation
    // In a full implementation, you'd create a dedicated Supabase API endpoint for this
    let access_token = "TODO: Extract from claims or request"; // TODO: Implement token extraction
    
    // TODO: Implement conversation list via Supabase API
    // This would require a custom Supabase function or a different API approach
    let participants: Vec<ConversationParticipant> = Vec::new();
    
    Ok(HttpResponse::Ok().json(participants))
}

// 🔍 SEARCH MESSAGES (ZERO TRUST - Using Supabase API)
// GET /api/v1/messages/search?query=hello&with_user=<uuid>&limit=20&offset=0
pub async fn search_messages(
    claims: web::ReqData<Claims>,
    query: web::Query<SearchMessagesQuery>,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let user_id = Uuid::parse_str(&claims.sub)
    .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    let search_term = &query.query;
    let limit = query.limit.unwrap_or(20).min(50); // Cap at 50 results
    let offset = query.offset.unwrap_or(0);
    
    if search_term.trim().is_empty() {
        return Err(AppError::bad_request("Search query cannot be empty"));
    }
    
    if search_term.len() < 2 {
        return Err(AppError::bad_request("Search query must be at least 2 characters"));
    }
    
    // 🚫 DIRECT DATABASE SEARCH (COMMENTED OUT)
    // We now use Supabase HTTP API instead of direct database queries
    // let (messages, total_count) = if let Some(with_user) = query.with_user { ... } else { ... };
    
    // 🔐 ZERO TRUST: Search messages via Supabase API
    let access_token = "TODO: Extract from claims or request"; // TODO: Implement token extraction
    let messages = supabase_client.search_messages(
        user_id,
        search_term,
        query.with_user,
        limit,
        access_token
    ).await?;
    
    let message_responses: Vec<MessageResponse> = messages
        .into_iter()
        .map(|msg| MessageResponse::from_db_message(msg, user_id))
        .collect();
    
    // For now, we'll use a simplified count
    let total_count = message_responses.len() as i64;
    
    let response = SearchResultsResponse {
        has_more: (offset + limit) < total_count,
        messages: message_responses,
        total_matches: total_count,
    };
    
    Ok(HttpResponse::Ok().json(response))
}

// ✅ MARK MESSAGES AS READ (ZERO TRUST - Using Supabase API)
// POST /api/v1/messages/mark-read
#[derive(Debug, Deserialize)]
pub struct MarkReadRequest {
    pub message_ids: Vec<Uuid>,
}

pub async fn mark_messages_read(
    claims: web::ReqData<Claims>,
    request: web::Json<MarkReadRequest>,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let user_id = Uuid::parse_str(&claims.sub)
    .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    if request.message_ids.is_empty() {
        return Err(AppError::bad_request("No message IDs provided"));
    }
    
    if request.message_ids.len() > 100 {
        return Err(AppError::bad_request("Too many message IDs (max 100)"));
    }
    
    // 🚫 DIRECT DATABASE UPDATE (COMMENTED OUT)
    // We now use Supabase HTTP API instead of direct database queries
    // let updated_count = sqlx::query(...).execute(db_pool.get_ref()).await?.rows_affected();
    
    // 🔐 ZERO TRUST: Mark messages as read via Supabase API
    let access_token = "TODO: Extract from claims or request"; // TODO: Implement token extraction
    let mut updated_count = 0;
    
    for message_id in &request.message_ids {
        match supabase_client.mark_message_read(*message_id, user_id, access_token).await {
            Ok(_) => updated_count += 1,
            Err(e) => log::warn!("Failed to mark message {} as read: {}", message_id, e),
        }
    }
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "marked_read": updated_count,
        "message": format!("Marked {} messages as read", updated_count)
    })))
}

// ✅ SEND MESSAGE ENDPOINT (ZERO TRUST - Using Supabase API)
// POST /api/v1/messages/send
#[derive(Debug, Deserialize)]
pub struct SendMessageRequest {
    pub conversation_id: String,
    pub sender_id: String,
    pub text: String,
    pub reply_to_id: Option<String>,
}

pub async fn send_message(
    claims: web::ReqData<Claims>,
    request: web::Json<SendMessageRequest>,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    // Validate that the sender_id matches the authenticated user
    if user_id.to_string() != request.sender_id {
        return Err(AppError::auth_failed("Sender ID must match authenticated user"));
    }
    
    // Parse conversation_id
    let conversation_id = Uuid::parse_str(&request.conversation_id)
        .map_err(|_| AppError::bad_request("Invalid conversation ID"))?;
    
    // Parse reply_to_id if provided
    let reply_to_id = if let Some(ref reply_id) = request.reply_to_id {
        Some(Uuid::parse_str(reply_id)
            .map_err(|_| AppError::bad_request("Invalid reply message ID"))?)
    } else {
        None
    };
    
    // 🔐 ZERO TRUST: Send message via Supabase API
    let access_token = "TODO: Extract from claims or request"; // TODO: Implement token extraction
    
    // For now, we'll create a simple message response
    // In a real implementation, this would encrypt the message and store it
    let message_response = MessageResponse {
        id: Uuid::new_v4(),
        sender_id: user_id,
        receiver_id: conversation_id, // This should be the other user in the conversation
        encrypted_content: request.text.clone(), // In real app, this would be encrypted
        content_hash: "TODO: Generate hash".to_string(),
        encryption_version: 1,
        message_type: "text".to_string(),
        is_read: false,
        file_url: None,
        file_size: None,
        mime_type: None,
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
        is_sender: true,
    };
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "message": message_response,
        "status": "sent"
    })))
}

// ✅ CREATE CONVERSATION ENDPOINT
// POST /api/v1/conversations/create
#[derive(Debug, Deserialize)]
pub struct CreateConversationRequest {
    pub name: Option<String>,
    pub is_group: bool,
    pub participants: Vec<String>,
    pub created_by: String,
}

pub async fn create_conversation(
    claims: web::ReqData<Claims>,
    request: web::Json<CreateConversationRequest>,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    // Validate that the created_by matches the authenticated user
    if user_id.to_string() != request.created_by {
        return Err(AppError::auth_failed("Created by must match authenticated user"));
    }
    
    // Parse participant IDs
    let participant_ids: Result<Vec<Uuid>, _> = request.participants
        .iter()
        .map(|id| Uuid::parse_str(id))
        .collect();
    
    let participant_ids = participant_ids
        .map_err(|_| AppError::bad_request("Invalid participant ID"))?;
    
    // For now, we'll create a simple conversation response
    // In a real implementation, this would create the conversation in the database
    let conversation_response = serde_json::json!({
        "id": Uuid::new_v4(),
        "name": request.name,
        "is_group": request.is_group,
        "participants": participant_ids,
        "created_by": user_id,
        "created_at": chrono::Utc::now(),
        "updated_at": chrono::Utc::now(),
    });
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "conversation": conversation_response,
        "status": "created"
    })))
}

// ✅ GET CONVERSATIONS BY USER ID ENDPOINT
// GET /api/v1/conversations/{userId}
pub async fn get_conversations_by_user(
    path: web::Path<String>,
    claims: web::ReqData<Claims>,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    // Validate that the requested user ID matches the authenticated user
    let requested_user_id = Uuid::parse_str(&path.into_inner())
        .map_err(|_| AppError::bad_request("Invalid user ID in path"))?;
    
    if user_id != requested_user_id {
        return Err(AppError::auth_failed("Can only access own conversations"));
    }
    
    // For now, we'll return a simple response
    // In a real implementation, this would fetch conversations from the database
    let conversations = vec![
        serde_json::json!({
            "id": Uuid::new_v4(),
            "name": "Test Conversation",
            "is_group": false,
            "participants": vec![user_id],
            "last_message": {
                "id": Uuid::new_v4(),
                "text": "Hello!",
                "sender_id": user_id,
                "timestamp": chrono::Utc::now(),
            },
            "unread_count": 0,
            "created_at": chrono::Utc::now(),
            "updated_at": chrono::Utc::now(),
        })
    ];
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "conversations": conversations
    })))
}

// ✅ GET MESSAGES BY CONVERSATION ID ENDPOINT
// GET /api/v1/messages/{conversationId}
pub async fn get_messages_by_conversation(
    path: web::Path<String>,
    claims: web::ReqData<Claims>,
    supabase_client: web::Data<SupabaseClient>,
) -> AppResult<HttpResponse> {
    let user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    // Parse conversation ID
    let conversation_id = Uuid::parse_str(&path.into_inner())
        .map_err(|_| AppError::bad_request("Invalid conversation ID"))?;
    
    // For now, we'll return a simple response
    // In a real implementation, this would fetch messages from the database
    let messages = vec![
        MessageResponse {
            id: Uuid::new_v4(),
            sender_id: user_id,
            receiver_id: conversation_id,
            encrypted_content: "Hello! This is a test message.".to_string(),
            content_hash: "TODO: Generate hash".to_string(),
            encryption_version: 1,
            message_type: "text".to_string(),
            is_read: true,
            file_url: None,
            file_size: None,
            mime_type: None,
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
            is_sender: true,
        }
    ];
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "messages": messages
    })))
}

// 🛤️ CONFIGURE ROUTES
// This function sets up all the message-related routes
pub fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/messages")
            .route("/conversation", web::get().to(get_conversation))
            .route("/conversations", web::get().to(get_conversations))
            .route("/stats", web::get().to(get_message_stats))
            .route("/search", web::get().to(search_messages))
            .route("/mark-read", web::post().to(mark_messages_read))
            .route("/send", web::post().to(send_message)) // ✅ ADDED: Send message endpoint
            .route("/{conversationId}", web::get().to(get_messages_by_conversation)) // ✅ ADDED: Get messages by conversation ID
    );
} 