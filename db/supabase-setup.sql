-- BSD Sales Copilot - Supabase Setup
-- Run this in Supabase SQL Editor to create required tables

-- Usage logs table
-- Tracks every trigger usage for analytics
CREATE TABLE IF NOT EXISTS usage_logs (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    trigger TEXT NOT NULL,
    user_id TEXT,
    os TEXT,
    question TEXT,
    response TEXT,
    confidence TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for common queries
CREATE INDEX IF NOT EXISTS idx_usage_logs_timestamp ON usage_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_usage_logs_trigger ON usage_logs(trigger);
CREATE INDEX IF NOT EXISTS idx_usage_logs_user ON usage_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_confidence ON usage_logs(confidence);

-- Gaps table
-- Tracks questions with low/medium confidence for knowledge base improvement
CREATE TABLE IF NOT EXISTS gaps (
    id BIGSERIAL PRIMARY KEY,
    question TEXT NOT NULL,
    confidence TEXT NOT NULL,
    status TEXT DEFAULT 'new',  -- new, reviewed, added, dismissed
    frequency INT DEFAULT 1,
    notes TEXT,
    first_seen TIMESTAMPTZ DEFAULT NOW(),
    last_seen TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for gaps queries
CREATE INDEX IF NOT EXISTS idx_gaps_status ON gaps(status);
CREATE INDEX IF NOT EXISTS idx_gaps_confidence ON gaps(confidence);
CREATE INDEX IF NOT EXISTS idx_gaps_frequency ON gaps(frequency DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE gaps ENABLE ROW LEVEL SECURITY;

-- Allow anonymous inserts (for logging from scripts)
-- This is safe because we're only allowing INSERT, not SELECT/UPDATE/DELETE
CREATE POLICY "Allow anonymous inserts to usage_logs"
ON usage_logs FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "Allow anonymous inserts to gaps"
ON gaps FOR INSERT
TO anon
WITH CHECK (true);

-- For the dashboard (authenticated users can read)
-- You may want to add more restrictive policies based on your auth setup
CREATE POLICY "Allow authenticated reads on usage_logs"
ON usage_logs FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated reads on gaps"
ON gaps FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated updates on gaps"
ON gaps FOR UPDATE
TO authenticated
USING (true);

-- Function to update gap frequency on duplicate questions
-- (Optional: call this from a trigger or manually)
CREATE OR REPLACE FUNCTION update_gap_frequency()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if similar question exists
    UPDATE gaps
    SET frequency = frequency + 1,
        last_seen = NOW()
    WHERE question = NEW.question
    AND status != 'added';

    -- If no update happened, this is a new gap
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    -- Duplicate found and updated, don't insert new row
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for gap deduplication
DROP TRIGGER IF EXISTS gaps_dedup_trigger ON gaps;
CREATE TRIGGER gaps_dedup_trigger
    BEFORE INSERT ON gaps
    FOR EACH ROW
    EXECUTE FUNCTION update_gap_frequency();

-- View for weekly analytics
CREATE OR REPLACE VIEW weekly_usage AS
SELECT
    DATE_TRUNC('week', timestamp) as week,
    trigger,
    confidence,
    COUNT(*) as count
FROM usage_logs
WHERE timestamp > NOW() - INTERVAL '8 weeks'
GROUP BY DATE_TRUNC('week', timestamp), trigger, confidence
ORDER BY week DESC, count DESC;

-- View for top gaps (unanswered questions)
CREATE OR REPLACE VIEW top_gaps AS
SELECT
    id,
    question,
    confidence,
    status,
    frequency,
    notes,
    first_seen,
    last_seen
FROM gaps
WHERE status IN ('new', 'reviewed')
ORDER BY frequency DESC, last_seen DESC
LIMIT 50;
