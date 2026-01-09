-- 🗄️ OCHAT DATABASE SCHEMA
-- Complete database schema for encrypted chat application
-- Run this in your Supabase SQL editor

-- 🔐 ENCRYPTION SETUP
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 👤 USERS TABLE
-- Extends Supabase auth.users with additional profile information
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR NOT NULL UNIQUE,
    username VARCHAR,
    avatar_url VARCHAR,
    is_online BOOLEAN NOT NULL DEFAULT false,
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 📝 MESSAGE TYPE ENUM
CREATE TYPE public.message_type AS ENUM (
    'text',
    'image', 
    'file',
    'system'
);

-- 💬 MESSAGES TABLE (ENCRYPTED)
-- Stores encrypted messages with all necessary metadata
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- 🔐 ENCRYPTED CONTENT FIELDS
    encrypted_content TEXT NOT NULL, -- AES-GCM encrypted message content (base64)
    content_hash VARCHAR(64) NOT NULL, -- SHA-256 hash for integrity verification
    encryption_version INTEGER NOT NULL DEFAULT 1, -- Version for future encryption upgrades
    nonce VARCHAR(24) NOT NULL, -- AES nonce (base64)
    session_key_id UUID NOT NULL, -- ID of the session key used
    
    -- 📝 MESSAGE METADATA
    message_type public.message_type NOT NULL DEFAULT 'text',
    is_read BOOLEAN NOT NULL DEFAULT false,
    file_url VARCHAR, -- For file/image messages
    file_size BIGINT, -- File size in bytes
    mime_type VARCHAR, -- MIME type for files
    
    -- ⏰ TIMESTAMPS
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for messages
CREATE POLICY "Users can view messages they sent or received" ON public.messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

CREATE POLICY "Users can insert messages they send" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they received" ON public.messages
    FOR UPDATE USING (auth.uid() = receiver_id);

-- Indexes for better performance
CREATE INDEX idx_messages_participants ON public.messages(sender_id, receiver_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX idx_messages_unread ON public.messages(receiver_id, is_read) WHERE is_read = false;
CREATE INDEX idx_messages_session_key ON public.messages(session_key_id);

-- 🔐 ENCRYPTION KEYS TABLE
-- Stores encryption keys for users
CREATE TABLE public.encryption_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- 🔑 KEY DATA
    encrypted_private_key TEXT NOT NULL, -- User's encrypted private key
    public_key TEXT NOT NULL, -- User's public key (PEM format)
    key_version INTEGER NOT NULL DEFAULT 1,
    
    -- 🔧 KEY METADATA
    algorithm VARCHAR(50) NOT NULL DEFAULT 'RSA-2048',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ, -- Optional key expiration
    
    UNIQUE(user_id, key_version)
);

-- Enable Row Level Security
ALTER TABLE public.encryption_keys ENABLE ROW LEVEL SECURITY;

-- RLS Policies for encryption keys
CREATE POLICY "Users can only access their own encryption keys" ON public.encryption_keys
    FOR ALL USING (auth.uid() = user_id);

-- 🔑 CONVERSATION SESSIONS TABLE
-- Stores session keys for conversations
CREATE TABLE public.conversation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- 🔐 SESSION ENCRYPTION
    encrypted_session_key TEXT NOT NULL, -- Encrypted session key
    session_key_hash VARCHAR(64) NOT NULL, -- Hash of session key for verification
    
    -- 📊 SESSION METADATA
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure unique conversations
    UNIQUE(user1_id, user2_id),
    UNIQUE(user2_id, user1_id)
);

-- Enable Row Level Security
ALTER TABLE public.conversation_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for conversation sessions
CREATE POLICY "Users can access their conversation sessions" ON public.conversation_sessions
    FOR ALL USING (
        auth.uid() = user1_id OR auth.uid() = user2_id
    );

-- 📎 MESSAGE ATTACHMENTS TABLE
-- Stores file attachments for messages
CREATE TABLE public.message_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    
    -- 📁 FILE INFORMATION
    file_name VARCHAR NOT NULL,
    file_url VARCHAR NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR NOT NULL,
    
    -- 🔐 ENCRYPTION
    encrypted_file_key TEXT, -- Encrypted file encryption key
    file_hash VARCHAR(64) NOT NULL, -- File integrity hash
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.message_attachments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for attachments
CREATE POLICY "Users can access attachments of their messages" ON public.message_attachments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.messages m 
            WHERE m.id = message_attachments.message_id 
            AND (m.sender_id = auth.uid() OR m.receiver_id = auth.uid())
        )
    );

-- 🔧 DATABASE FUNCTIONS

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON public.messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to get conversation between two users
CREATE OR REPLACE FUNCTION get_conversation_messages(
    p_user1_id UUID,
    p_user2_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    sender_id UUID,
    receiver_id UUID,
    encrypted_content TEXT,
    content_hash VARCHAR,
    encryption_version INTEGER,
    nonce VARCHAR,
    session_key_id UUID,
    message_type public.message_type,
    is_read BOOLEAN,
    file_url VARCHAR,
    file_size BIGINT,
    mime_type VARCHAR,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.sender_id,
        m.receiver_id,
        m.encrypted_content,
        m.content_hash,
        m.encryption_version,
        m.nonce,
        m.session_key_id,
        m.message_type,
        m.is_read,
        m.file_url,
        m.file_size,
        m.mime_type,
        m.created_at,
        m.updated_at
    FROM public.messages m
    WHERE (m.sender_id = p_user1_id AND m.receiver_id = p_user2_id)
       OR (m.sender_id = p_user2_id AND m.receiver_id = p_user1_id)
    ORDER BY m.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create conversation ID (deterministic)
CREATE OR REPLACE FUNCTION create_conversation_id(user1_id UUID, user2_id UUID)
RETURNS UUID AS $$
DECLARE
    smaller_id UUID;
    larger_id UUID;
    hash_input TEXT;
    hash_result BYTEA;
BEGIN
    -- Sort the UUIDs to ensure consistent conversation ID
    IF user1_id < user2_id THEN
        smaller_id := user1_id;
        larger_id := user2_id;
    ELSE
        smaller_id := user2_id;
        larger_id := user1_id;
    END IF;
    
    -- Create hash input
    hash_input := smaller_id::text || larger_id::text;
    
    -- Generate hash
    hash_result := digest(hash_input, 'sha256');
    
    -- Use first 16 bytes as UUID
    RETURN encode(hash_result, 'hex')::uuid;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get unread message count
CREATE OR REPLACE FUNCTION get_unread_count(p_user_id UUID)
RETURNS BIGINT AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM public.messages
        WHERE receiver_id = p_user_id AND is_read = false
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 🔍 SAMPLE DATA (OPTIONAL)
-- Uncomment the following lines to insert sample data for testing

/*
-- Insert sample users (replace with actual user IDs from your auth.users table)
INSERT INTO public.users (id, email, username, is_online) VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'alice@example.com', 'Alice', true),
    ('550e8400-e29b-41d4-a716-446655440001', 'bob@example.com', 'Bob', false);

-- Insert sample encryption keys (replace with actual encrypted keys)
INSERT INTO public.encryption_keys (user_id, encrypted_private_key, public_key, algorithm) VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'encrypted_private_key_1', 'public_key_1', 'RSA-2048'),
    ('550e8400-e29b-41d4-a716-446655440001', 'encrypted_private_key_2', 'public_key_2', 'RSA-2048');
*/

-- 📊 VIEWS FOR EASIER QUERYING

-- View for user conversations
CREATE VIEW user_conversations AS
SELECT DISTINCT
    CASE 
        WHEN m.sender_id = auth.uid() THEN m.receiver_id
        ELSE m.sender_id
    END as other_user_id,
    u.email as other_user_email,
    u.username as other_user_username,
    u.avatar_url as other_user_avatar,
    u.is_online as other_user_online,
    MAX(m.created_at) as last_message_at,
    COUNT(CASE WHEN m.receiver_id = auth.uid() AND m.is_read = false THEN 1 END) as unread_count
FROM public.messages m
JOIN public.users u ON (
    CASE 
        WHEN m.sender_id = auth.uid() THEN m.receiver_id
        ELSE m.sender_id
    END = u.id
)
WHERE m.sender_id = auth.uid() OR m.receiver_id = auth.uid()
GROUP BY other_user_id, u.email, u.username, u.avatar_url, u.is_online
ORDER BY last_message_at DESC;

-- Grant access to the view
GRANT SELECT ON user_conversations TO authenticated;

-- 🎯 FINAL SETUP

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create indexes for better performance
CREATE INDEX idx_encryption_keys_user_version ON public.encryption_keys(user_id, key_version);
CREATE INDEX idx_conversation_sessions_users ON public.conversation_sessions(user1_id, user2_id);
CREATE INDEX idx_conversation_sessions_active ON public.conversation_sessions(is_active) WHERE is_active = true;
CREATE INDEX idx_attachments_message ON public.message_attachments(message_id);

-- Log successful schema creation
DO $$
BEGIN
    RAISE NOTICE '✅ OChat database schema created successfully!';
    RAISE NOTICE '📊 Tables created: users, messages, encryption_keys, conversation_sessions, message_attachments';
    RAISE NOTICE '🔐 Encryption support: AES-GCM for messages, RSA for key exchange';
    RAISE NOTICE '🛡️ Row Level Security (RLS) enabled on all tables';
    RAISE NOTICE '📈 Performance indexes created for optimal query performance';
END $$; 