-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================
-- 1. Categories
-- =========================

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    image_url TEXT,
    icon_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =========================
-- 2. Notification Settings
-- =========================

CREATE TABLE notification_settings (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL UNIQUE,
    notification_type VARCHAR(30) NOT NULL
        CHECK (notification_type IN ('relative', 'same_day_morning')),
    offset_minutes INT CHECK (offset_minutes >= 0),
    CHECK (
        (notification_type = 'relative' AND offset_minutes IS NOT NULL)
        OR
        (notification_type <> 'relative' AND offset_minutes IS NULL)
    )
);

-- =========================
-- 3. Volunteers
-- =========================

CREATE TABLE volunteers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    identity_card VARCHAR(9) UNIQUE NOT NULL 
        CHECK (char_length(identity_card) = 9),
    email TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    notification_setting_id INT 
        REFERENCES notification_settings(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =========================
-- 4. Preferences
-- =========================

CREATE TABLE volunteer_preferences (
    volunteer_id UUID REFERENCES volunteers(id) ON DELETE CASCADE,
    category_id INT REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (volunteer_id, category_id)
);

-- =========================
-- 5. Availability
-- =========================

CREATE TABLE volunteer_availability (
    id SERIAL PRIMARY KEY,
    volunteer_id UUID REFERENCES volunteers(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CHECK (start_time < end_time)
);

-- =========================
-- 6. Opportunities
-- =========================

CREATE TABLE opportunities (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    category_id INT REFERENCES categories(id) ON DELETE SET NULL,
    target_date DATE NOT NULL,
    start_time TIME,
    is_deadline BOOLEAN DEFAULT FALSE,
    is_recurring BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =========================
-- 7. Assignments
-- =========================

CREATE TABLE volunteer_assignments (
    id SERIAL PRIMARY KEY,
    volunteer_id UUID REFERENCES volunteers(id) ON DELETE CASCADE,
    opportunity_id INT REFERENCES opportunities(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    scheduled_time TIME,
    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN ('pending','approved','cancelled','completed')),
    notified_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (volunteer_id, opportunity_id, scheduled_date)
);

-- =========================
-- 8. System Updates
-- =========================

CREATE TABLE system_updates (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT,
    image_url TEXT,
    link_url TEXT,
    update_type VARCHAR(20)
        CHECK (update_type IN ('story','banner','announcement')),
    expiry_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =========================
-- 9. Admins
-- =========================

CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL
        CHECK (role IN ('super_admin','manager')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE
);

-- =========================
-- INDEXES
-- =========================

CREATE INDEX idx_assignments_notified 
ON volunteer_assignments(notified_at)
WHERE notified_at IS NULL;

CREATE INDEX idx_assignments_date 
ON volunteer_assignments(scheduled_date);

CREATE INDEX idx_opportunities_category 
ON opportunities(category_id);
