-- Digital ID Management System: PostgreSQL Schema, Migrations, and Seed Data
-- This script creates all tables, constraints, indexes, and inserts initial seed data.
-- Entities: admin_users (super admin/admin), admin_invitations, digital_id_holders, unique_numbers, linkage_records

BEGIN;

-- 1. Admin Users Table (super admin, admin)
CREATE TABLE IF NOT EXISTS admin_users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(128) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    hashed_password TEXT NOT NULL,
    role VARCHAR(16) NOT NULL CHECK (role IN ('super_admin', 'admin')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 2. Admin Invitations Table
CREATE TABLE IF NOT EXISTS admin_invitations (
    id SERIAL PRIMARY KEY,
    email VARCHAR(128) UNIQUE NOT NULL,
    invited_by INT NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
    invitation_code VARCHAR(64) UNIQUE NOT NULL,
    status VARCHAR(16) NOT NULL CHECK (status IN ('pending', 'accepted', 'expired')),
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- 3. Digital ID Holders Table
CREATE TABLE IF NOT EXISTS digital_id_holders (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(64) NOT NULL,
    last_name VARCHAR(64) NOT NULL,
    date_of_birth DATE NOT NULL,
    email VARCHAR(128) UNIQUE,
    phone VARCHAR(32),
    status VARCHAR(16) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'revoked')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 4. Unique Numbers Table
CREATE TABLE IF NOT EXISTS unique_numbers (
    id SERIAL PRIMARY KEY,
    unique_number VARCHAR(32) UNIQUE NOT NULL,
    description VARCHAR(100),
    current_holder_id INT REFERENCES digital_id_holders(id) ON DELETE SET NULL,
    assigned_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(16) NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'assigned', 'reserved', 'revoked'))
);

-- 5. Linkage Records (link/unlink history)
CREATE TABLE IF NOT EXISTS linkage_records (
    id SERIAL PRIMARY KEY,
    unique_number_id INT NOT NULL REFERENCES unique_numbers(id) ON DELETE CASCADE,
    holder_id INT REFERENCES digital_id_holders(id) ON DELETE SET NULL,
    action VARCHAR(8) NOT NULL CHECK (action IN ('link', 'unlink')),
    acted_by INT REFERENCES admin_users(id) ON DELETE SET NULL,
    action_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    comment TEXT
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_unique_numbers_current_holder_id ON unique_numbers (current_holder_id);
CREATE INDEX IF NOT EXISTS idx_linkage_records_holder_id ON linkage_records (holder_id);
CREATE INDEX IF NOT EXISTS idx_linkage_records_unique_number_id ON linkage_records (unique_number_id);

-- Seed Data

-- 1. Super Admin User
-- Password hash is just a sample -- replace with real hash in production.
INSERT INTO admin_users (email, full_name, hashed_password, role, is_active) VALUES
    ('superadmin@example.com', 'Super User', '$2b$12$superadminpasswordhash', 'super_admin', TRUE)
    ON CONFLICT (email) DO NOTHING;

-- 2. Another Admin user (activated)
INSERT INTO admin_users (email, full_name, hashed_password, role, is_active) VALUES
    ('admin1@example.com', 'Admin One', '$2b$12$admin1passwordhash', 'admin', TRUE)
    ON CONFLICT (email) DO NOTHING;

-- 3. Seed Invitations (pending and accepted)
-- (You may want the hashcodes to be random in real deployments)
INSERT INTO admin_invitations (email, invited_by, invitation_code, status, sent_at, expires_at)
VALUES
    ('admin2@example.com', 
     (SELECT id FROM admin_users WHERE email='superadmin@example.com'), 
     'invitecode123', 'pending', NOW(), NOW() + INTERVAL '7 days'),
    ('admin3@example.com', 
     (SELECT id FROM admin_users WHERE email='superadmin@example.com'), 
     'invitecode456', 'accepted', NOW() - INTERVAL '3 days', NOW() + INTERVAL '4 days')
    ON CONFLICT (email) DO NOTHING;

-- 4. Digital ID Holders
INSERT INTO digital_id_holders (first_name, last_name, date_of_birth, email, phone, status)
VALUES
    ('Alice', 'Smith', '1990-08-15', 'alice.smith@email.com', '555-1299', 'active'),
    ('Bob', 'Johnson', '1985-12-30', 'bob.johnson@email.com', NULL, 'active'),
    ('Carol', 'White', '1975-02-20', 'carol.white@email.com', '555-3300', 'inactive')
    ON CONFLICT (email) DO NOTHING;

-- 5. Unique Numbers (some available, assigned, reserved, revoked)
INSERT INTO unique_numbers (unique_number, description, current_holder_id, assigned_at, status)
VALUES
    ('UNIQ-100001', 'National Health ID', (SELECT id FROM digital_id_holders WHERE email='alice.smith@email.com'), NOW(), 'assigned'),
    ('UNIQ-100002', 'Driver License Number', NULL, NULL, 'available'),
    ('UNIQ-100003', 'Student Card', (SELECT id FROM digital_id_holders WHERE email='bob.johnson@email.com'), NOW() - INTERVAL '2 days', 'assigned'),
    ('UNIQ-100004', 'Visitor Pass', NULL, NULL, 'reserved'),
    ('UNIQ-100005', 'Employee Badge', NULL, NULL, 'revoked')
    ON CONFLICT (unique_number) DO NOTHING;

-- 6. Linkage Records (test link/unlink history)
INSERT INTO linkage_records (unique_number_id, holder_id, action, acted_by, action_time, comment)
VALUES
    (
        (SELECT id FROM unique_numbers WHERE unique_number='UNIQ-100001'),
        (SELECT id FROM digital_id_holders WHERE email='alice.smith@email.com'),
        'link',
        (SELECT id FROM admin_users WHERE email='admin1@example.com'),
        NOW(),
        'Linked Health ID to Alice Smith'
    ),
    (
        (SELECT id FROM unique_numbers WHERE unique_number='UNIQ-100003'),
        (SELECT id FROM digital_id_holders WHERE email='bob.johnson@email.com'),
        'link',
        (SELECT id FROM admin_users WHERE email='superadmin@example.com'),
        NOW() - INTERVAL '1 day',
        'Linked Student Card to Bob Johnson'
    ),
    (
        (SELECT id FROM unique_numbers WHERE unique_number='UNIQ-100003'),
        NULL,
        'unlink',
        (SELECT id FROM admin_users WHERE email='superadmin@example.com'),
        NOW(),
        'Unlinked Student Card (bob left school)'
    )
;

COMMIT;

-- End of schema and seed
