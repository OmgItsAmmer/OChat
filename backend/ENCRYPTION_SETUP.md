# 🔐 OChat Encrypted Messaging Setup Guide

This guide will help you set up the complete encrypted messaging system for OChat.

## 📋 Prerequisites

1. **Supabase Account**: You need a Supabase project
2. **Rust Environment**: Rust 1.70+ with Cargo
3. **Environment Variables**: Configure your `.env` file

## 🗄️ Database Setup

### Step 1: Run the Database Schema

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the entire contents of `database_schema.sql`
4. Click **Run** to execute the schema

The schema will create:
- ✅ `users` table (extends Supabase auth)
- ✅ `messages` table (encrypted content)
- ✅ `encryption_keys` table (RSA key pairs)
- ✅ `conversation_sessions` table (AES session keys)
- ✅ `message_attachments` table (file attachments)
- ✅ Row Level Security (RLS) policies
- ✅ Performance indexes
- ✅ Database functions and views

### Step 2: Verify Schema Creation

After running the schema, you should see:
```
✅ OChat database schema created successfully!
📊 Tables created: users, messages, encryption_keys, conversation_sessions, message_attachments
🔐 Encryption support: AES-GCM for messages, RSA for key exchange
🛡️ Row Level Security (RLS) enabled on all tables
📈 Performance indexes created for optimal query performance
```

## 🔧 Environment Configuration

### Step 1: Create `.env` File

Create a `.env` file in your `backend` directory:

```env
# 🌐 SUPABASE CONFIGURATION
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# 🔐 ENCRYPTION CONFIGURATION
ENCRYPTION_ALGORITHM=RSA-2048
AES_KEY_SIZE=256
SESSION_KEY_EXPIRY_HOURS=24

# 🚀 SERVER CONFIGURATION
SERVER_HOST=127.0.0.1
SERVER_PORT=8080
RUST_LOG=info

# 🛡️ SECURITY
JWT_SECRET=your-jwt-secret-here
CORS_ORIGIN=http://localhost:3000
```

### Step 2: Get Supabase Keys

1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **API**
3. Copy the following values:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** → `SUPABASE_ANON_KEY`
   - **service_role secret** → `SUPABASE_SERVICE_ROLE_KEY`

## 🔐 Encryption Architecture

### Overview

OChat uses a **hybrid encryption system**:

1. **RSA-2048** for key exchange (asymmetric)
2. **AES-256-GCM** for message encryption (symmetric)
3. **SHA-256** for integrity verification

### Encryption Flow

```
User A sends message to User B:
1. Generate/retrieve AES session key for conversation
2. Encrypt message content with AES session key
3. Encrypt session key with User B's RSA public key
4. Store encrypted message + metadata in database
5. User B decrypts session key with their RSA private key
6. User B decrypts message with session key
```

### Security Features

- ✅ **End-to-End Encryption**: Only users can decrypt their messages
- ✅ **Perfect Forward Secrecy**: Session keys are rotated
- ✅ **Message Integrity**: SHA-256 hashes prevent tampering
- ✅ **Zero Trust**: No server access to plaintext messages
- ✅ **Row Level Security**: Database-level access control

## 🚀 Running the Application

### Step 1: Install Dependencies

```bash
cd backend
cargo build
```

### Step 2: Run the Server

```bash
cargo run
```

You should see:
```
🔌 Connecting to Supabase...
✅ Supabase connection established
🚀 Server running on http://127.0.0.1:8080
```

## 📱 API Endpoints

### Authentication
- `POST /auth/signup` - User registration
- `POST /auth/signin` - User login

### Messaging (Encrypted)
- `POST /messages/send` - Send encrypted message
- `GET /messages/conversation/{user_id}` - Get encrypted conversation
- `GET /messages/unread` - Get unread count

### Encryption Keys
- `POST /keys/generate` - Generate user encryption keys
- `GET /keys/public/{user_id}` - Get user's public key

### WebSocket (Real-time)
- `WS /ws` - Real-time encrypted messaging

## 🔍 Testing the Encryption

### Test Message Encryption

```bash
# Send an encrypted message
curl -X POST http://localhost:8080/messages/send \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "receiver_id": "user-uuid-here",
    "content": "Hello, encrypted world!",
    "message_type": "text"
  }'
```

### Verify Encryption

1. Check the database - message content should be encrypted
2. Only the intended recipient can decrypt it
3. Message integrity is verified with SHA-256

## 🛠️ Development Workflow

### Adding New Encryption Features

1. **Update Encryption Module** (`src/encryption.rs`)
2. **Update Database Schema** (`database_schema.sql`)
3. **Update API Wrapper** (`src/supabase_api.rs`)
4. **Update Messaging Service** (`src/encrypted_messaging.rs`)
5. **Test with Real Data**

### Debugging Encryption Issues

```bash
# Enable debug logging
RUST_LOG=debug cargo run

# Check encryption service logs
tail -f logs/encryption.log
```

## 🔒 Security Best Practices

### Key Management
- ✅ Store private keys encrypted with user passwords
- ✅ Rotate session keys regularly
- ✅ Use secure random number generation
- ✅ Implement key backup/recovery

### Message Security
- ✅ Verify message integrity with hashes
- ✅ Use authenticated encryption (AES-GCM)
- ✅ Implement message expiration
- ✅ Rate limit message sending

### Database Security
- ✅ Enable Row Level Security (RLS)
- ✅ Use parameterized queries
- ✅ Encrypt sensitive metadata
- ✅ Regular security audits

## 🚨 Common Issues

### Issue 1: "No public key found for user"
**Solution**: Generate encryption keys for the user first:
```bash
curl -X POST http://localhost:8080/keys/generate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Issue 2: "Failed to decrypt message"
**Solution**: Check session key management and key rotation

### Issue 3: "Database connection failed"
**Solution**: Verify Supabase URL and API keys in `.env`

### Issue 4: "RLS policy violation"
**Solution**: Ensure user is authenticated and has proper permissions

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Rust Cryptography](https://docs.rs/aes-gcm/latest/aes_gcm/)
- [End-to-End Encryption Guide](https://signal.org/docs/)
- [Zero Trust Architecture](https://www.nist.gov/publications/zero-trust-architecture)

## 🤝 Contributing

When contributing to the encryption system:

1. **Security Review**: All encryption code must be reviewed
2. **Testing**: Include comprehensive encryption tests
3. **Documentation**: Update this guide for new features
4. **Audit Trail**: Log all encryption operations

## 📞 Support

For encryption-related issues:
1. Check the logs for detailed error messages
2. Verify your Supabase configuration
3. Test with the provided examples
4. Open an issue with detailed reproduction steps

---

**🔐 Remember**: This is a production-ready encryption system. Always test thoroughly before deploying to production! 