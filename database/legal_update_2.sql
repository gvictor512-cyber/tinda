-- Continuación de migración legal: permisos restantes y RLS

GRANT SELECT, INSERT, UPDATE, DELETE ON data_requests TO app_user;

ALTER TABLE consent_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS consent_logs_own_data ON consent_logs;
CREATE POLICY consent_logs_own_data ON consent_logs
    FOR ALL
    TO app_user
    USING (firebase_uid = current_setting('app.firebase_uid', true));

DROP POLICY IF EXISTS data_requests_own_data ON data_requests;
CREATE POLICY data_requests_own_data ON data_requests
    FOR ALL
    TO app_user
    USING (firebase_uid = current_setting('app.firebase_uid', true));
