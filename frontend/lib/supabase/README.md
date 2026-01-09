# 🔐 Supabase Direct Integration

This directory contains all files related to the direct Supabase integration for OChat.

## Files Structure

```
lib/supabase/
├── functions/
│   └── rpc_functions.sql       # Server-side RPC functions
├── info/
│   └── table_schema.md         # Database schema documentation
└── README.md                   # This file
```

## 🚀 Quick Setup

### 1. Deploy RPC Functions
```sql
-- Copy contents of functions/rpc_functions.sql
-- Paste in Supabase Dashboard → SQL Editor
-- Execute to create all functions and policies
```

### 2. Verify Tables
Ensure your database has these tables:
- `users` - User profiles and status
- `messages` - Encrypted messages
- `conversation_sessions` - Chat sessions between users
- `encryption_keys` - User encryption keys
- `message_attachments` - File attachments (optional)

### 3. Test RPC Functions
```sql
-- Test user encryption setup
SELECT initialize_user_encryption();

-- Test conversation creation
SELECT create_or_get_conversation('other-user-uuid');

-- Test message sending
SELECT send_encrypted_message(
  'conversation-uuid',
  'Hello World!',
  'text'
);
```

## 🔑 Authentication Flow

1. **User Login**: Supabase handles JWT tokens automatically
2. **Permission Check**: RLS policies verify user access
3. **Function Call**: RPC functions authenticate via `auth.uid()`
4. **Data Access**: Encrypted operations performed server-side

## 🛡️ Security Features

### Row Level Security (RLS)
- Users can only access their own data
- Messages filtered by conversation participation
- Automatic JWT verification on all operations

### Server-Side Encryption
- Message content encrypted before database storage
- Encryption keys managed server-side
- No sensitive operations exposed to client

### Access Control
- All functions verify user authentication
- Conversation access validated per operation
- Failed requests logged for security monitoring

## 📡 Real-time Features

### Message Subscriptions
```dart
final channel = SupabaseService.subscribeToMessages(
  conversationId,
  (message) => _handleNewMessage(message),
);
```

### User Status Updates
```dart
final statusChannel = SupabaseService.subscribeToUserStatus(
  (user) => _updateUserStatus(user),
);
```

## 🔧 Available RPC Functions

| Function | Purpose | Parameters |
|----------|---------|------------|
| `initialize_user_encryption()` | Setup user encryption keys | None |
| `create_or_get_conversation(uuid)` | Create/retrieve conversation | `other_user_id` |
| `send_encrypted_message(...)` | Send encrypted message | `conversation_id`, `content`, `type` |
| `get_conversation_messages(...)` | Get decrypted messages | `conversation_id`, `limit`, `offset` |
| `mark_messages_as_read(uuid)` | Mark messages as read | `conversation_id` |
| `update_user_status(boolean)` | Update online status | `is_online` |

## 🚀 Performance Optimizations

### Caching Strategy
- Local storage for offline access
- Conversation list cached after fetch
- Message history stored per conversation

### Real-time Efficiency
- Subscribe only to active conversations
- Unsubscribe when leaving chat screens
- Batch status updates to reduce bandwidth

### Database Optimization
- Indexed queries for fast message retrieval
- Efficient RLS policies for security
- Paginated message loading

## 🐛 Debugging

### Enable Debug Logs
```dart
if (kDebugMode) {
  print('🔐 Calling Supabase RPC function: $functionName');
  print('📊 Parameters: $parameters');
}
```

### Common Debug Queries
```sql
-- Check user authentication
SELECT auth.uid();

-- Verify conversation access
SELECT * FROM conversation_sessions 
WHERE user1_id = auth.uid() OR user2_id = auth.uid();

-- Check message count
SELECT COUNT(*) FROM messages 
WHERE sender_id = auth.uid() OR receiver_id = auth.uid();
```

### Error Handling
```dart
try {
  final result = await SupabaseService.sendMessage(...);
} catch (e) {
  if (e.toString().contains('User not authenticated')) {
    // Handle auth error
  } else if (e.toString().contains('Access denied')) {
    // Handle permission error
  }
}
```

## 📈 Monitoring

### Key Metrics to Track
- Message send/receive success rates
- Authentication failure rates
- Real-time connection stability
- Function execution times

### Supabase Dashboard
Monitor in Supabase Dashboard:
- **Auth**: User session management
- **Database**: Query performance
- **Realtime**: Connection statistics
- **Functions**: Execution logs

## 🔄 Migration Support

If migrating from Rust server:
1. RPC functions replace Rust endpoints
2. SupabaseService replaces HTTP client
3. Real-time subscriptions replace WebSocket
4. RLS policies replace Rust authorization

## 🎯 Best Practices

### Security
- Never store encryption keys client-side
- Always validate user permissions server-side
- Use RLS policies for additional protection
- Rotate encryption keys periodically

### Performance  
- Batch operations when possible
- Use pagination for large datasets
- Cache frequently accessed data
- Minimize real-time subscriptions

### Error Handling
- Graceful degradation for offline scenarios
- Clear error messages for users
- Comprehensive logging for debugging
- Retry logic for network failures

---

For detailed migration instructions, see `SUPABASE_MIGRATION.md` in the project root.