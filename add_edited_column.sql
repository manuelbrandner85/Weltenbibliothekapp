-- Add 'edited' column to chat_messages table if it doesn't exist
-- This allows tracking edited messages

-- For Cloudflare D1, run this migration:
ALTER TABLE chat_messages ADD COLUMN edited INTEGER DEFAULT 0;

-- Test query to verify:
-- SELECT id, message, edited FROM chat_messages LIMIT 5;
