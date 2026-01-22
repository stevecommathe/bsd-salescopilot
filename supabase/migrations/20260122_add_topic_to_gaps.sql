-- Add topic column for question categorization/deduplication
ALTER TABLE gaps ADD COLUMN IF NOT EXISTS topic TEXT;
CREATE INDEX IF NOT EXISTS idx_gaps_topic ON gaps(topic);
