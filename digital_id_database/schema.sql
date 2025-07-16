-- Digital ID Management System: MySQL-Compatible Schema, Migrations, and Seed Data
-- Entities: admin_users, admin_invitations, digital_id_holders, unique_numbers, linkage_records

-- Drop tables if they exist (for testing/migration)
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS linkage_records;
DROP TABLE IF EXISTS unique_numbers;
DROP TABLE IF EXISTS digital_id_holders;
DROP TABLE IF EXISTS admin_invitations;
DROP TABLE IF EXISTS admin_users;
SET FOREIGN_KEY_CHECKS=1;

-- 1. Admin Users Table (super admin, admin)
CREATE TABLE admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(128) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    hashed_password TEXT NOT NULL,
    role ENUM('super_admin', 'admin') NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Admin Invitations Table
CREATE TABLE admin_invitations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(128) NOT NULL UNIQUE,
    invited_by INT NOT NULL,
    invitation_code VARCHAR(64) NOT NULL UNIQUE,
    status ENUM('pending', 'accepted', 'expired') NOT NULL,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    expires_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_admin_invited_by FOREIGN KEY (invited_by) REFERENCES admin_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Digital ID Holders Table
CREATE TABLE digital_id_holders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(64) NOT NULL,
    last_name VARCHAR(64) NOT NULL,
    date_of_birth DATE NOT NULL,
    email VARCHAR(128) UNIQUE,
    phone VARCHAR(32),
    status ENUM('active', 'inactive', 'revoked') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Unique Numbers Table
CREATE TABLE unique_numbers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    unique_number VARCHAR(32) NOT NULL UNIQUE,
    description VARCHAR(100),
    current_holder_id INT,
    assigned_at TIMESTAMP NULL,
    status ENUM('available', 'assigned', 'reserved', 'revoked') NOT NULL DEFAULT 'available',
    CONSTRAINT fk_unique_numbers_holder FOREIGN KEY (current_holder_id) REFERENCES digital_id_holders(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Linkage Records (link/unlink history)
CREATE TABLE linkage_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    unique_number_id INT NOT NULL,
    holder_id INT NULL,
    action ENUM('link', 'unlink') NOT NULL,
    acted_by INT NULL,
    action_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    comment TEXT,
    CONSTRAINT fk_linkage_unique FOREIGN KEY (unique_number_id) REFERENCES unique_numbers(id) ON DELETE CASCADE,
    CONSTRAINT fk_linkage_holder FOREIGN KEY (holder_id) REFERENCES digital_id_holders(id) ON DELETE SET NULL,
    CONSTRAINT fk_linkage_admin FOREIGN KEY (acted_by) REFERENCES admin_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Indexes for performance
CREATE INDEX idx_unique_numbers_current_holder_id ON unique_numbers (current_holder_id);
CREATE INDEX idx_linkage_records_holder_id ON linkage_records (holder_id);
CREATE INDEX idx_linkage_records_unique_number_id ON linkage_records (unique_number_id);

-- Seed Data

-- 1. Super Admin User
INSERT INTO admin_users (email, full_name, hashed_password, role, is_active)
VALUES
    ('superadmin@example.com', 'Super User', '$2b$12$superadminpasswordhash', 'super_admin', TRUE)
ON DUPLICATE KEY UPDATE id=id;

-- 2. Another Admin user (activated)
INSERT INTO admin_users (email, full_name, hashed_password, role, is_active)
VALUES
    ('admin1@example.com', 'Admin One', '$2b$12$admin1passwordhash', 'admin', TRUE)
ON DUPLICATE KEY UPDATE id=id;

-- 3. Seed Invitations (pending and accepted)
INSERT INTO admin_invitations
    (email, invited_by, invitation_code, status, sent_at, expires_at)
VALUES
    ('admin2@example.com',
        (SELECT id FROM admin_users WHERE email='superadmin@example.com' LIMIT 1),
        'invitecode123', 'pending', NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY)
    ),
    ('admin3@example.com',
        (SELECT id FROM admin_users WHERE email='superadmin@example.com' LIMIT 1),
        'invitecode456', 'accepted', DATE_ADD(NOW(), INTERVAL -3 DAY), DATE_ADD(NOW(), INTERVAL 4 DAY)
    )
ON DUPLICATE KEY UPDATE id=id;

-- 4. Digital ID Holders
INSERT INTO digital_id_holders (first_name, last_name, date_of_birth, email, phone, status)
VALUES
    ('Alice', 'Smith', '1990-08-15', 'alice.smith@email.com', '555-1299', 'active'),
    ('Bob', 'Johnson', '1985-12-30', 'bob.johnson@email.com', NULL, 'active'),
    ('Carol', 'White', '1975-02-20', 'carol.white@email.com', '555-3300', 'inactive')
ON DUPLICATE KEY UPDATE id=id;

-- 5. Unique Numbers
INSERT INTO unique_numbers (unique_number, description, current_holder_id, assigned_at, status)
VALUES
    ('UNIQ-100001', 'National Health ID', (SELECT id FROM digital_id_holders WHERE email='alice.smith@email.com' LIMIT 1), NOW(), 'assigned'),
    ('UNIQ-100002', 'Driver License Number', NULL, NULL, 'available'),
    ('UNIQ-100003', 'Student Card', (SELECT id FROM digital_id_holders WHERE email='bob.johnson@email.com' LIMIT 1), DATE_ADD(NOW(), INTERVAL -2 DAY), 'assigned'),
    ('UNIQ-100004', 'Visitor Pass', NULL, NULL, 'reserved'),
    ('UNIQ-100005', 'Employee Badge', NULL, NULL, 'revoked')
ON DUPLICATE KEY UPDATE id=id;

-- 6. Linkage Records (test link/unlink history)
INSERT INTO linkage_records (unique_number_id, holder_id, action, acted_by, action_time, comment)
VALUES
    (
        (SELECT id FROM unique_numbers WHERE unique_number='UNIQ-100001' LIMIT 1),
        (SELECT id FROM digital_id_holders WHERE email='alice.smith@email.com' LIMIT 1),
        'link',
        (SELECT id FROM admin_users WHERE email='admin1@example.com' LIMIT 1),
        NOW(),
        'Linked Health ID to Alice Smith'
    ),
    (
        (SELECT id FROM unique_numbers WHERE unique_number='UNIQ-100003' LIMIT 1),
        (SELECT id FROM digital_id_holders WHERE email='bob.johnson@email.com' LIMIT 1),
        'link',
        (SELECT id FROM admin_users WHERE email='superadmin@example.com' LIMIT 1),
        DATE_ADD(NOW(), INTERVAL -1 DAY),
        'Linked Student Card to Bob Johnson'
    ),
    (
        (SELECT id FROM unique_numbers WHERE unique_number='UNIQ-100003' LIMIT 1),
        NULL,
        'unlink',
        (SELECT id FROM admin_users WHERE email='superadmin@example.com' LIMIT 1),
        NOW(),
        'Unlinked Student Card (bob left school)'
    );
-- End of schema and seed for MySQL

