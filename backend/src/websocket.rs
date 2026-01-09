/*
📡 WEBSOCKET MODULE
==================

This module handles WebSocket connections for real-time messaging.

RUST CONCEPTS EXPLAINED:
- `Actor`: Actix uses the Actor model - each WebSocket connection is an actor
- `StreamHandler`: Handles incoming WebSocket messages
- `Addr`: Address to send messages to an actor
- `HashMap`: Key-value storage for tracking connected users
- `Arc<Mutex<>>`: Thread-safe shared data (like a synchronized map)

WEBSOCKET ARCHITECTURE:
1. Client connects with JWT token
2. We verify the token and create a WebSocket actor
3. Actor is stored in SessionManager with user_id as key
4. When messages arrive, we route them to the correct recipient
5. When connection closes, we clean up the actor
*/

use actix::{Actor, StreamHandler, Handler, Message as ActixMessage, Addr, AsyncContext, ActorContext};
use actix_web::{web, HttpRequest, HttpResponse, Error};
use actix_web_actors::ws;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use crate::auth::auth::{JwtValidator, extract_token_from_ws_request};
use crate::database::{NewMessage, User};
use crate::supabase_api::SupabaseClient;
// use sqlx::PgPool; // COMMENTED OUT - Using Supabase API instead

// 📨 WEBSOCKET MESSAGE TYPES
// These are the different types of messages we can send/receive over WebSocket

// 📥 INCOMING MESSAGE (from client to server)
#[derive(Debug, Deserialize)]
#[serde(tag = "type")]
pub enum IncomingMessage {
    // 💬 Send a chat message
    #[serde(rename = "message")]
    SendMessage {
        to: Uuid,           // Recipient user ID
        content: String,    // Message content
    },
    
    // 💓 Heartbeat to keep connection alive
    #[serde(rename = "ping")]
    Ping,
    
    // ✅ Mark message as read
    #[serde(rename = "mark_read")]
    MarkRead {
        message_id: Uuid,
    },
    
    // 👀 User is typing indicator
    #[serde(rename = "typing")]
    Typing {
        to: Uuid,
        is_typing: bool,
    },
}

// 📤 OUTGOING MESSAGE (from server to client)
#[derive(Debug, Serialize, Clone)]
#[serde(tag = "type")]
pub enum OutgoingMessage {
    // 💬 New message received
    #[serde(rename = "message")]
    NewMessage {
        id: Uuid,
        from: Uuid,
        content: String,
        timestamp: DateTime<Utc>,
    },
    
    // 💓 Pong response to ping
    #[serde(rename = "pong")]
    Pong,
    
    // ❌ Error occurred
    #[serde(rename = "error")]
    Error {
        message: String,
    },
    
    // 🟢 User came online
    #[serde(rename = "user_online")]
    UserOnline {
        user_id: Uuid,
    },
    
    // 🔴 User went offline
    #[serde(rename = "user_offline")]
    UserOffline {
        user_id: Uuid,
    },
    
    // 👀 User is typing
    #[serde(rename = "typing")]
    TypingIndicator {
        from: Uuid,
        is_typing: bool,
    },
    
    // ✅ Message marked as read
    #[serde(rename = "read_receipt")]
    ReadReceipt {
        message_id: Uuid,
        read_by: Uuid,
    },
}

// 🎭 WEBSOCKET ACTOR
// Each WebSocket connection is represented by this actor
// RUST PATTERN: Actors are isolated, message-passing entities
pub struct WebSocketActor {
    user_id: Uuid,                              // The authenticated user
    session_manager: Arc<Mutex<SessionManager>>, // Shared session manager
    supabase_client: SupabaseClient,            // Supabase API client (ZERO TRUST)
}

impl WebSocketActor {
    pub fn new(
        user_id: Uuid, 
        session_manager: Arc<Mutex<SessionManager>>, 
        supabase_client: SupabaseClient
    ) -> Self {
        Self {
            user_id,
            session_manager,
            supabase_client,
        }
    }
    
    // 📤 Send message to client
    fn send_message(&self, ctx: &mut ws::WebsocketContext<Self>, msg: OutgoingMessage) {
        match serde_json::to_string(&msg) {
            Ok(json) => ctx.text(json),
            Err(e) => {
                log::error!("Failed to serialize outgoing message: {}", e);
                ctx.text(r#"{"type":"error","message":"Internal server error"}"#);
            }
        }
    }
    
    // 💬 Handle incoming chat message
    async fn handle_send_message(&self, to: Uuid, content: String, ctx: &mut ws::WebsocketContext<Self>) {
        // Validate message content
        if content.trim().is_empty() {
            self.send_message(ctx, OutgoingMessage::Error {
                message: "Message content cannot be empty".to_string(),
            });
            return;
        }
        
        if content.len() > 4000 { // Reasonable message length limit
            self.send_message(ctx, OutgoingMessage::Error {
                message: "Message too long (max 4000 characters)".to_string(),
            });
            return;
        }
        
        // Create new message in database
        let new_message = NewMessage {
            receiver_id: to,
            content: content.clone(),
            message_type: None, // Default to text
            file_url: None,
            file_size: None,
            mime_type: None,
        };
        
        // 💾 Save message to database via Supabase API (ZERO TRUST)
        // 🚫 DIRECT DATABASE OPERATION (COMMENTED OUT)
        // match DbMessage::create(&self.db_pool, self.user_id, new_message).await {
        
        // 🔐 ZERO TRUST: Create message via Supabase API
        let access_token = "TODO: Extract from WebSocket context"; // TODO: Implement token extraction
        match self.supabase_client.create_message(&new_message, self.user_id, access_token).await {
            Ok(message) => {
                // Send to recipient if they're online
                if let Ok(session_manager) = self.session_manager.lock() {
                    if let Some(recipient_addr) = session_manager.get_user_session(&to) {
                        recipient_addr.do_send(SendToClient {
                            message: OutgoingMessage::NewMessage {
                                id: message.id,
                                from: self.user_id,
                                content: message.encrypted_content.clone(),
                                timestamp: message.created_at,
                            },
                        });
                    }
                }
                
                log::debug!("Message sent from {} to {}", self.user_id, to);
            }
            Err(e) => {
                log::error!("Failed to save message to database: {}", e);
                self.send_message(ctx, OutgoingMessage::Error {
                    message: "Failed to send message".to_string(),
                });
            }
        }
    }
    
    // ✅ Handle mark message as read (ZERO TRUST)
    async fn handle_mark_read(&self, message_id: Uuid, ctx: &mut ws::WebsocketContext<Self>) {
        // 🚫 DIRECT DATABASE OPERATION (COMMENTED OUT)
        // match DbMessage::mark_as_read(&self.db_pool, message_id, self.user_id).await {
        
        // 🔐 ZERO TRUST: Mark message as read via Supabase API
        let access_token = "TODO: Extract from WebSocket context"; // TODO: Implement token extraction
        match self.supabase_client.mark_message_read(message_id, self.user_id, access_token).await {
            Ok(_) => {
                // Find the sender and notify them
                // For simplicity in Week 1, we'll skip this notification
                log::debug!("Message {} marked as read by {}", message_id, self.user_id);
            }
            Err(e) => {
                log::error!("Failed to mark message as read: {}", e);
                self.send_message(ctx, OutgoingMessage::Error {
                    message: "Failed to mark message as read".to_string(),
                });
            }
        }
    }
    
    // 👀 Handle typing indicator
    fn handle_typing(&self, to: Uuid, is_typing: bool) {
        if let Ok(session_manager) = self.session_manager.lock() {
            if let Some(recipient_addr) = session_manager.get_user_session(&to) {
                recipient_addr.do_send(SendToClient {
                    message: OutgoingMessage::TypingIndicator {
                        from: self.user_id,
                        is_typing,
                    },
                });
            }
        }
    }
}

// 🎬 ACTOR IMPLEMENTATION
// This makes WebSocketActor an actual Actor that can receive messages
impl Actor for WebSocketActor {
    type Context = ws::WebsocketContext<Self>;
    
    // 🚀 Called when actor starts
    fn started(&mut self, ctx: &mut Self::Context) {
        log::info!("📡 WebSocket connection started for user {}", self.user_id);
        
        // Register this actor in the session manager
        if let Ok(mut session_manager) = self.session_manager.lock() {
            session_manager.add_session(self.user_id, ctx.address());
        }
        
        // 🔐 ZERO TRUST: Update user online status via Supabase API
        // 🚫 DIRECT DATABASE OPERATION (COMMENTED OUT)
        // let db_pool = self.db_pool.clone();
        // let user_id = self.user_id;
        // actix::spawn(async move {
        //     if let Err(e) = User::set_online_status(&db_pool, user_id, true).await {
        //         log::error!("Failed to set user online status: {}", e);
        //     }
        // });
        
        // 🔐 ZERO TRUST: Set user online status via Supabase API
        let supabase_client = self.supabase_client.clone();
        let user_id = self.user_id;
        
        actix::spawn(async move {
            let access_token = "TODO: Extract from WebSocket context"; // TODO: Implement token extraction
            if let Err(e) = supabase_client.update_user_status(user_id, true, access_token).await {
                log::error!("Failed to set user online status: {}", e);
            }
        });
    }
    
    // 🛑 Called when actor stops
    fn stopped(&mut self, _ctx: &mut Self::Context) {
        log::info!("📡 WebSocket connection stopped for user {}", self.user_id);
        
        // Remove this actor from the session manager
        if let Ok(mut session_manager) = self.session_manager.lock() {
            session_manager.remove_session(&self.user_id);
        }
        
        // 🔐 ZERO TRUST: Update user offline status via Supabase API
        // 🚫 DIRECT DATABASE OPERATION (COMMENTED OUT)
        // let db_pool = self.db_pool.clone();
        // let user_id = self.user_id;
        // actix::spawn(async move {
        //     if let Err(e) = User::set_online_status(&db_pool, user_id, false).await {
        //         log::error!("Failed to set user offline status: {}", e);
        //     }
        // });
        
        // 🔐 ZERO TRUST: Set user offline status via Supabase API
        let supabase_client = self.supabase_client.clone();
        let user_id = self.user_id;
        
        actix::spawn(async move {
            let access_token = "TODO: Extract from WebSocket context"; // TODO: Implement token extraction
            if let Err(e) = supabase_client.update_user_status(user_id, false, access_token).await {
                log::error!("Failed to set user offline status: {}", e);
            }
        });
    }
}

// 📥 WEBSOCKET MESSAGE HANDLER
// Handles incoming WebSocket text messages
impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for WebSocketActor {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        match msg {
            Ok(ws::Message::Text(text)) => {
                // Parse incoming JSON message
                match serde_json::from_str::<IncomingMessage>(&text) {
                    Ok(incoming_msg) => {
                        match incoming_msg {
                            IncomingMessage::SendMessage { to, content } => {
                                // 🔐 ZERO TRUST: Handle async operation via Supabase API
                                // 🚫 DIRECT DATABASE OPERATION (COMMENTED OUT)
                                // let db_pool = self.db_pool.clone();
                                // let user_id = self.user_id;
                                // let fut = async move {
                                //     let new_message = NewMessage {
                                //         receiver_id: to,
                                //         content: content.clone(),
                                //         message_type: None,
                                //     };
                                //     DbMessage::create(&db_pool, user_id, new_message).await
                                // };
                                
                                let supabase_client = self.supabase_client.clone();
                                let user_id = self.user_id;
                                
                                let fut = async move {
                                    let new_message = NewMessage {
                                        receiver_id: to,
                                        content: content.clone(),
                                        message_type: None,
                                        file_url: None,
                                        file_size: None,
                                        mime_type: None,
                                    };
                                    let access_token = "TODO: Extract from WebSocket context"; // TODO: Implement token extraction
                                    supabase_client.create_message(&new_message, user_id, access_token).await
                                };
                                
                                let session_manager = self.session_manager.clone();
                                actix::spawn(async move {
                                    match fut.await {
                                        Ok(message) => {
                                            if let Ok(sm) = session_manager.lock() {
                                                if let Some(addr) = sm.get_user_session(&to) {
                                                    addr.do_send(SendToClient {
                                                        message: OutgoingMessage::NewMessage {
                                                            id: message.id,
                                                            from: user_id,
                                                            content: message.encrypted_content.clone(),
                                                            timestamp: message.created_at,
                                                        },
                                                    });
                                                }
                                            }
                                        }
                                        Err(e) => log::error!("Failed to send message: {}", e),
                                    }
                                });
                            }
                            
                            IncomingMessage::Ping => {
                                self.send_message(ctx, OutgoingMessage::Pong);
                            }
                            
                            IncomingMessage::MarkRead { message_id } => {
                                // 🔐 ZERO TRUST: Mark message as read via Supabase API
                                // 🚫 DIRECT DATABASE OPERATION (COMMENTED OUT)
                                // let db_pool = self.db_pool.clone();
                                // let user_id = self.user_id;
                                // actix::spawn(async move {
                                //     if let Err(e) = DbMessage::mark_as_read(&db_pool, message_id, user_id).await {
                                //         log::error!("Failed to mark message as read: {}", e);
                                //     }
                                // });
                                
                                let supabase_client = self.supabase_client.clone();
                                let user_id = self.user_id;
                                
                                actix::spawn(async move {
                                    let access_token = "TODO: Extract from WebSocket context"; // TODO: Implement token extraction
                                    if let Err(e) = supabase_client.mark_message_read(message_id, user_id, access_token).await {
                                        log::error!("Failed to mark message as read: {}", e);
                                    }
                                });
                            }
                            
                            IncomingMessage::Typing { to, is_typing } => {
                                self.handle_typing(to, is_typing);
                            }
                        }
                    }
                    Err(e) => {
                        log::warn!("Invalid message format from user {}: {}", self.user_id, e);
                        self.send_message(ctx, OutgoingMessage::Error {
                            message: "Invalid message format".to_string(),
                        });
                    }
                }
            }
            
            Ok(ws::Message::Binary(_)) => {
                log::warn!("Binary messages not supported");
                self.send_message(ctx, OutgoingMessage::Error {
                    message: "Binary messages not supported".to_string(),
                });
            }
            
            Ok(ws::Message::Close(reason)) => {
                log::info!("WebSocket connection closed for user {}: {:?}", self.user_id, reason);
                ctx.stop();
            }
            
            Ok(ws::Message::Ping(bytes)) => {
                ctx.pong(&bytes);
            }
            
            Ok(ws::Message::Pong(_)) => {
                // Pong received, connection is alive
            }
            
            Ok(ws::Message::Continuation(_)) => {
                log::trace!("Received WebSocket continuation message");
            }

            Ok(ws::Message::Nop) => {
                log::trace!("Received WebSocket nop message");
            }
            
            Err(e) => {
                log::error!("WebSocket error for user {}: {}", self.user_id, e);
                ctx.stop();
            }
        }
    }
}

// 📬 MESSAGE TO SEND TO CLIENT
// This is an Actix message that we can send to WebSocket actors
#[derive(ActixMessage)]
#[rtype(result = "()")]
pub struct SendToClient {
    pub message: OutgoingMessage,
}

// 📬 HANDLER FOR SENDTOCLIENT
impl Handler<SendToClient> for WebSocketActor {
    type Result = ();
    
    fn handle(&mut self, msg: SendToClient, ctx: &mut Self::Context) {
        self.send_message(ctx, msg.message);
    }
}

// 🗂️ SESSION MANAGER
// Keeps track of all connected WebSocket sessions
// RUST PATTERN: Arc<Mutex<T>> for thread-safe shared state
#[derive(Debug, Clone)]
pub struct SessionManager {
    sessions: Arc<Mutex<HashMap<Uuid, Addr<WebSocketActor>>>>,
}

impl SessionManager {
    pub fn new() -> Self {
        Self {
            sessions: Arc::new(Mutex::new(HashMap::new())),
        }
    }
    
    // ➕ Add a new session
    pub fn add_session(&mut self, user_id: Uuid, addr: Addr<WebSocketActor>) {
        if let Ok(mut sessions) = self.sessions.lock() {
            sessions.insert(user_id, addr);
            log::debug!("Added session for user {}", user_id);
        }
    }
    
    // ➖ Remove a session
    pub fn remove_session(&mut self, user_id: &Uuid) {
        if let Ok(mut sessions) = self.sessions.lock() {
            if sessions.remove(user_id).is_some() {
                log::debug!("Removed session for user {}", user_id);
            }
        }
    }
    
    // 🔍 Get a session by user ID
    pub fn get_user_session(&self, user_id: &Uuid) -> Option<Addr<WebSocketActor>> {
        if let Ok(sessions) = self.sessions.lock() {
            sessions.get(user_id).cloned()
        } else {
            None
        }
    }
    
    // 📊 Get number of connected users
    pub fn connected_count(&self) -> usize {
        if let Ok(sessions) = self.sessions.lock() {
            sessions.len()
        } else {
            0
        }
    }
    
    // 📢 Broadcast message to all connected users
    pub fn broadcast(&self, message: OutgoingMessage) {
        if let Ok(sessions) = self.sessions.lock() {
            for (user_id, addr) in sessions.iter() {
                addr.do_send(SendToClient {
                    message: message.clone(),
                });
                log::debug!("Broadcasted message to user {}", user_id);
            }
        }
    }
}

// 🔌 WEBSOCKET HANDLER ENDPOINT
// This is the HTTP endpoint that upgrades connections to WebSocket
pub async fn websocket_handler(
    req: HttpRequest,
    stream: web::Payload,
    jwt_validator: web::Data<JwtValidator>,
    session_manager: web::Data<SessionManager>,
    supabase_client: web::Data<SupabaseClient>,
) -> Result<HttpResponse, Error> {
    log::info!("📡 New WebSocket connection attempt");
    
    // Extract and verify JWT token
    let token = extract_token_from_ws_request(&req)
        .map_err(|e| {
            log::warn!("WebSocket authentication failed: {}", e);
            actix_web::error::ErrorUnauthorized(e.to_string())
        })?;
    
    // 🛡️ ZERO TRUST: Extract request context for verification
    let ip_address = req.connection_info().peer_addr().map(|s| s.to_string());
    let user_agent = req.headers()
        .get("user-agent")
        .and_then(|h| h.to_str().ok())
        .map(|s| s.to_string());
    
    // Verify the token with Zero Trust context
    let claims = jwt_validator.verify_token(&token, ip_address, user_agent).await
        .map_err(|e| {
            log::warn!("WebSocket token verification failed: {}", e);
            actix_web::error::ErrorUnauthorized(e.to_string())
        })?;
    
    // Extract user ID
    let user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| {
            log::error!("Invalid user ID in JWT token");
            actix_web::error::ErrorBadRequest("Invalid user ID")
        })?;
    
    // 🔐 ZERO TRUST: Ensure user exists via Supabase API (create if first time)
    // 🚫 DIRECT DATABASE OPERATION (COMMENTED OUT)
    // User::upsert(&db_pool, user_id, &claims.email).await
    //     .map_err(|e| {
    //         log::error!("Failed to upsert user: {}", e);
    //         actix_web::error::ErrorInternalServerError("Database error")
    //     })?;
    
    // 🔐 ZERO TRUST: Upsert user via Supabase API
    let access_token = "TODO: Extract from request"; // TODO: Implement token extraction
    let user = User {
        id: user_id,
        email: claims.email.clone(),
        username: None,
        avatar_url: None,
        is_online: false,
        last_seen: Utc::now(),
        created_at: Utc::now(),
        updated_at: Utc::now(),
    };
    
    if let Err(e) = supabase_client.get_ref().upsert_user(&user, access_token).await {
        log::error!("Failed to upsert user: {}", e);
        return Err(actix_web::error::ErrorInternalServerError("Database error"));
    }
    
    log::info!("✅ WebSocket authentication successful for user {}", user_id);
    
    // Create WebSocket actor and start connection
    let actor = WebSocketActor::new(
        user_id,
        Arc::new(Mutex::new(session_manager.get_ref().clone())),
        supabase_client.get_ref().clone(),
    );
    
    ws::start(actor, &req, stream)
} 