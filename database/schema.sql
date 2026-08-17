-- RoomMate Match Database Schema
-- PostgreSQL 15+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    is_premium BOOLEAN DEFAULT false,
    premium_expires_at TIMESTAMP,
    last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    device_token VARCHAR(500)
);

-- Profiles Table
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    age INTEGER CHECK (age >= 18 AND age <= 100),
    gender VARCHAR(20),
    profession VARCHAR(100),
    city VARCHAR(100),
    bio TEXT,
    profile_photo_url VARCHAR(500),
    photos JSONB DEFAULT '[]'::jsonb,
    budget_min INTEGER DEFAULT 300,
    budget_max INTEGER DEFAULT 1000,
    preferred_location VARCHAR(255),
    languages JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Compatibility Settings Table
CREATE TABLE compatibility_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    schedule_type VARCHAR(50) CHECK (schedule_type IN ('madrugador', 'nocturno', 'trabajo_remoto', 'turnos', 'estudiante')),
    cleanliness_level INTEGER CHECK (cleanliness_level >= 1 AND cleanliness_level <= 5),
    smoking_preference VARCHAR(50) CHECK (smoking_preference IN ('no_fuma', 'fuma_fuera', 'fuma_dentro')),
    pets_preference VARCHAR(50) CHECK (pets_preference IN ('me_encantan', 'tengo_mascotas', 'no_quiero_mascotas', 'soy_alergico')),
    personality_traits JSONB DEFAULT '[]'::jsonb,
    guests_frequency VARCHAR(50) CHECK (guests_frequency IN ('nunca', 'a_veces', 'frecuentemente')),
    cooking_frequency VARCHAR(50) CHECK (cooking_frequency IN ('nunca', 'ocasionalmente', 'todos_los_dias')),
    music_volume VARCHAR(50) CHECK (music_volume IN ('nunca', 'a_veces', 'mucho')),
    work_from_home BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Swipes Table
CREATE TABLE swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_id UUID REFERENCES users(id) ON DELETE CASCADE,
    swiped_id UUID REFERENCES users(id) ON DELETE CASCADE,
    swipe_type VARCHAR(20) CHECK (swipe_type IN ('like', 'dislike', 'super_like')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(swiper_id, swiped_id)
);

-- Matches Table
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES users(id) ON DELETE CASCADE,
    compatibility_score INTEGER CHECK (compatibility_score >= 0 AND compatibility_score <= 100),
    compatibility_explanation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user1_id, user2_id),
    CHECK (user1_id < user2_id)
);

-- Messages Table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES users(id) NOT NULL,
    message_type VARCHAR(20) CHECK (message_type IN ('text', 'image', 'location', 'emoji', 'housing_proposal')),
    content TEXT,
    media_url VARCHAR(500),
    location_data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Housing Listings Table
CREATE TABLE housing_listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255),
    source VARCHAR(50) CHECK (source IN ('idealista', 'fotocasa', 'manual')),
    title VARCHAR(255),
    description TEXT,
    price INTEGER,
    location VARCHAR(255),
    city VARCHAR(100),
    bedrooms INTEGER,
    bathrooms INTEGER,
    square_meters INTEGER,
    photos JSONB DEFAULT '[]'::jsonb,
    features JSONB DEFAULT '{}'::jsonb,
    url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Favorite Housing Table
CREATE TABLE favorite_housing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    housing_id UUID REFERENCES housing_listings(id) ON DELETE CASCADE,
    match_id UUID REFERENCES matches(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, housing_id)
);

-- Groups Table
CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100),
    description TEXT,
    creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
    max_members INTEGER DEFAULT 4,
    compatibility_score INTEGER CHECK (compatibility_score >= 0 AND compatibility_score <= 100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Group Members Table
CREATE TABLE group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) CHECK (role IN ('creator', 'admin', 'member')),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(group_id, user_id)
);

-- Subscriptions Table
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plan_type VARCHAR(50) CHECK (plan_type IN ('free', 'premium_monthly', 'premium_yearly')),
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    auto_renew BOOLEAN DEFAULT false,
    payment_method VARCHAR(50)
);

-- Verification Table
CREATE TABLE verification (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    email_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP,
    phone_verified BOOLEAN DEFAULT false,
    phone_verified_at TIMESTAMP,
    selfie_verified BOOLEAN DEFAULT false,
    selfie_verified_at TIMESTAMP,
    document_verified BOOLEAN DEFAULT false,
    document_verified_at TIMESTAMP,
    document_url VARCHAR(500),
    is_verified BOOLEAN DEFAULT false,
    verification_level VARCHAR(20) CHECK (verification_level IN ('basic', 'standard', 'advanced')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Badges Table
CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    badge_type VARCHAR(50) CHECK (badge_type IN ('profile_complete', 'verified', 'good_roommate', 'quick_responder', 'premium', 'top_matcher')),
    criteria JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Badges Table
CREATE TABLE user_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, badge_id)
);

-- User Filters Table
CREATE TABLE user_filters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    age_min INTEGER DEFAULT 18,
    age_max INTEGER DEFAULT 40,
    cities JSONB DEFAULT '[]'::jsonb,
    budget_min INTEGER DEFAULT 300,
    budget_max INTEGER DEFAULT 1000,
    smoking_preferences JSONB DEFAULT '[]'::jsonb,
    pets_preferences JSONB DEFAULT '[]'::jsonb,
    work_from_home BOOLEAN,
    gender VARCHAR(20),
    languages JSONB DEFAULT '[]'::jsonb,
    user_types JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Daily Limits Table
CREATE TABLE daily_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE,
    likes_used INTEGER DEFAULT 0,
    super_likes_used INTEGER DEFAULT 0,
    boosts_used INTEGER DEFAULT 0,
    UNIQUE(user_id, date)
);

-- Reports Table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reported_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reason VARCHAR(100),
    description TEXT,
    status VARCHAR(20) CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- Blocks Table
CREATE TABLE blocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reason VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(blocker_id, blocked_id)
);

-- Notifications Table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) CHECK (notification_type IN ('new_match', 'new_message', 'new_housing', 'new_compatible', 'system')),
    title VARCHAR(255),
    body TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin Users Table
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) CHECK (role IN ('super_admin', 'admin', 'moderator')),
    permissions JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Analytics Events Table
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100),
    event_data JSONB,
    session_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_last_active ON users(last_active DESC);
CREATE INDEX idx_profiles_created_at ON profiles(created_at DESC);
CREATE INDEX idx_messages_match_id_created ON messages(match_id, created_at);
CREATE INDEX idx_matches_created_at ON matches(created_at DESC);
CREATE INDEX idx_housing_listings_created_at ON housing_listings(created_at DESC);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_compatibility_settings_updated_at BEFORE UPDATE ON compatibility_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_groups_updated_at BEFORE UPDATE ON groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_housing_listings_updated_at BEFORE UPDATE ON housing_listings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_verification_updated_at BEFORE UPDATE ON verification
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_filters_updated_at BEFORE UPDATE ON user_filters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Admin Tables
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- User Cancellations Table
CREATE TABLE user_cancellations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    cancellation_type VARCHAR(50) CHECK (cancellation_type IN ('account_deletion', 'subscription_cancel', 'manual_deactivation')),
    reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_user_cancellations_updated_at BEFORE UPDATE ON user_cancellations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

