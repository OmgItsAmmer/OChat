/*
⚙️ CONFIGURATION MODULE
=======================

This module handles loading and managing configuration from environment variables.

RUST CONCEPTS EXPLAINED:
- `struct`: Like a class in other languages, but simpler - just data storage
- `Clone`: Allows the struct to be copied (needed for sharing between threads)
- `Debug`: Allows printing the struct for debugging
- `derive`: Automatically implements traits (like interfaces)
- `std::env`: Standard library for environment variables
*/

use std::env;
use anyhow::{Context, Result};

// 🏗️ CONFIGURATION STRUCT
// This struct holds all our app configuration
// RUST BEST PRACTICE: Use descriptive field names and group related settings
#[derive(Debug, Clone)]
pub struct Config {
    // 🗄️ Database settings
    pub database_url: String,
    pub database_max_connections: u32,
    
    // 🔐 Supabase settings  
    pub supabase_url: String,
    pub supabase_anon_key: String,
    pub supabase_service_role_key: String,
    
    // 🌐 Server settings
    pub server_host: String,
    pub server_port: u16,
    
    // 🛡️ Security settings
    pub jwt_secret: String,
    pub allowed_origins: String,
    
    // ⏱️ Connection settings
    pub websocket_timeout_seconds: u64,
    
    // 🚀 Performance settings
    pub actix_workers: usize,
}

impl Config {
    // 📖 CONSTRUCTOR FROM ENVIRONMENT
    // This function creates a Config struct from environment variables
    // RUST CONCEPT: `Result<T, E>` means this function can either:
    // - Return Ok(Config) if successful
    // - Return Err(error) if something goes wrong
    pub fn from_env() -> Result<Self> {
        // 🔍 HELPER FUNCTION TO GET ENV VARS
        // This closure makes it easier to get environment variables with error context
        let get_env = |key: &str| -> Result<String> {
            env::var(key).with_context(|| format!("Missing environment variable: {}", key))
        };
        
        // 🔢 HELPER FUNCTION TO PARSE NUMBERS
        // This closure parses string environment variables into numbers
        let parse_env = |key: &str, default: &str| -> Result<String> {
            Ok(env::var(key).unwrap_or_else(|_| default.to_string()))
        };
        
        Ok(Config {
            // 🗄️ Database configuration
            database_url: get_env("DATABASE_URL")?,
            database_max_connections: parse_env("DATABASE_MAX_CONNECTIONS", "10")?
                .parse()
                .with_context(|| "DATABASE_MAX_CONNECTIONS must be a valid number")?,
                
            // 🔐 Supabase configuration
            supabase_url: get_env("SUPABASE_URL")?,
            supabase_anon_key: get_env("SUPABASE_ANON_KEY")?,
            supabase_service_role_key: get_env("SUPABASE_SERVICE_ROLE_KEY")?,
            
            // 🌐 Server configuration  
            server_host: env::var("SERVER_HOST").unwrap_or_else(|_| "127.0.0.1".to_string()),
            server_port: parse_env("SERVER_PORT", "8080")?
                .parse()
                .with_context(|| "SERVER_PORT must be a valid port number")?,
                
            // 🛡️ Security configuration
            jwt_secret: env::var("JWT_SECRET").unwrap_or_else(|_| {
                log::warn!("⚠️  JWT_SECRET not set, using default (NOT SECURE FOR PRODUCTION!)");
                "default_jwt_secret_change_me_in_production".to_string()
            }),
            allowed_origins: env::var("ALLOWED_ORIGINS")
                .unwrap_or_else(|_| "http://localhost:3000".to_string()),
            
            // ⏱️ Connection configuration
            websocket_timeout_seconds: parse_env("WEBSOCKET_TIMEOUT_SECONDS", "300")?
                .parse()
                .with_context(|| "WEBSOCKET_TIMEOUT_SECONDS must be a valid number")?,
                
            // 🚀 Performance configuration
            actix_workers: parse_env("ACTIX_WORKERS", "4")?
                .parse()
                .with_context(|| "ACTIX_WORKERS must be a valid number")?,
        })
    }
    
    // 🔍 VALIDATION METHOD
    // This method validates that our configuration makes sense
    // RUST BEST PRACTICE: Validate configuration early to catch errors
    pub fn validate(&self) -> Result<()> {
        // Check that URLs are valid
        if !self.supabase_url.starts_with("https://") {
            anyhow::bail!("SUPABASE_URL must start with https://");
        }
        
        if !self.database_url.starts_with("postgresql://") {
            anyhow::bail!("DATABASE_URL must be a PostgreSQL connection string");
        }
        
        // Check reasonable limits
        if self.server_port < 1024 {
            log::warn!("⚠️  Server port {} is below 1024, you might need root privileges", self.server_port);
        }
        
        if self.database_max_connections == 0 {
            anyhow::bail!("DATABASE_MAX_CONNECTIONS must be greater than 0");
        }
        
        if self.actix_workers == 0 {
            anyhow::bail!("ACTIX_WORKERS must be greater than 0");
        }
        
        Ok(())
    }
    
    // 📊 DISPLAY METHOD FOR DEBUGGING
    // This method safely displays configuration (without secrets)
    pub fn display_safe(&self) {
        log::info!("🔧 Configuration loaded:");
        log::info!("  📡 Server: {}:{}", self.server_host, self.server_port);
        log::info!("  🗄️  Database: {} (max connections: {})", 
                   self.database_url.split('@').last().unwrap_or("hidden"), 
                   self.database_max_connections);
        log::info!("  🔐 Supabase: {}", self.supabase_url);
        log::info!("  ⏱️  WebSocket timeout: {}s", self.websocket_timeout_seconds);
        log::info!("  🚀 Workers: {}", self.actix_workers);
        log::info!("  🛡️  CORS origins: {}", self.allowed_origins);
    }
} 