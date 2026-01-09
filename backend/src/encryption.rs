// 🔐 ENCRYPTION MODULE
// This module handles all cryptographic operations for end-to-end encrypted messaging
// Following Zero Trust principles: never trust, always verify

use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Key, Nonce,
};
use base64::{Engine as _, engine::general_purpose};
use rsa::{
    pkcs8::{EncodePublicKey, DecodePublicKey, LineEnding},
    RsaPrivateKey, RsaPublicKey,
};
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use uuid::Uuid;
use rand::Rng;

// 🔑 ENCRYPTION TYPES AND STRUCTURES

/// Represents an encryption key pair for a user
#[derive(Debug, Clone)]
pub struct EncryptionKeyPair {
    pub private_key: RsaPrivateKey,
    pub public_key: RsaPublicKey,
    pub key_id: Uuid,
    pub version: u32,
}

/// Represents an encrypted message with all necessary metadata
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct EncryptedMessage {
    pub encrypted_content: String,        // Base64 encoded AES encrypted content
    pub encrypted_session_key: String,    // Base64 encoded RSA encrypted session key
    pub content_hash: String,             // SHA-256 hash of original content
    pub encryption_version: u32,          // Version for future upgrades
    pub nonce: String,                    // Base64 encoded AES nonce
    pub session_key_id: Uuid,             // ID of the session key used
}

/// Represents a session key for a conversation
#[derive(Debug, Clone)]
pub struct SessionKey {
    pub key: [u8; 32],           // 256-bit AES key
    pub nonce: [u8; 12],         // 96-bit nonce
    pub session_id: Uuid,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

/// Error types for encryption operations
#[derive(Debug, thiserror::Error)]
pub enum EncryptionError {
    #[error("Failed to generate encryption key: {0}")]
    KeyGenerationFailed(String),
    
    #[error("Failed to encrypt data: {0}")]
    EncryptionFailed(String),
    
    #[error("Failed to decrypt data: {0}")]
    DecryptionFailed(String),
    
    #[error("Invalid key format: {0}")]
    InvalidKeyFormat(String),
    
    #[error("Hash verification failed: {0}")]
    HashVerificationFailed(String),
    
    #[error("Session key not found: {0}")]
    SessionKeyNotFound(Uuid),
    
    #[error("Invalid message format: {0}")]
    InvalidMessageFormat(String),
}

// 🔐 ENCRYPTION SERVICE

/// Main encryption service that handles all cryptographic operations
pub struct EncryptionService {
    // In-memory storage for session keys (in production, use Redis or similar)
    session_keys: HashMap<Uuid, SessionKey>,
}

impl EncryptionService {
    /// Create a new encryption service
    pub fn new() -> Self {
        Self {
            session_keys: HashMap::new(),
        }
    }

    /// Generate a new RSA key pair for a user
    pub fn generate_key_pair(&self) -> Result<EncryptionKeyPair, EncryptionError> {
        // Generate a new RSA private key (2048 bits for security)
        let private_key = RsaPrivateKey::new(&mut OsRng, 2048)
            .map_err(|e| EncryptionError::KeyGenerationFailed(e.to_string()))?;
        
        // Extract the public key from the private key
        let public_key = RsaPublicKey::from(&private_key);
        
        Ok(EncryptionKeyPair {
            private_key,
            public_key,
            key_id: Uuid::new_v4(),
            version: 1,
        })
    }

    /// Generate a session key for a conversation
    pub fn generate_session_key(&self) -> Result<SessionKey, EncryptionError> {
        // Generate a random 256-bit AES key
        let mut key = [0u8; 32];
        OsRng.fill(&mut key);
        
        // Generate a random 96-bit nonce
        let mut nonce = [0u8; 12];
        OsRng.fill(&mut nonce);
        
        Ok(SessionKey {
            key,
            nonce,
            session_id: Uuid::new_v4(),
            created_at: chrono::Utc::now(),
        })
    }

    /// Encrypt a message using AES-GCM with a session key
    pub fn encrypt_message(
        &self,
        content: &str,
        session_key: &SessionKey,
    ) -> Result<EncryptedMessage, EncryptionError> {
        // Create AES-GCM cipher
        let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(&session_key.key));
        
        // Create nonce from session key nonce
        let nonce = Nonce::from_slice(&session_key.nonce);
        
        // Encrypt the content
        let encrypted_content = cipher
            .encrypt(nonce, content.as_bytes())
            .map_err(|e| EncryptionError::EncryptionFailed(e.to_string()))?;
        
        // Generate hash of original content for integrity verification
        let content_hash = self.generate_content_hash(content);
        
        Ok(EncryptedMessage {
            encrypted_content: general_purpose::STANDARD.encode(&encrypted_content),
            encrypted_session_key: String::new(), // Will be set by caller
            content_hash,
            encryption_version: 1,
            nonce: general_purpose::STANDARD.encode(&session_key.nonce),
            session_key_id: session_key.session_id,
        })
    }

    /// Decrypt a message using AES-GCM with a session key
    pub fn decrypt_message(
        &self,
        encrypted_message: &EncryptedMessage,
        session_key: &SessionKey,
    ) -> Result<String, EncryptionError> {
        // Create AES-GCM cipher
        let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(&session_key.key));
        
        // Decode the encrypted content
        let encrypted_content = general_purpose::STANDARD
            .decode(&encrypted_message.encrypted_content)
            .map_err(|e| EncryptionError::DecryptionFailed(format!("Invalid base64: {}", e)))?;
        
        // Create nonce
        let nonce = Nonce::from_slice(&session_key.nonce);
        
        // Decrypt the content
        let decrypted_content = cipher
            .decrypt(nonce, encrypted_content.as_ref())
            .map_err(|e| EncryptionError::DecryptionFailed(e.to_string()))?;
        
        // Convert to string
        let content = String::from_utf8(decrypted_content)
            .map_err(|e| EncryptionError::DecryptionFailed(format!("Invalid UTF-8: {}", e)))?;
        
        // Verify content hash
        let expected_hash = self.generate_content_hash(&content);
        if expected_hash != encrypted_message.content_hash {
            return Err(EncryptionError::HashVerificationFailed(
                "Content hash verification failed".to_string(),
            ));
        }
        
        Ok(content)
    }

    /// Encrypt a session key with a user's public key
    pub fn encrypt_session_key(
        &self,
        session_key: &SessionKey,
        public_key: &RsaPublicKey,
    ) -> Result<String, EncryptionError> {
        // Convert session key to bytes
        let session_key_bytes = session_key.key.to_vec();
        
        // Encrypt with RSA public key
        let encrypted_session_key = public_key
            .encrypt(&mut OsRng, rsa::Pkcs1v15Encrypt, &session_key_bytes)
            .map_err(|e| EncryptionError::EncryptionFailed(e.to_string()))?;
        
        // Encode as base64
        Ok(general_purpose::STANDARD.encode(&encrypted_session_key))
    }

    /// Decrypt a session key with a user's private key
    pub fn decrypt_session_key(
        &self,
        encrypted_session_key: &str,
        private_key: &RsaPrivateKey,
    ) -> Result<[u8; 32], EncryptionError> {
        // Decode from base64
        let encrypted_bytes = general_purpose::STANDARD
            .decode(encrypted_session_key)
            .map_err(|e| EncryptionError::DecryptionFailed(format!("Invalid base64: {}", e)))?;
        
        // Decrypt with RSA private key
        let decrypted_bytes = private_key
            .decrypt(rsa::Pkcs1v15Encrypt, &encrypted_bytes)
            .map_err(|e| EncryptionError::DecryptionFailed(e.to_string()))?;
        
        // Convert to fixed-size array
        if decrypted_bytes.len() != 32 {
            return Err(EncryptionError::DecryptionFailed(
                "Invalid session key length".to_string(),
            ));
        }
        
        let mut key = [0u8; 32];
        key.copy_from_slice(&decrypted_bytes);
        Ok(key)
    }

    /// Generate SHA-256 hash of content
    pub fn generate_content_hash(&self, content: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(content.as_bytes());
        hex::encode(hasher.finalize())
    }

    /// Store a session key in memory (in production, use Redis)
    pub fn store_session_key(&mut self, session_key: SessionKey) {
        self.session_keys.insert(session_key.session_id, session_key);
    }

    /// Retrieve a session key from memory
    pub fn get_session_key(&self, session_id: Uuid) -> Option<&SessionKey> {
        self.session_keys.get(&session_id)
    }

    /// Export public key as PEM format
    pub fn export_public_key_pem(&self, public_key: &RsaPublicKey) -> Result<String, EncryptionError> {
        public_key
            .to_public_key_pem(LineEnding::LF)
            .map_err(|e| EncryptionError::InvalidKeyFormat(e.to_string()))
    }

    /// Import public key from PEM format
    pub fn import_public_key_pem(&self, pem: &str) -> Result<RsaPublicKey, EncryptionError> {
        RsaPublicKey::from_public_key_pem(pem)
            .map_err(|e| EncryptionError::InvalidKeyFormat(e.to_string()))
    }
}

// 🔧 UTILITY FUNCTIONS

/// Create a conversation ID from two user IDs (deterministic)
pub fn create_conversation_id(user1_id: Uuid, user2_id: Uuid) -> Uuid {
    // Sort the UUIDs to ensure consistent conversation ID regardless of order
    let (smaller, larger) = if user1_id < user2_id {
        (user1_id, user2_id)
    } else {
        (user2_id, user1_id)
    };
    
    // Create a deterministic UUID from the sorted user IDs
    let mut hasher = Sha256::new();
    hasher.update(smaller.as_bytes());
    hasher.update(larger.as_bytes());
    let hash = hasher.finalize();
    
    // Use first 16 bytes of hash as UUID
    let mut uuid_bytes = [0u8; 16];
    uuid_bytes.copy_from_slice(&hash[..16]);
    
    // Set version (4) and variant bits
    uuid_bytes[6] = (uuid_bytes[6] & 0x0f) | 0x40; // Version 4
    uuid_bytes[8] = (uuid_bytes[8] & 0x3f) | 0x80; // Variant 1
    
    Uuid::from_bytes(uuid_bytes)
}

/// Validate that a message is properly encrypted
pub fn validate_encrypted_message(message: &EncryptedMessage) -> Result<(), EncryptionError> {
    // Check that required fields are present
    if message.encrypted_content.is_empty() {
        return Err(EncryptionError::InvalidMessageFormat(
            "Encrypted content is empty".to_string(),
        ));
    }
    
    if message.content_hash.is_empty() {
        return Err(EncryptionError::InvalidMessageFormat(
            "Content hash is empty".to_string(),
        ));
    }
    
    if message.encryption_version == 0 {
        return Err(EncryptionError::InvalidMessageFormat(
            "Invalid encryption version".to_string(),
        ));
    }
    
    // Validate base64 encoding
    if general_purpose::STANDARD.decode(&message.encrypted_content).is_err() {
        return Err(EncryptionError::InvalidMessageFormat(
            "Invalid base64 encoding in encrypted content".to_string(),
        ));
    }
    
    if general_purpose::STANDARD.decode(&message.nonce).is_err() {
        return Err(EncryptionError::InvalidMessageFormat(
            "Invalid base64 encoding in nonce".to_string(),
        ));
    }
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_key_generation() {
        let service = EncryptionService::new();
        let key_pair = service.generate_key_pair().unwrap();
        
        assert_eq!(key_pair.version, 1);
        assert_ne!(key_pair.key_id, Uuid::nil());
    }

    #[test]
    fn test_session_key_generation() {
        let service = EncryptionService::new();
        let session_key = service.generate_session_key().unwrap();
        
        assert_ne!(session_key.session_id, Uuid::nil());
        assert_eq!(session_key.key.len(), 32);
        assert_eq!(session_key.nonce.len(), 12);
    }

    #[test]
    fn test_message_encryption_decryption() {
        let mut service = EncryptionService::new();
        let session_key = service.generate_session_key().unwrap();
        let original_content = "Hello, encrypted world!";
        
        // Encrypt
        let encrypted = service.encrypt_message(original_content, &session_key).unwrap();
        
        // Decrypt
        let decrypted = service.decrypt_message(&encrypted, &session_key).unwrap();
        
        assert_eq!(original_content, decrypted);
    }

    #[test]
    fn test_conversation_id_consistency() {
        let user1 = Uuid::new_v4();
        let user2 = Uuid::new_v4();
        
        let conv1 = create_conversation_id(user1, user2);
        let conv2 = create_conversation_id(user2, user1);
        
        assert_eq!(conv1, conv2);
    }
} 