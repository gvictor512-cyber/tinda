-- Admin views for RoomMate Match
-- Add these tables to the main schema.sql

-- Payments Table
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    amount INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    status VARCHAR(50) CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded')),
    provider VARCHAR(50) DEFAULT 'stripe',
    provider_payment_id VARCHAR(255),
    plan_type VARCHAR(50) CHECK (plan_type IN ('free', 'premium_monthly', 'premium_yearly')),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at DESC)
);

-- User Cancellations Table
CREATE TABLE user_cancellations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    cancellation_type VARCHAR(50) CHECK (cancellation_type IN ('account_deletion', 'subscription_cancel', 'manual_deactivation')),
    reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_cancellation_type (cancellation_type),
    INDEX idx_created_at (created_at DESC)
);

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_cancellations_updated_at BEFORE UPDATE ON user_cancellations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
