| table_name            | column_name           | data_type                |
| --------------------- | --------------------- | ------------------------ |
| conversation_sessions | id                    | uuid                     |
| conversation_sessions | user1_id              | uuid                     |
| conversation_sessions | user2_id              | uuid                     |
| conversation_sessions | encrypted_session_key | text                     |
| conversation_sessions | session_key_hash      | character varying        |
| conversation_sessions | is_active             | boolean                  |
| conversation_sessions | created_at            | timestamp with time zone |
| conversation_sessions | last_used             | timestamp with time zone |

| encryption_keys       | id                    | uuid                     |
| encryption_keys       | user_id               | uuid                     |
| encryption_keys       | encrypted_private_key | text                     |
| encryption_keys       | public_key            | text                     |
| encryption_keys       | key_version           | integer                  |
| encryption_keys       | algorithm             | character varying        |
| encryption_keys       | created_at            | timestamp with time zone |
| encryption_keys       | expires_at            | timestamp with time zone |

| message_attachments   | id                    | uuid                     |
| message_attachments   | message_id            | uuid                     |
| message_attachments   | file_name             | character varying        |
| message_attachments   | file_url              | character varying        |
| message_attachments   | file_size             | bigint                   |
| message_attachments   | mime_type             | character varying        |
| message_attachments   | encrypted_file_key    | text                     |
| message_attachments   | file_hash             | character varying        |
| message_attachments   | created_at            | timestamp with time zone |

| messages              | id                    | uuid                     |
| messages              | sender_id             | uuid                     |
| messages              | receiver_id           | uuid                     |
| messages              | encrypted_content     | text                     |
| messages              | content_hash          | character varying        |
| messages              | encryption_version    | integer                  |
| messages              | nonce                 | character varying        |
| messages              | session_key_id        | uuid                     |
| messages              | message_type          | USER-DEFINED             |
| messages              | is_read               | boolean                  |
| messages              | file_url              | character varying        |
| messages              | file_size             | bigint                   |
| messages              | mime_type             | character varying        |
| messages              | created_at            | timestamp with time zone |
| messages              | updated_at            | timestamp with time zone |

| user_conversations    | other_user_id         | uuid                     |
| user_conversations    | other_user_email      | character varying        |
| user_conversations    | other_user_username   | character varying        |
| user_conversations    | other_user_avatar     | character varying        |
| user_conversations    | other_user_online     | boolean                  |
| user_conversations    | last_message_at       | timestamp with time zone |
| user_conversations    | unread_count          | bigint                   |

| users                 | id                    | uuid                     |
| users                 | email                 | character varying        |
| users                 | username              | character varying        |
| users                 | avatar_url            | character varying        |
| users                 | is_online             | boolean                  |
| users                 | last_seen             | timestamp with time zone |
| users                 | created_at            | timestamp with time zone |
| users                 | updated_at            | timestamp with time zone |