-- Migración legal: edad, consentimientos, exportación y borrado
-- Ejecutar como superusuario (postgres)

-- 1. Añadir campos legales a users
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS birth_date DATE,
    ADD COLUMN IF NOT EXISTS consent JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS accepted_terms_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS accepted_privacy_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS accepted_cookies_at TIMESTAMP;

-- 2. Tabla de log de consentimientos
CREATE TABLE IF NOT EXISTS consent_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    firebase_uid VARCHAR(255) NOT NULL,
    consent_type VARCHAR(50) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    accepted BOOLEAN NOT NULL,
    ip_address INET,
    user_agent VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de solicitudes GDPR
CREATE TABLE IF NOT EXISTS data_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    firebase_uid VARCHAR(255) NOT NULL,
    request_type VARCHAR(20) NOT NULL, -- 'export', 'deletion'
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'completed', 'rejected'
    payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- 4. Índices
CREATE INDEX IF NOT EXISTS idx_consent_logs_user_id ON consent_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_consent_logs_firebase_uid ON consent_logs(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_data_requests_user_id ON data_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_data_requests_firebase_uid ON data_requests(firebase_uid);

-- 5. Privilegios para app_user
GRANT SELECT, INSERT, UPDATE, DELETE ON consent_logs TO app_user;
GRANT USAGE, SELECT ON SEQUENCE consent_logs_id_seq TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON data_requests TO app_user;
GRANT USAGE, SELECT ON SEQUENCE data_requests_id_seq TO app_user;

ALTER TABLE consent_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY consent_logs_own_data ON consent_logs
    FOR ALL
    TO app_user
    USING (firebase_uid = current_setting('app.firebase_uid', true));

CREATE POLICY data_requests_own_data ON data_requests
    FOR ALL
    TO app_user
    USING (firebase_uid = current_setting('app.firebase_uid', true));
