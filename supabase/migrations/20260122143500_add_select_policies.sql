-- Add SELECT policies for anon role (for dashboard/debugging)
CREATE POLICY "Allow anon read usage_logs" ON usage_logs
    FOR SELECT TO anon
    USING (true);

CREATE POLICY "Allow anon read gaps" ON gaps
    FOR SELECT TO anon
    USING (true);
