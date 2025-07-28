# 🚀 OChat Backend

A secure real-time messaging backend built with Rust, featuring WebSocket connections, JWT authentication, and PostgreSQL storage.

## 🏗️ Architecture Overview

- **Framework**: Actix-web for HTTP server and WebSocket handling
- **Authentication**: Supabase JWT token verification
- **Database**: PostgreSQL with SQLx for async queries
- **Real-time**: WebSocket connections managed by Actor model
- **Security**: CORS protection and JWT validation

## 📦 Features (Week 1)

✅ **Authentication**
- Supabase JWT token verification
- User registration and management
- Secure WebSocket connections

✅ **Real-time Messaging**
- WebSocket-based message delivery
- Online/offline status tracking
- Typing indicators
- Message read receipts

✅ **Database Operations**
- Message persistence
- Conversation history
- User management
- Message search

✅ **REST API**
- Get conversation history
- Search messages
- Message statistics
- Conversation management

## 🛠️ Setup Instructions

### 1. Prerequisites

- **Rust** (latest stable version): https://rustup.rs/
- **PostgreSQL** (v12 or higher)
- **Supabase Project** (for authentication)

### 2. Environment Configuration

1. Copy the environment template:
```bash
cp .env.example .env
```

2. Fill in your configuration in `.env`:

```bash
# 🗄️ DATABASE CONFIGURATION
DATABASE_URL=postgresql://username:password@localhost:5432/ochat_db

# 🔐 SUPABASE CONFIGURATION
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key_here

# 🌐 SERVER CONFIGURATION
SERVER_HOST=127.0.0.1
SERVER_PORT=8080

# 📝 LOGGING CONFIGURATION
RUST_LOG=debug

# 🛡️ SECURITY CONFIGURATION
JWT_SECRET=your_super_secret_jwt_key_here
ALLOWED_ORIGINS=http://localhost:3000
```

### 3. Database Setup

1. Create PostgreSQL database:
```sql
CREATE DATABASE ochat_db;
```

2. The backend will automatically run migrations on startup.

### 4. Supabase Setup

1. Create a new Supabase project at https://supabase.com
2. Go to Settings > API to get your URL and keys
3. Enable Row Level Security (RLS) on auth.users table
4. Copy the values to your `.env` file

### 5. Build and Run

```bash
# Install dependencies and build
cargo build

# Run the development server
cargo run

# Or run with automatic reloading (install cargo-watch first)
cargo install cargo-watch
cargo watch -x run
```

The server will start on `http://127.0.0.1:8080`

## 🛤️ API Endpoints

### Authentication
All WebSocket and message endpoints require a valid Supabase JWT token.

### WebSocket Connection
- **URL**: `ws://localhost:8080/api/v1/ws`
- **Auth**: JWT token in `Authorization` header or `?token=<jwt>` query parameter

### REST Endpoints

#### Health Check
```http
GET /api/v1/health
```

#### Get Conversation History
```http
GET /api/v1/messages/conversation?with_user=<uuid>&limit=50
Authorization: Bearer <jwt_token>
```

#### Get All Conversations
```http
GET /api/v1/messages/conversations
Authorization: Bearer <jwt_token>
```

#### Search Messages
```http
GET /api/v1/messages/search?query=hello&limit=20
Authorization: Bearer <jwt_token>
```

#### Get Message Statistics
```http
GET /api/v1/messages/stats
Authorization: Bearer <jwt_token>
```

#### Mark Messages as Read
```http
POST /api/v1/messages/mark-read
Content-Type: application/json
Authorization: Bearer <jwt_token>

{
  "message_ids": ["uuid1", "uuid2"]
}
```

## 📨 WebSocket Message Format

### Sending Messages (Client → Server)

#### Send Message
```json
{
  "type": "message",
  "to": "recipient-user-uuid",
  "content": "Hello, world!"
}
```

#### Ping (Keep-alive)
```json
{
  "type": "ping"
}
```

#### Mark Message as Read
```json
{
  "type": "mark_read",
  "message_id": "message-uuid"
}
```

#### Typing Indicator
```json
{
  "type": "typing",
  "to": "recipient-user-uuid",
  "is_typing": true
}
```

### Receiving Messages (Server → Client)

#### New Message
```json
{
  "type": "message",
  "id": "message-uuid",
  "from": "sender-user-uuid",
  "content": "Hello, world!",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### Pong Response
```json
{
  "type": "pong"
}
```

#### Error
```json
{
  "type": "error",
  "message": "Error description"
}
```

#### User Online/Offline
```json
{
  "type": "user_online",
  "user_id": "user-uuid"
}
```

#### Typing Indicator
```json
{
  "type": "typing",
  "from": "sender-user-uuid",
  "is_typing": true
}
```

#### Read Receipt
```json
{
  "type": "read_receipt",
  "message_id": "message-uuid",
  "read_by": "user-uuid"
}
```

## 🗄️ Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR NOT NULL UNIQUE,
    username VARCHAR,
    avatar_url VARCHAR,
    is_online BOOLEAN NOT NULL DEFAULT false,
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Messages Table
```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type message_type NOT NULL DEFAULT 'text',
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

## 🔧 Development

### Code Structure
```
src/
├── main.rs           # Server entry point and configuration
├── config.rs         # Environment configuration management
├── database.rs       # Database models and operations
├── auth.rs           # JWT authentication and verification
├── websocket.rs      # WebSocket handling and session management
├── messages.rs       # Message API endpoints and operations
└── errors.rs         # Custom error types and handling
```

### Best Practices Implemented
- **Error Handling**: Comprehensive error types with proper HTTP status codes
- **Security**: JWT verification, input validation, CORS protection
- **Performance**: Connection pooling, async operations, efficient queries
- **Logging**: Structured logging with different levels
- **Documentation**: Extensive comments explaining Rust concepts
- **Type Safety**: Strong typing with custom data structures

### Running Tests
```bash
# Run all tests
cargo test

# Run tests with output
cargo test -- --nocapture

# Run specific test
cargo test test_name
```

### Code Quality Tools
```bash
# Format code
cargo fmt

# Lint code
cargo clippy

# Security audit
cargo audit
```

## 🚀 Production Deployment

1. Set `RUST_LOG=info` for production
2. Use a strong `JWT_SECRET`
3. Configure proper CORS origins
4. Use connection pooling for database
5. Set up proper monitoring and logging
6. Use HTTPS in production

## 🤝 Contributing

1. Follow Rust coding conventions
2. Add extensive comments for complex logic
3. Write tests for new features
4. Update documentation
5. Use meaningful commit messages

## 📄 License

This project is licensed under the MIT License.

---

## 🆘 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL is running
   - Verify DATABASE_URL format
   - Ensure database exists

2. **JWT Verification Failed**
   - Check Supabase URL and keys
   - Verify token format
   - Ensure Supabase project is active

3. **WebSocket Connection Failed**
   - Check JWT token in Authorization header
   - Verify token is not expired
   - Check server logs for details

4. **Build Errors**
   - Update Rust to latest stable version
   - Run `cargo clean` and rebuild
   - Check dependency versions

### Getting Help

- Check server logs (set `RUST_LOG=debug`)
- Verify environment variables
- Test with health check endpoint first
- Use WebSocket testing tools for debugging 