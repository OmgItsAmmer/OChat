# 🚀 Quick Setup: Deploy RPC Functions to Supabase

## The Issue
Your `sendMessage` function is failing because the Supabase RPC functions haven't been deployed yet. Here's how to fix it:

## Step 1: Deploy RPC Functions

1. **Go to Supabase Dashboard**
   - Open your Supabase project dashboard
   - Navigate to **SQL Editor**

2. **Copy the RPC Functions**
   - Open `lib/supabase/functions/rpc_functions.sql` in your project
   - Copy the entire contents

3. **Paste and Execute**
   - Paste the SQL into the Supabase SQL Editor
   - Click **Run** to execute the script

## Step 2: Verify Deployment

After running the script, you should see:
- ✅ Functions created successfully
- ✅ RLS policies enabled
- ✅ Views created

## Step 3: Test the Functions

The app will now automatically test the RPC functions when it starts. Look for these debug messages:

```
🔍 Testing RPC function availability...
✅ RPC functions are available
```

If you see errors like:
```
❌ RPC functions test failed: function "send_encrypted_message" does not exist
```

Then the functions weren't deployed correctly.

### Test Message Functions

After deployment, you can test the message functions manually:

```sql
-- Test user encryption setup
SELECT initialize_user_encryption();

-- Test conversation creation (replace with actual user IDs)
SELECT create_or_get_conversation('other-user-uuid');

-- Test message sending
SELECT send_encrypted_message(
  'conversation-uuid',
  'Hello World!',
  'text'
);

-- Test message retrieval
SELECT get_conversation_messages('conversation-uuid', 10, 0);
```

**Note**: This demo uses simplified storage (no encryption) for easier testing. In production, implement proper encryption.

## Step 4: Test Message Sending

Once RPC functions are deployed, try sending a message again. You should see:

```
📤 Sending encrypted message via Supabase RPC
🔍 Debug: About to call SupabaseService.sendMessage
✅ Message sent and encrypted successfully
```

## Troubleshooting

### If RPC functions fail to deploy:
1. Check that you're in the correct Supabase project
2. Ensure you have admin permissions
3. Try running the SQL in smaller chunks

### If authentication fails:
1. Make sure user is logged in
2. Check Supabase auth settings
3. Verify JWT tokens are valid

### If conversation doesn't exist:
1. Create a conversation first using `create_or_get_conversation`
2. Check that the conversation ID is valid
3. Verify user has access to the conversation

## Quick Test

After deployment, you can test manually in Supabase SQL Editor:

```sql
-- Test user encryption setup
SELECT initialize_user_encryption();

-- Test conversation creation (replace with actual user IDs)
SELECT create_or_get_conversation('other-user-uuid');

-- Test message sending (replace with actual conversation ID)
SELECT send_encrypted_message(
  'conversation-uuid',
  'Hello World!',
  'text'
);
```

## Success Indicators

✅ **RPC functions deployed**: No SQL errors when running the script
✅ **Authentication working**: User can log in and get JWT token  
✅ **Message sending works**: No "function does not exist" errors
✅ **Real-time ready**: Messages appear instantly in chat

---

**Next**: Once RPC functions are deployed, your `sendMessage` function should work perfectly! 🎉 