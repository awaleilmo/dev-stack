-- PostgreSQL Initialization Script
-- This script runs when the PostgreSQL container starts for the first time

-- Create additional databases for different projects
CREATE DATABASE laravel_app WITH OWNER = pguser ENCODING = 'UTF8';
CREATE DATABASE symfony_app WITH OWNER = pguser ENCODING = 'UTF8';
CREATE DATABASE test_db WITH OWNER = pguser ENCODING = 'UTF8';
CREATE DATABASE staging_db WITH OWNER = pguser ENCODING = 'UTF8';

-- Create additional users for different environments
CREATE USER laravel_user WITH PASSWORD 'laravel_pass';
CREATE USER symfony_user WITH PASSWORD 'symfony_pass';
CREATE USER test_user WITH PASSWORD 'test_pass';
CREATE USER readonly_user WITH PASSWORD 'readonly_pass';

-- Grant permissions on databases
GRANT ALL PRIVILEGES ON DATABASE laravel_app TO laravel_user;
GRANT ALL PRIVILEGES ON DATABASE symfony_app TO symfony_user;
GRANT ALL PRIVILEGES ON DATABASE test_db TO test_user;
GRANT ALL PRIVILEGES ON DATABASE staging_db TO pguser;

-- Grant connect privileges to readonly user on all databases
GRANT CONNECT ON DATABASE app_pgdb TO readonly_user;
GRANT CONNECT ON DATABASE laravel_app TO readonly_user;
GRANT CONNECT ON DATABASE symfony_app TO readonly_user;
GRANT CONNECT ON DATABASE test_db TO readonly_user;

-- Connect to main database and create sample tables
\c app_pgdb;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create sample tables
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified_at TIMESTAMP NULL,
    password VARCHAR(255) NOT NULL,
    remember_token VARCHAR(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS personal_access_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tokenable_type VARCHAR(255) NOT NULL,
    tokenable_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    token VARCHAR(64) UNIQUE NOT NULL,
    abilities TEXT NULL,
    last_used_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_tokens_tokenable ON personal_access_tokens(tokenable_type, tokenable_id);
CREATE INDEX IF NOT EXISTS idx_tokens_token ON personal_access_tokens(token);

-- Insert sample data
INSERT INTO users (name, email, password) VALUES
('Admin User', 'admin@example.com', crypt('password', gen_salt('bf'))),
('Test User', 'test@example.com', crypt('password', gen_salt('bf'))),
('Developer', 'dev@example.com', crypt('password', gen_salt('bf')))
ON CONFLICT (email) DO NOTHING;

-- Create a function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for auto-updating timestamps
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tokens_updated_at BEFORE UPDATE ON personal_access_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant table permissions to readonly user
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;

-- Ensure future tables also get permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_user;

-- Display success message
SELECT 'PostgreSQL initialization completed successfully!' as message;
