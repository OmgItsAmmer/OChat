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
use crate::database::{Message, User};
use crate::errors::{AppError, AppResult};
use crate::auth::auth::Claims;
use sqlx::PgPool;

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
    pub content: String,
    pub message_type: String,
    pub is_read: bool,
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
            content: message.content,
            message_type: format!("{:?}", message.message_type).to_lowercase(),
            is_read: message.is_read,
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

// 🛤️ REST API ENDPOINTS
// These are HTTP endpoints for message operations

// 📜 GET CONVERSATION HISTORY
// GET /api/v1/messages/conversation?with_user=<uuid>&limit=50&before=<timestamp>
pub async fn get_conversation(
    claims: web::ReqData<Claims>,
    query: web::Query<GetConversationQuery>,
    db_pool: web::Data<PgPool>,
) -> AppResult<HttpResponse> {
    // let current_user_id = Uuid::parse_str(&claims.get_ref().sub)
    //     .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
        let current_user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    let limit = query.limit.unwrap_or(50).min(100); // Cap at 100 messages
    let other_user_id = query.with_user;
    
    // Get messages from database
    let messages = Message::get_conversation(
        &db_pool,
        current_user_id,
        other_user_id,
        limit,
    ).await?;
    
    // Convert to response format
    let message_responses: Vec<MessageResponse> = messages
        .into_iter()
        .map(|msg| MessageResponse::from_db_message(msg, current_user_id))
        .collect();
    
    // Get total message count for this conversation
    let total_count = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*) FROM messages 
        WHERE (sender_id = $1 AND receiver_id = $2) 
           OR (sender_id = $2 AND receiver_id = $1)
        "#
    )
    .bind(current_user_id)
    .bind(other_user_id)
    .fetch_one(db_pool.get_ref())
    .await?;
    
    // Get unread count for current user
    let unread_count = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*) FROM messages 
        WHERE sender_id = $1 AND receiver_id = $2 AND is_read = false
        "#
    )
    .bind(other_user_id)
    .bind(current_user_id)
    .fetch_one(db_pool.get_ref())
    .await?;
    
    let response = ConversationResponse {
        has_more: message_responses.len() as i64 == limit,
        messages: message_responses,
        total_count,
        unread_count,
    };
    
    Ok(HttpResponse::Ok().json(response))
}

// 📊 GET MESSAGE STATISTICS
// GET /api/v1/messages/stats
pub async fn get_message_stats(
    claims: web::ReqData<Claims>,
    db_pool: web::Data<PgPool>,
) -> AppResult<HttpResponse> {
    let user_id = Uuid::parse_str(&claims.sub)
    .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    // Get various statistics
    let total_sent = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM messages WHERE sender_id = $1"
    )
    .bind(user_id)
    .fetch_one(db_pool.get_ref())
    .await?;
    
    let total_received = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM messages WHERE receiver_id = $1"
    )
    .bind(user_id)
    .fetch_one(db_pool.get_ref())
    .await?;
    
    let unread_messages = Message::get_unread_count(&db_pool, user_id).await?;
    
    let active_conversations = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(DISTINCT 
            CASE 
                WHEN sender_id = $1 THEN receiver_id 
                ELSE sender_id 
            END
        ) 
        FROM messages 
        WHERE sender_id = $1 OR receiver_id = $1
        "#
    )
    .bind(user_id)
    .fetch_one(db_pool.get_ref())
    .await?;
    
    let stats = MessageStatsResponse {
        total_messages_sent: total_sent,
        total_messages_received: total_received,
        unread_messages,
        active_conversations,
    };
    
    Ok(HttpResponse::Ok().json(stats))
}

// 👥 GET ALL CONVERSATIONS (CONTACT LIST)
// GET /api/v1/messages/conversations
pub async fn get_conversations(
    claims: web::ReqData<Claims>,
    db_pool: web::Data<PgPool>,
) -> AppResult<HttpResponse> {
    // let user_id = Uuid::parse_str(&claims.get_ref().sub)
    //     .map_err(|_| AppError::auth_failed("Invalid user ID"))?;

    let user_id = Uuid::parse_str(&claims.sub)
    .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    // Get all users the current user has conversations with
    let conversations = sqlx::query!(
        r#"
        WITH conversation_partners AS (
            SELECT DISTINCT 
                CASE 
                    WHEN sender_id = $1 THEN receiver_id 
                    ELSE sender_id 
                END as partner_id
            FROM messages 
            WHERE sender_id = $1 OR receiver_id = $1
        ),
        latest_messages AS (
            SELECT DISTINCT ON (
                CASE 
                    WHEN sender_id = $1 THEN receiver_id 
                    ELSE sender_id 
                END
            ) 
                CASE 
                    WHEN sender_id = $1 THEN receiver_id 
                    ELSE sender_id 
                END as partner_id,
                id, sender_id, receiver_id, content, created_at, is_read
            FROM messages 
            WHERE sender_id = $1 OR receiver_id = $1
            ORDER BY 
                CASE 
                    WHEN sender_id = $1 THEN receiver_id 
                    ELSE sender_id 
                END,
                created_at DESC
        ),
        unread_counts AS (
            SELECT sender_id as partner_id, COUNT(*) as unread_count
            FROM messages 
            WHERE receiver_id = $1 AND is_read = false
            GROUP BY sender_id
        )
        SELECT 
            u.id, u.email, u.username, u.avatar_url, u.is_online,
            lm.id as last_message_id,
            lm.sender_id as last_message_sender_id,
            lm.receiver_id as last_message_receiver_id,
            lm.content as last_message_content,
            lm.created_at as last_message_created_at,
            lm.is_read as last_message_is_read,
            COALESCE(uc.unread_count, 0) as unread_count
        FROM conversation_partners cp
        JOIN users u ON u.id = cp.partner_id
        LEFT JOIN latest_messages lm ON lm.partner_id = cp.partner_id
        LEFT JOIN unread_counts uc ON uc.partner_id = cp.partner_id
        ORDER BY lm.created_at DESC NULLS LAST
        "#,
        user_id
    )
    .fetch_all(db_pool.get_ref())
    .await?;
    
    let mut participants = Vec::new();
    
    for row in conversations {
        let last_message = if let Some(msg_id) = row.last_message_id {
            Some(MessageResponse {
                id: msg_id,
                sender_id: row.last_message_sender_id.unwrap(),
                receiver_id: row.last_message_receiver_id.unwrap(),
                content: row.last_message_content.unwrap(),
                message_type: "text".to_string(),
                is_read: row.last_message_is_read.unwrap(),
                created_at: row.last_message_created_at.unwrap(),
                updated_at: row.last_message_created_at.unwrap(),
                is_sender: row.last_message_sender_id.unwrap() == user_id,
            })
        } else {
            None
        };
        
        participants.push(ConversationParticipant {
            user_id: row.id,
            email: row.email,
            username: row.username,
            avatar_url: row.avatar_url,
            is_online: row.is_online,
            last_message,
            unread_count: row.unread_count.unwrap_or(0),
        });
    }
    
    Ok(HttpResponse::Ok().json(participants))
}

// 🔍 SEARCH MESSAGES
// GET /api/v1/messages/search?query=hello&with_user=<uuid>&limit=20&offset=0
pub async fn search_messages(
    claims: web::ReqData<Claims>,
    query: web::Query<SearchMessagesQuery>,
    db_pool: web::Data<PgPool>,
) -> AppResult<HttpResponse> {
    // let user_id = Uuid::parse_str(&claims.get_ref().sub)
    //     .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
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
    
    // Build the search query
    let (messages, total_count) = if let Some(with_user) = query.with_user {
        // Search within specific conversation
        let messages = sqlx::query_as::<_, Message>(
            r#"
            SELECT * FROM messages 
            WHERE ((sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1))
              AND content ILIKE $3
            ORDER BY created_at DESC
            LIMIT $4 OFFSET $5
            "#
        )
        .bind(user_id)
        .bind(with_user)
        .bind(format!("%{}%", search_term))
        .bind(limit)
        .bind(offset)
        .fetch_all(db_pool.get_ref())
        .await?;
        
        let count = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM messages 
            WHERE ((sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1))
              AND content ILIKE $3
            "#
        )
        .bind(user_id)
        .bind(with_user)
        .bind(format!("%{}%", search_term))
        .fetch_one(db_pool.get_ref())
        .await?;
        
        (messages, count)
    } else {
        // Search across all conversations
        let messages = sqlx::query_as::<_, Message>(
            r#"
            SELECT * FROM messages 
            WHERE (sender_id = $1 OR receiver_id = $1)
              AND content ILIKE $2
            ORDER BY created_at DESC
            LIMIT $3 OFFSET $4
            "#
        )
        .bind(user_id)
        .bind(format!("%{}%", search_term))
        .bind(limit)
        .bind(offset)
        .fetch_all(db_pool.get_ref())
        .await?;
        
        let count = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM messages 
            WHERE (sender_id = $1 OR receiver_id = $1)
              AND content ILIKE $2
            "#
        )
        .bind(user_id)
        .bind(format!("%{}%", search_term))
        .fetch_one(db_pool.get_ref())
        .await?;
        
        (messages, count)
    };
    
    let message_responses: Vec<MessageResponse> = messages
        .into_iter()
        .map(|msg| MessageResponse::from_db_message(msg, user_id))
        .collect();
    
    let response = SearchResultsResponse {
        has_more: (offset + limit) < total_count,
        messages: message_responses,
        total_matches: total_count,
    };
    
    Ok(HttpResponse::Ok().json(response))
}

// ✅ MARK MESSAGES AS READ
// POST /api/v1/messages/mark-read
#[derive(Debug, Deserialize)]
pub struct MarkReadRequest {
    pub message_ids: Vec<Uuid>,
}

pub async fn mark_messages_read(
    claims: web::ReqData<Claims>,
    request: web::Json<MarkReadRequest>,
    db_pool: web::Data<PgPool>,
) -> AppResult<HttpResponse> {
    // let user_id = Uuid::parse_str(&claims.get_ref().sub)
    //     .map_err(|_| AppError::auth_failed("Invalid user ID"))?;

    let user_id = Uuid::parse_str(&claims.sub)
    .map_err(|_| AppError::auth_failed("Invalid user ID"))?;
    
    if request.message_ids.is_empty() {
        return Err(AppError::bad_request("No message IDs provided"));
    }
    
    if request.message_ids.len() > 100 {
        return Err(AppError::bad_request("Too many message IDs (max 100)"));
    }
    
    // Mark messages as read
    let updated_count = sqlx::query!(
        r#"
        UPDATE messages 
        SET is_read = true, updated_at = NOW()
        WHERE id = ANY($1) AND receiver_id = $2 AND is_read = false
        "#,
        &request.message_ids,
        user_id
    )
    .execute(db_pool.get_ref())
    .await?
    .rows_affected();
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "marked_read": updated_count,
        "message": format!("Marked {} messages as read", updated_count)
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
    );
} 