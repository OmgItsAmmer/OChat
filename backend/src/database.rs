/*
🗄️ DATABASE MODULE
==================

This module handles all database operations for our messaging app.

RUST CONCEPTS EXPLAINED:
- `sqlx`: An async SQL toolkit with compile-time checked queries
- `Pool`: A connection pool that manages multiple database connections
- `#[derive]`: Automatically implements traits for structs
- `sqlx::FromRow`: Allows automatic conversion from database rows to Rust structs

DATABASE DESIGN:
- `users` table: Stores user information from Supabase
- `messages` table: Stores all chat messages
- `conversations` table: Tracks conversation participants (for future use)
*/

use sqlx::{PgPool, Row};
use chrono::{DateTime, Utc};
use uuid::Uuid;
use serde::{Deserialize, Serialize};
use crate::errors::{AppError, AppResult};

// 🏗️ DATABASE MODELS
// These structs represent our database tables

// 👤 USER MODEL
// Represents a user in our system (synced with Supabase Auth)
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,                    // User ID from Supabase (matches JWT 'sub' claim)
    pub email: String,               // User's email address
    pub username: Option<String>,    // Display name (optional)
    pub avatar_url: Option<String>,  // Profile picture URL (optional)
    pub is_online: bool,             // Whether user is currently connected
    pub last_seen: DateTime<Utc>,    // When user was last active
    pub created_at: DateTime<Utc>,   // When account was created
    pub updated_at: DateTime<Utc>,   // When account was last updated
}

// 💬 MESSAGE MODEL
// Represents a chat message between users
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Message {
    pub id: Uuid,                    // Unique message ID
    pub sender_id: Uuid,             // Who sent the message
    pub receiver_id: Uuid,           // Who should receive the message
    pub content: String,             // The actual message text
    pub message_type: MessageType,   // Type of message (text, image, etc.)
    pub is_read: bool,               // Whether message has been read
    pub created_at: DateTime<Utc>,   // When message was sent
    pub updated_at: DateTime<Utc>,   // When message was last modified
}

// 📝 MESSAGE TYPES
// Enum to represent different types of messages
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "message_type", rename_all = "lowercase")]
pub enum MessageType {
    Text,        // Plain text message
    Image,       // Image message
    File,        // File attachment
    System,      // System message (user joined, etc.)
}

// 📨 NEW MESSAGE DTO (Data Transfer Object)
// This struct is used when creating new messages
// RUST PATTERN: Separate structs for different use cases
#[derive(Debug, Deserialize)]
pub struct NewMessage {
    pub receiver_id: Uuid,
    pub content: String,
    pub message_type: Option<MessageType>,
}

// 🔗 DATABASE CONNECTION POOL
// Creates a connection pool to PostgreSQL
// RUST BEST PRACTICE: Use connection pooling for better performance
pub async fn create_pool(database_url: &str) -> AppResult<PgPool> {
    log::info!("🔌 Connecting to database...");
    
    let pool = PgPool::connect(database_url)
        .await
        .map_err(|e| AppError::Database(e))?;
    
    log::info!("✅ Database connection established");
    Ok(pool)
}

// 🏃‍♂️ DATABASE MIGRATIONS
// Creates our database tables if they don't exist
// RUST BEST PRACTICE: Run migrations on startup for development
pub async fn run_migrations(pool: &PgPool) -> AppResult<()> {
    log::info!("🏃‍♂️ Running database migrations...");
    
    // Create message_type enum
    sqlx::query(
        r#"
        DO $$ BEGIN
            CREATE TYPE message_type AS ENUM ('text', 'image', 'file', 'system');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
        "#
    )
    .execute(pool)
    .await?;
    
    // Create users table
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id UUID PRIMARY KEY,
            email VARCHAR NOT NULL UNIQUE,
            username VARCHAR,
            avatar_url VARCHAR,
            is_online BOOLEAN NOT NULL DEFAULT false,
            last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        "#
    )
    .execute(pool)
    .await?;
    
    // Create messages table
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS messages (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            content TEXT NOT NULL,
            message_type message_type NOT NULL DEFAULT 'text',
            is_read BOOLEAN NOT NULL DEFAULT false,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        "#
    )
    .execute(pool)
    .await?;
    
    // Create indexes for better query performance
    sqlx::query(
        r#"
        CREATE INDEX IF NOT EXISTS idx_messages_participants 
        ON messages(sender_id, receiver_id);
        
        CREATE INDEX IF NOT EXISTS idx_messages_created_at 
        ON messages(created_at DESC);
        
        CREATE INDEX IF NOT EXISTS idx_users_email 
        ON users(email);
        "#
    )
    .execute(pool)
    .await?;
    
    log::info!("✅ Database migrations completed");
    Ok(())
}

// 🧑‍💼 USER DATABASE OPERATIONS
impl User {
    // 🔍 Find user by ID
    pub async fn find_by_id(pool: &PgPool, user_id: Uuid) -> AppResult<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE id = $1"
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await?;
        
        Ok(user)
    }
    
    // 🔍 Find user by email
    pub async fn find_by_email(pool: &PgPool, email: &str) -> AppResult<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE email = $1"
        )
        .bind(email)
        .fetch_optional(pool)
        .await?;
        
        Ok(user)
    }
    
    // 💾 Create or update user (upsert)
    // This is called when a user authenticates for the first time
    pub async fn upsert(pool: &PgPool, user_id: Uuid, email: &str) -> AppResult<User> {
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (id, email, last_seen, updated_at)
            VALUES ($1, $2, NOW(), NOW())
            ON CONFLICT (id) 
            DO UPDATE SET 
                email = EXCLUDED.email,
                last_seen = NOW(),
                updated_at = NOW()
            RETURNING *
            "#
        )
        .bind(user_id)
        .bind(email)
        .fetch_one(pool)
        .await?;
        
        Ok(user)
    }
    
    // 🟢 Set user online status
    pub async fn set_online_status(pool: &PgPool, user_id: Uuid, is_online: bool) -> AppResult<()> {
        sqlx::query(
            r#"
            UPDATE users 
            SET is_online = $1, last_seen = NOW(), updated_at = NOW()
            WHERE id = $2
            "#
        )
        .bind(is_online)
        .bind(user_id)
        .execute(pool)
        .await?;
        
        Ok(())
    }
}

// 💬 MESSAGE DATABASE OPERATIONS
impl Message {
    // 💾 Create a new message
    pub async fn create(pool: &PgPool, sender_id: Uuid, new_message: NewMessage) -> AppResult<Message> {
        let message = sqlx::query_as::<_, Message>(
            r#"
            INSERT INTO messages (sender_id, receiver_id, content, message_type)
            VALUES ($1, $2, $3, $4)
            RETURNING *
            "#
        )
        .bind(sender_id)
        .bind(new_message.receiver_id)
        .bind(new_message.content)
        .bind(new_message.message_type.unwrap_or(MessageType::Text))
        .fetch_one(pool)
        .await?;
        
        Ok(message)
    }
    
    // 📜 Get conversation between two users
    // Returns messages ordered by creation time (oldest first)
    pub async fn get_conversation(
        pool: &PgPool, 
        user1_id: Uuid, 
        user2_id: Uuid,
        limit: i64
    ) -> AppResult<Vec<Message>> {
        let messages = sqlx::query_as::<_, Message>(
            r#"
            SELECT * FROM messages 
            WHERE (sender_id = $1 AND receiver_id = $2) 
               OR (sender_id = $2 AND receiver_id = $1)
            ORDER BY created_at DESC
            LIMIT $3
            "#
        )
        .bind(user1_id)
        .bind(user2_id)
        .bind(limit)
        .fetch_all(pool)
        .await?;
        
        Ok(messages)
    }
    
    // ✅ Mark message as read
    pub async fn mark_as_read(pool: &PgPool, message_id: Uuid, user_id: Uuid) -> AppResult<()> {
        sqlx::query(
            r#"
            UPDATE messages 
            SET is_read = true, updated_at = NOW()
            WHERE id = $1 AND receiver_id = $2
            "#
        )
        .bind(message_id)
        .bind(user_id)
        .execute(pool)
        .await?;
        
        Ok(())
    }
    
    // 🔢 Get unread message count for user
    pub async fn get_unread_count(pool: &PgPool, user_id: Uuid) -> AppResult<i64> {
        let count = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM messages WHERE receiver_id = $1 AND is_read = false"
        )
        .bind(user_id)
        .fetch_one(pool)
        .await?;
        
        Ok(count)
    }
} 