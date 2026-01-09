// 🔐 ENCRYPTED MESSAGING MODULE
// This module handles the complete encrypted messaging workflow
// It integrates encryption with the Supabase API for end-to-end encrypted chat

use crate::{
    encryption::{EncryptionService, SessionKey, EncryptedMessage, EncryptionError},
    supabase_api::SupabaseClient,
    database::{NewMessage, Message, User},
    errors::AppResult,
};
use serde_json::Value;
use uuid::Uuid;
use chrono::Utc;

// 🔑 ENCRYPTED MESSAGING SERVICE

/// Main service for handling encrypted messaging operations
pub struct EncryptedMessagingService {
    encryption_service: EncryptionService,
    supabase_client: SupabaseClient,
}

impl EncryptedMessagingService {
    /// Create a new encrypted messaging service
    pub fn new(supabase_client: SupabaseClient) -> Self {
        Self {
            encryption_service: EncryptionService::new(),
            supabase_client,
        }
    }

    /// Send an encrypted message
    pub async fn send_encrypted_message(
        &mut self,
        sender_id: Uuid,
        receiver_id: Uuid,
        plaintext_content: &str,
        message_type: Option<crate::database::MessageType>,
        file_url: Option<String>,
        file_size: Option<i64>,
        mime_type: Option<String>,
        access_token: &str,
    ) -> AppResult<Message> {
        // 🔐 STEP 1: Get or create session key for this conversation
        let session_key = self.get_or_create_session_key(sender_id, receiver_id, access_token).await?;
        
        // 🔐 STEP 2: Encrypt the message content
        let encrypted_message = self.encryption_service.encrypt_message(plaintext_content, &session_key)?;
        
        // 🔐 STEP 3: Create the message data for Supabase
        let new_message = NewMessage {
            receiver_id,
            content: encrypted_message.encrypted_content.clone(), // Store encrypted content
            message_type,
            file_url,
            file_size,
            mime_type,
        };
        
        // 🔐 STEP 4: Send to Supabase with encrypted content
        let mut message = self.supabase_client.create_message(&new_message, sender_id, access_token).await?;
        
        // 🔐 STEP 5: Update message with encryption metadata
        // Note: In a real implementation, you'd need to update the message with encryption metadata
        // For now, we'll store this in the session key mapping
        
        Ok(message)
    }

    /// Receive and decrypt messages
    pub async fn receive_encrypted_messages(
        &self,
        user_id: Uuid,
        other_user_id: Uuid,
        limit: i64,
        access_token: &str,
    ) -> AppResult<Vec<DecryptedMessage>> {
        // 🔐 STEP 1: Get encrypted messages from Supabase
        let encrypted_messages = self.supabase_client.get_conversation(user_id, other_user_id, limit, access_token).await?;
        
        // 🔐 STEP 2: Decrypt each message
        let mut decrypted_messages = Vec::new();
        
        for encrypted_msg in encrypted_messages {
            // Get session key for this message
            if let Some(session_key) = self.get_session_key_for_message(&encrypted_msg).await? {
                // Decrypt the message content
                match self.encryption_service.decrypt_message(&self.convert_to_encrypted_message(&encrypted_msg)?, &session_key) {
                    Ok(decrypted_content) => {
                        decrypted_messages.push(DecryptedMessage {
                            id: encrypted_msg.id,
                            sender_id: encrypted_msg.sender_id,
                            receiver_id: encrypted_msg.receiver_id,
                            content: decrypted_content,
                            message_type: encrypted_msg.message_type,
                            is_read: encrypted_msg.is_read,
                            file_url: encrypted_msg.file_url.clone(),
                            file_size: encrypted_msg.file_size,
                            mime_type: encrypted_msg.mime_type.clone(),
                            created_at: encrypted_msg.created_at,
                            updated_at: encrypted_msg.updated_at,
                        });
                    }
                    Err(e) => {
                        log::error!("Failed to decrypt message {}: {}", encrypted_msg.id, e);
                        // Continue with other messages
                    }
                }
            } else {
                log::warn!("No session key found for message {}", encrypted_msg.id);
            }
        }
        
        Ok(decrypted_messages)
    }

    /// Get or create a session key for a conversation
    async fn get_or_create_session_key(
        &mut self,
        user1_id: Uuid,
        user2_id: Uuid,
        access_token: &str,
    ) -> AppResult<SessionKey> {
        // 🔐 STEP 1: Try to get existing session key
        if let Some(session_data) = self.supabase_client.get_conversation_session(user1_id, user2_id, access_token).await? {
            // Parse session data and recreate session key
            // This is a simplified version - in reality you'd need to decrypt the session key
            return self.recreate_session_key_from_data(session_data);
        }
        
        // 🔐 STEP 2: Create new session key
        let session_key = self.encryption_service.generate_session_key()?;
        
        // 🔐 STEP 3: Get both users' public keys
        let user1_key = self.get_user_public_key(user1_id, access_token).await?;
        let user2_key = self.get_user_public_key(user2_id, access_token).await?;
        
        // 🔐 STEP 4: Encrypt session key for both users
        let encrypted_for_user1 = self.encryption_service.encrypt_session_key(&session_key, &user1_key)?;
        let encrypted_for_user2 = self.encryption_service.encrypt_session_key(&session_key, &user2_key)?;
        
        // 🔐 STEP 5: Store session key in database
        let session_data = serde_json::json!({
            "user1_id": user1_id,
            "user2_id": user2_id,
            "encrypted_session_key": encrypted_for_user1, // Store for user1
            "session_key_hash": self.encryption_service.generate_content_hash(&encrypted_for_user1),
            "is_active": true,
            "created_at": Utc::now(),
            "last_used": Utc::now()
        });
        
        self.supabase_client.store_conversation_session(&session_data, access_token).await?;
        
        // 🔐 STEP 6: Store session key in memory for quick access
        self.encryption_service.store_session_key(session_key.clone());
        
        Ok(session_key)
    }

    /// Get session key for a specific message
    async fn get_session_key_for_message(&self, message: &Message) -> AppResult<Option<SessionKey>> {
        // Try to get from memory first
        if let Some(session_key) = self.encryption_service.get_session_key(message.session_key_id) {
            return Ok(Some(session_key.clone()));
        }
        
        // If not in memory, try to get from database
        // This would require implementing session key retrieval from the database
        // For now, return None
        Ok(None)
    }

    /// Get user's public key from database
    async fn get_user_public_key(&self, user_id: Uuid, access_token: &str) -> AppResult<rsa::RsaPublicKey> {
        if let Some(key_data) = self.supabase_client.get_encryption_key(user_id, access_token).await? {
            if let Some(public_key_pem) = key_data.get("public_key").and_then(|v| v.as_str()) {
                return self.encryption_service.import_public_key_pem(public_key_pem)
                    .map_err(|e| crate::errors::AppError::Internal { message: format!("Failed to import public key: {}", e) });
            }
        }
        
        Err(crate::errors::AppError::Internal { 
            message: format!("No public key found for user {}", user_id) 
        })
    }

    /// Recreate session key from stored data
    fn recreate_session_key_from_data(&self, session_data: Value) -> AppResult<SessionKey> {
        // This is a simplified implementation
        // In reality, you'd need to decrypt the session key using the user's private key
        Err(crate::errors::AppError::Internal { 
            message: "Session key recreation not implemented".to_string() 
        })
    }

    /// Convert database Message to EncryptedMessage
    fn convert_to_encrypted_message(&self, message: &Message) -> AppResult<EncryptedMessage> {
        Ok(EncryptedMessage {
            encrypted_content: message.encrypted_content.clone(),
            encrypted_session_key: String::new(), // Not stored in database
            content_hash: message.content_hash.clone(),
            encryption_version: message.encryption_version as u32,
            nonce: message.nonce.clone(),
            session_key_id: message.session_key_id,
        })
    }

    /// Generate encryption keys for a user
    pub async fn generate_user_keys(&mut self, user_id: Uuid, access_token: &str) -> AppResult<()> {
        // 🔐 STEP 1: Generate new key pair
        let key_pair = self.encryption_service.generate_key_pair()?;
        
        // 🔐 STEP 2: Export public key as PEM
        let public_key_pem = self.encryption_service.export_public_key_pem(&key_pair.public_key)?;
        
        // 🔐 STEP 3: Encrypt private key (in real implementation, use user's password)
        let encrypted_private_key = "TODO: Encrypt with user password"; // Placeholder
        
        // 🔐 STEP 4: Store in database
        let key_data = serde_json::json!({
            "user_id": user_id,
            "encrypted_private_key": encrypted_private_key,
            "public_key": public_key_pem,
            "key_version": key_pair.version,
            "algorithm": "RSA-2048",
            "created_at": Utc::now()
        });
        
        self.supabase_client.store_encryption_key(user_id, &key_data, access_token).await?;
        
        Ok(())
    }

    /// Verify message integrity
    pub fn verify_message_integrity(&self, message: &Message, decrypted_content: &str) -> bool {
        let expected_hash = self.encryption_service.generate_content_hash(decrypted_content);
        expected_hash == message.content_hash
    }
}

// 📨 DECRYPTED MESSAGE STRUCTURE

/// Represents a decrypted message that can be displayed to users
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct DecryptedMessage {
    pub id: Uuid,
    pub sender_id: Uuid,
    pub receiver_id: Uuid,
    pub content: String,                    // Decrypted content
    pub message_type: crate::database::MessageType,
    pub is_read: bool,
    pub file_url: Option<String>,
    pub file_size: Option<i64>,
    pub mime_type: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

// 🔧 UTILITY FUNCTIONS

/// Create a deterministic conversation ID
pub fn create_conversation_id(user1_id: Uuid, user2_id: Uuid) -> Uuid {
    crate::encryption::create_conversation_id(user1_id, user2_id)
}

/// Validate encrypted message format
pub fn validate_encrypted_message(message: &Message) -> AppResult<()> {
    if message.encrypted_content.is_empty() {
        return Err(crate::errors::AppError::Internal { 
            message: "Encrypted content is empty".to_string() 
        });
    }
    
    if message.content_hash.is_empty() {
        return Err(crate::errors::AppError::Internal { 
            message: "Content hash is empty".to_string() 
        });
    }
    
    if message.encryption_version <= 0 {
        return Err(crate::errors::AppError::Internal { 
            message: "Invalid encryption version".to_string() 
        });
    }
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::MessageType;

    #[tokio::test]
    async fn test_encrypted_messaging_workflow() {
        // This test would require a mock Supabase client
        // For now, just test the utility functions
        
        let user1 = Uuid::new_v4();
        let user2 = Uuid::new_v4();
        
        let conv_id1 = create_conversation_id(user1, user2);
        let conv_id2 = create_conversation_id(user2, user1);
        
        assert_eq!(conv_id1, conv_id2);
    }

    #[test]
    fn test_message_validation() {
        let valid_message = Message {
            id: Uuid::new_v4(),
            sender_id: Uuid::new_v4(),
            receiver_id: Uuid::new_v4(),
            encrypted_content: "encrypted_content".to_string(),
            content_hash: "hash".to_string(),
            encryption_version: 1,
            nonce: "nonce".to_string(),
            session_key_id: Uuid::new_v4(),
            message_type: MessageType::Text,
            is_read: false,
            file_url: None,
            file_size: None,
            mime_type: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        
        assert!(validate_encrypted_message(&valid_message).is_ok());
    }
} 