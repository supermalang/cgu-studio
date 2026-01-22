-- ============================================================================
-- UCG STUDIO DATABASE SCHEMA
-- PostgreSQL 15 (Supabase)
-- Version: 1.0.0
-- Last Updated: January 20, 2026
-- ============================================================================

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- ENUMS
-- ============================================================================

-- User role enum
CREATE TYPE user_role AS ENUM ('user', 'admin');

-- User status enum
CREATE TYPE user_status AS ENUM ('active', 'suspended');

-- Project status enum
CREATE TYPE project_status AS ENUM ('draft', 'in_progress', 'completed', 'archived');

-- Shot type enum
CREATE TYPE shot_type AS ENUM ('ai_generated', 'stock_footage');

-- Shot generation status enum
CREATE TYPE generation_status AS ENUM ('pending', 'generating', 'completed', 'failed');

-- Shot category enum
CREATE TYPE shot_category AS ENUM (
  'pov',
  'close_up',
  'extreme_close_up',
  'medium_shot',
  'wide_shot',
  'off_shoulder',
  'aerial',
  'low_angle',
  'high_angle'
);

-- Aspect ratio enum
CREATE TYPE aspect_ratio AS ENUM ('16:9', '9:16', '1:1', '4:5');

-- Video resolution enum
CREATE TYPE video_resolution AS ENUM ('720p', '1080p', '4k');

-- Credit transaction type enum
CREATE TYPE transaction_type AS ENUM ('purchase', 'deduction', 'refund');

-- Payment provider enum
CREATE TYPE payment_provider AS ENUM ('wave', 'orange_money');

-- Payment status enum
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed');

-- Workflow type enum
CREATE TYPE workflow_type AS ENUM (
  'script_breakdown',
  'audio_generation',
  'video_generation',
  'export',
  'avatar_creation',
  'environment_creation'
);

-- Export status enum
CREATE TYPE export_status AS ENUM ('queued', 'processing', 'completed', 'failed');

-- Notification type enum
CREATE TYPE notification_type AS ENUM (
  'export_ready',
  'low_credits',
  'generation_failed',
  'payment_received',
  'system_announcement'
);

-- ============================================================================
-- TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. PROFILES TABLE (extends Supabase auth.users)
-- ----------------------------------------------------------------------------

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- User Information
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  country TEXT, -- ISO country code (e.g., "SN" for Senegal)
  phone_number TEXT,
  timezone TEXT DEFAULT 'UTC',
  preferred_language TEXT DEFAULT 'en-US', -- ISO language code
  
  -- Credit & Storage
  credit_balance INTEGER NOT NULL DEFAULT 0,
  total_storage_used BIGINT NOT NULL DEFAULT 0, -- bytes
  
  -- Role & Status
  role user_role NOT NULL DEFAULT 'user',
  status user_status NOT NULL DEFAULT 'active',
  
  -- API Keys (encrypted)
  elevenlabs_api_key TEXT, -- Encrypted with pgcrypto
  
  -- Activity Tracking
  last_active_at TIMESTAMPTZ,
  
  -- Timestamps & Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  
  CONSTRAINT credit_balance_non_negative CHECK (credit_balance >= 0),
  CONSTRAINT storage_non_negative CHECK (total_storage_used >= 0)
);

-- Indexes
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_status ON profiles(status);
CREATE INDEX idx_profiles_last_active ON profiles(last_active_at);

-- ----------------------------------------------------------------------------
-- 2. ADMIN SETTINGS TABLE (Single Row)
-- ----------------------------------------------------------------------------

CREATE TABLE admin_settings (
  id INTEGER PRIMARY KEY DEFAULT 1, -- Only one row
  
  -- Company Settings (JSONB)
  company_settings JSONB NOT NULL DEFAULT '{
    "company_name": "UCG Studio",
    "description": "AI-powered video production platform",
    "support_email": "support@ucgstudio.com",
    "contact_phone": "",
    "contact_email": "",
    "logo_url": ""
  }'::jsonb,
  
  -- Platform Settings (JSONB)
  platform_settings JSONB NOT NULL DEFAULT '{
    "low_credit_threshold": 100,
    "max_audio_upload_size_mb": 2,
    "max_storage_per_user_gb": 1,
    "ai_model_provider": "openai",
    "ai_model_name": "gpt-4-turbo-preview",
    "credit_cost_breakdown": 10,
    "credit_cost_audio_per_shot": 2,
    "credit_cost_video_per_shot": 50,
    "rate_limit_generations_per_hour": 100,
    "rate_limit_enabled": false,
    "generation_timeout_seconds": 180,
    "retry_enabled": true,
    "max_retries": 3
  }'::jsonb,
  
  -- Credit Packages (JSONB Array)
  credit_packages JSONB NOT NULL DEFAULT '[
    {"price_usd": 5, "credits": 250},
    {"price_usd": 20, "credits": 1000},
    {"price_usd": 50, "credits": 3000}
  ]'::jsonb,
  
  -- Timestamps & Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id),
  
  CONSTRAINT only_one_settings_row CHECK (id = 1)
);

-- Insert default settings
INSERT INTO admin_settings (id) VALUES (1);

-- ----------------------------------------------------------------------------
-- 3. PROJECTS TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Project Identity
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  script TEXT NOT NULL, -- Original full script
  
  -- Video Settings
  ai_budget_percentage INTEGER NOT NULL DEFAULT 80, -- 20-100
  target_aspect_ratio aspect_ratio NOT NULL DEFAULT '16:9',
  target_resolution video_resolution NOT NULL DEFAULT '1080p',
  voiceover_language TEXT NOT NULL DEFAULT 'en-US',
  project_language TEXT NOT NULL DEFAULT 'en-US',
  
  -- Avatar & Environment (Future)
  avatar_id UUID, -- References avatars table (future)
  wardrobe_id UUID, -- References avatar_wardrobes table (future)
  environment_id UUID, -- References environments table (future)
  
  -- Status & Metrics
  status project_status NOT NULL DEFAULT 'draft',
  total_shots INTEGER NOT NULL DEFAULT 0,
  total_credits_used INTEGER NOT NULL DEFAULT 0,
  
  -- Timestamps & Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  
  CONSTRAINT ai_budget_range CHECK (ai_budget_percentage >= 20 AND ai_budget_percentage <= 100),
  CONSTRAINT total_shots_non_negative CHECK (total_shots >= 0),
  CONSTRAINT total_credits_non_negative CHECK (total_credits_used >= 0)
);

-- Indexes
CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_slug ON projects(slug);
CREATE INDEX idx_projects_created_at ON projects(created_at DESC);

-- Unique constraint: slug must be unique per user
CREATE UNIQUE INDEX idx_projects_user_slug ON projects(user_id, slug);

-- ----------------------------------------------------------------------------
-- 4. SHOTS TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE shots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  
  -- Shot Details
  shot_number INTEGER NOT NULL,
  script_text TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL, -- 2-8 seconds
  
  -- Shot Type & Recommendation
  shot_type shot_type NOT NULL DEFAULT 'ai_generated',
  stock_search_hint TEXT, -- For stock footage shots
  
  -- AI Prompts (3 alternatives)
  ai_prompt_1 TEXT,
  shot_category_1 shot_category,
  ai_prompt_2 TEXT,
  shot_category_2 shot_category,
  ai_prompt_3 TEXT,
  shot_category_3 shot_category,
  
  -- User Selection
  selected_prompt INTEGER, -- 1, 2, or 3
  
  -- Generation Status
  generation_status generation_status NOT NULL DEFAULT 'pending',
  
  -- Voice Settings (JSONB)
  voice_settings JSONB DEFAULT '{
    "voice_id": "",
    "speed": 1.0,
    "stability": 0.75,
    "clarity": 0.85,
    "emotion": "neutral"
  }'::jsonb,
  elevenlabs_voice_id TEXT,
  
  -- Media URLs
  audio_file_url TEXT,
  video_file_url TEXT,
  
  -- Credit Tracking
  audio_credits_used INTEGER DEFAULT 0,
  video_credits_used INTEGER DEFAULT 0,
  
  -- Timestamps & Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  
  CONSTRAINT duration_range CHECK (duration_seconds >= 2 AND duration_seconds <= 8),
  CONSTRAINT selected_prompt_range CHECK (selected_prompt IN (1, 2, 3) OR selected_prompt IS NULL),
  CONSTRAINT shot_number_positive CHECK (shot_number > 0)
);

-- Indexes
CREATE INDEX idx_shots_project_id ON shots(project_id);
CREATE INDEX idx_shots_generation_status ON shots(generation_status);
CREATE INDEX idx_shots_created_at ON shots(created_at DESC);

-- Unique constraint: shot_number must be unique per project
CREATE UNIQUE INDEX idx_shots_project_shot_number ON shots(project_id, shot_number);

-- ----------------------------------------------------------------------------
-- 5. CREDIT TRANSACTIONS TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE credit_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Transaction Details
  transaction_type transaction_type NOT NULL,
  amount INTEGER NOT NULL, -- Can be negative for deductions
  previous_balance INTEGER NOT NULL,
  new_balance INTEGER NOT NULL,
  reason TEXT NOT NULL,
  
  -- Related Entities
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  shot_id UUID REFERENCES shots(id) ON DELETE SET NULL,
  payment_transaction_id UUID, -- References payment_transactions
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_credit_transactions_user_id ON credit_transactions(user_id);
CREATE INDEX idx_credit_transactions_created_at ON credit_transactions(created_at DESC);
CREATE INDEX idx_credit_transactions_type ON credit_transactions(transaction_type);

-- ----------------------------------------------------------------------------
-- 6. PAYMENT TRANSACTIONS TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Payment Details
  payment_provider payment_provider NOT NULL,
  payment_amount_usd DECIMAL(10, 2) NOT NULL,
  credits_purchased INTEGER NOT NULL,
  
  -- Payment Status
  payment_status payment_status NOT NULL DEFAULT 'pending',
  provider_transaction_id TEXT,
  webhook_payload JSONB, -- For debugging
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  
  CONSTRAINT amount_positive CHECK (payment_amount_usd > 0),
  CONSTRAINT credits_positive CHECK (credits_purchased > 0)
);

-- Indexes
CREATE INDEX idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(payment_status);
CREATE INDEX idx_payment_transactions_created_at ON payment_transactions(created_at DESC);
CREATE INDEX idx_payment_transactions_provider_tx_id ON payment_transactions(provider_transaction_id);

-- ----------------------------------------------------------------------------
-- 7. EXPORTS TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE exports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Export Details
  status export_status NOT NULL DEFAULT 'queued',
  zip_file_url TEXT,
  zip_file_size_bytes BIGINT,
  
  -- Error Handling
  error_message TEXT,
  
  -- Expiry
  expires_at TIMESTAMPTZ NOT NULL, -- created_at + 3 days
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  
  CONSTRAINT file_size_non_negative CHECK (zip_file_size_bytes >= 0 OR zip_file_size_bytes IS NULL)
);

-- Indexes
CREATE INDEX idx_exports_user_id ON exports(user_id);
CREATE INDEX idx_exports_project_id ON exports(project_id);
CREATE INDEX idx_exports_status ON exports(status);
CREATE INDEX idx_exports_expires_at ON exports(expires_at);

-- ----------------------------------------------------------------------------
-- 8. N8N JOBS TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE n8n_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Job Details
  workflow_type workflow_type NOT NULL,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  shot_id UUID REFERENCES shots(id) ON DELETE SET NULL,
  
  -- Status
  status generation_status NOT NULL DEFAULT 'pending',
  n8n_execution_id TEXT,
  error_message TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  
  CONSTRAINT retry_count_non_negative CHECK (retry_count >= 0)
);

-- Indexes
CREATE INDEX idx_n8n_jobs_user_id ON n8n_jobs(user_id);
CREATE INDEX idx_n8n_jobs_workflow_type ON n8n_jobs(workflow_type);
CREATE INDEX idx_n8n_jobs_status ON n8n_jobs(status);
CREATE INDEX idx_n8n_jobs_created_at ON n8n_jobs(created_at DESC);
CREATE INDEX idx_n8n_jobs_execution_id ON n8n_jobs(n8n_execution_id);

-- ----------------------------------------------------------------------------
-- 9. NOTIFICATIONS TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Notification Details
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  
  -- Related Entity
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  export_id UUID REFERENCES exports(id) ON DELETE SET NULL,
  
  -- Status
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- ----------------------------------------------------------------------------
-- 10. AVATARS TABLE (Future Feature)
-- ----------------------------------------------------------------------------

CREATE TABLE avatars (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Avatar Details
  name TEXT NOT NULL,
  description TEXT,
  reference_photo_url TEXT NOT NULL,
  physical_specs JSONB, -- Flexible JSON for appearance details
  
  -- Current State
  current_wardrobe_id UUID, -- References avatar_wardrobes
  environment_id UUID, -- References environments
  
  -- Status
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  
  -- Timestamps & Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id)
);

-- Indexes
CREATE INDEX idx_avatars_user_id ON avatars(user_id);
CREATE INDEX idx_avatars_is_active ON avatars(is_active);

-- ----------------------------------------------------------------------------
-- 11. AVATAR WARDROBES TABLE (Future Feature)
-- ----------------------------------------------------------------------------

CREATE TABLE avatar_wardrobes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  avatar_id UUID NOT NULL REFERENCES avatars(id) ON DELETE CASCADE,
  
  -- Wardrobe Details
  wardrobe_name TEXT NOT NULL,
  wardrobe_description TEXT,
  reference_photo_url TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id)
);

-- Indexes
CREATE INDEX idx_wardrobes_avatar_id ON avatar_wardrobes(avatar_id);

-- Add foreign key constraint after table creation
ALTER TABLE avatars
ADD CONSTRAINT fk_avatars_current_wardrobe
FOREIGN KEY (current_wardrobe_id) REFERENCES avatar_wardrobes(id) ON DELETE SET NULL;

-- ----------------------------------------------------------------------------
-- 12. ENVIRONMENTS TABLE (Future Feature)
-- ----------------------------------------------------------------------------

CREATE TABLE environments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Environment Details
  name TEXT NOT NULL,
  description TEXT,
  reference_image_url TEXT,
  environment_specs JSONB, -- Flexible JSON for environment details
  
  -- Status
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  
  -- Timestamps & Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id)
);

-- Indexes
CREATE INDEX idx_environments_user_id ON environments(user_id);
CREATE INDEX idx_environments_is_active ON environments(is_active);

-- Add foreign key constraint to avatars table
ALTER TABLE avatars
ADD CONSTRAINT fk_avatars_environment
FOREIGN KEY (environment_id) REFERENCES environments(id) ON DELETE SET NULL;

-- ============================================================================
-- TRIGGERS & FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- AUTO-UPDATE TIMESTAMPS
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admin_settings_updated_at BEFORE UPDATE ON admin_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shots_updated_at BEFORE UPDATE ON shots
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_n8n_jobs_updated_at BEFORE UPDATE ON n8n_jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_avatars_updated_at BEFORE UPDATE ON avatars
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_environments_updated_at BEFORE UPDATE ON environments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- AUTO-SET created_by ON INSERT
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_created_by()
RETURNS TRIGGER AS $$
BEGIN
  NEW.created_by = auth.uid();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to relevant tables
CREATE TRIGGER set_projects_created_by BEFORE INSERT ON projects
  FOR EACH ROW EXECUTE FUNCTION set_created_by();

CREATE TRIGGER set_shots_created_by BEFORE INSERT ON shots
  FOR EACH ROW EXECUTE FUNCTION set_created_by();

CREATE TRIGGER set_avatars_created_by BEFORE INSERT ON avatars
  FOR EACH ROW EXECUTE FUNCTION set_created_by();

CREATE TRIGGER set_environments_created_by BEFORE INSERT ON environments
  FOR EACH ROW EXECUTE FUNCTION set_created_by();

CREATE TRIGGER set_wardrobes_created_by BEFORE INSERT ON avatar_wardrobes
  FOR EACH ROW EXECUTE FUNCTION set_created_by();

-- ----------------------------------------------------------------------------
-- CREDIT DEDUCTION ON SHOT GENERATION
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION record_credit_deduction()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_credits_used INTEGER;
  v_previous_balance INTEGER;
BEGIN
  -- Only process when status changes to 'generating'
  IF NEW.generation_status = 'generating' AND OLD.generation_status = 'pending' THEN
    -- Get user_id from project
    SELECT user_id INTO v_user_id
    FROM projects
    WHERE id = NEW.project_id;
    
    -- Calculate total credits
    v_credits_used := NEW.audio_credits_used + NEW.video_credits_used;
    
    -- Get previous balance
    SELECT credit_balance INTO v_previous_balance
    FROM profiles
    WHERE id = v_user_id;
    
    -- Insert credit transaction
    INSERT INTO credit_transactions (
      user_id,
      transaction_type,
      amount,
      previous_balance,
      new_balance,
      reason,
      project_id,
      shot_id
    ) VALUES (
      v_user_id,
      'deduction',
      -v_credits_used,
      v_previous_balance,
      v_previous_balance - v_credits_used,
      'Generation for Shot #' || NEW.shot_number,
      NEW.project_id,
      NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_record_credit_deduction
AFTER UPDATE ON shots
FOR EACH ROW
EXECUTE FUNCTION record_credit_deduction();

-- ----------------------------------------------------------------------------
-- UPDATE USER BALANCE FROM CREDIT TRANSACTIONS
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_user_credit_balance()
RETURNS TRIGGER AS $$
BEGIN
  -- Update user's credit balance
  UPDATE profiles
  SET credit_balance = NEW.new_balance
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_credit_balance
AFTER INSERT ON credit_transactions
FOR EACH ROW
EXECUTE FUNCTION update_user_credit_balance();

-- ----------------------------------------------------------------------------
-- UPDATE PROJECT TOTAL CREDITS USED
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_project_credits()
RETURNS TRIGGER AS $$
BEGIN
  -- Update project's total credits used
  IF NEW.project_id IS NOT NULL AND NEW.transaction_type = 'deduction' THEN
    UPDATE projects
    SET total_credits_used = total_credits_used + ABS(NEW.amount)
    WHERE id = NEW.project_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_project_credits
AFTER INSERT ON credit_transactions
FOR EACH ROW
EXECUTE FUNCTION update_project_credits();

-- ----------------------------------------------------------------------------
-- REFUND CREDITS ON GENERATION FAILURE
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION refund_credits_on_failure()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_credits_to_refund INTEGER;
  v_previous_balance INTEGER;
BEGIN
  -- Only process when status changes to 'failed' from 'generating'
  IF NEW.generation_status = 'failed' AND OLD.generation_status = 'generating' THEN
    -- Get user_id from project
    SELECT user_id INTO v_user_id
    FROM projects
    WHERE id = NEW.project_id;
    
    -- Calculate credits to refund
    v_credits_to_refund := NEW.audio_credits_used + NEW.video_credits_used;
    
    -- Get current balance (after deduction)
    SELECT credit_balance INTO v_previous_balance
    FROM profiles
    WHERE id = v_user_id;
    
    -- Insert refund transaction
    INSERT INTO credit_transactions (
      user_id,
      transaction_type,
      amount,
      previous_balance,
      new_balance,
      reason,
      project_id,
      shot_id
    ) VALUES (
      v_user_id,
      'refund',
      v_credits_to_refund,
      v_previous_balance,
      v_previous_balance + v_credits_to_refund,
      'Refund: Generation failed for Shot #' || NEW.shot_number,
      NEW.project_id,
      NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_refund_on_failure
AFTER UPDATE ON shots
FOR EACH ROW
EXECUTE FUNCTION refund_credits_on_failure();

-- ----------------------------------------------------------------------------
-- AUTO-SET EXPORT EXPIRY DATE
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_export_expiry()
RETURNS TRIGGER AS $$
BEGIN
  NEW.expires_at = NEW.created_at + INTERVAL '3 days';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_export_expiry
BEFORE INSERT ON exports
FOR EACH ROW
EXECUTE FUNCTION set_export_expiry();

-- ----------------------------------------------------------------------------
-- UPDATE PROJECT TOTAL SHOTS COUNT
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_project_shot_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE projects
  SET total_shots = (
    SELECT COUNT(*)
    FROM shots
    WHERE project_id = NEW.project_id
  )
  WHERE id = NEW.project_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_shot_count_insert
AFTER INSERT ON shots
FOR EACH ROW
EXECUTE FUNCTION update_project_shot_count();

CREATE TRIGGER trigger_update_shot_count_delete
AFTER DELETE ON shots
FOR EACH ROW
EXECUTE FUNCTION update_project_shot_count();

-- ----------------------------------------------------------------------------
-- CREATE PROFILE ON USER SIGNUP (Supabase Auth Hook)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, created_by, updated_by)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.id,
    NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- RPC FUNCTIONS (Callable from Client)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ADMIN FUNCTIONS
-- ----------------------------------------------------------------------------

-- Add credits manually (admin only)
CREATE OR REPLACE FUNCTION admin_add_credits(
  target_user_id UUID,
  credit_amount INTEGER,
  credit_reason TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_previous_balance INTEGER;
  v_new_balance INTEGER;
  v_is_admin BOOLEAN;
BEGIN
  -- Check if caller is admin
  SELECT role = 'admin' INTO v_is_admin
  FROM profiles
  WHERE id = auth.uid();
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- Get current balance
  SELECT credit_balance INTO v_previous_balance
  FROM profiles
  WHERE id = target_user_id;
  
  IF v_previous_balance IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;
  
  v_new_balance := v_previous_balance + credit_amount;
  
  -- Insert credit transaction
  INSERT INTO credit_transactions (
    user_id,
    transaction_type,
    amount,
    previous_balance,
    new_balance,
    reason
  ) VALUES (
    target_user_id,
    'purchase', -- Using 'purchase' for manual additions
    credit_amount,
    v_previous_balance,
    v_new_balance,
    credit_reason
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'previous_balance', v_previous_balance,
    'new_balance', v_new_balance
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get platform statistics (admin only)
CREATE OR REPLACE FUNCTION admin_get_platform_stats()
RETURNS JSONB AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_total_users INTEGER;
  v_active_users INTEGER;
  v_total_projects INTEGER;
  v_total_shots INTEGER;
  v_total_credits_sold BIGINT;
  v_total_credits_used BIGINT;
  v_failed_jobs INTEGER;
BEGIN
  -- Check if caller is admin
  SELECT role = 'admin' INTO v_is_admin
  FROM profiles
  WHERE id = auth.uid();
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- Gather statistics
  SELECT COUNT(*) INTO v_total_users FROM profiles;
  SELECT COUNT(*) INTO v_active_users FROM profiles WHERE status = 'active';
  SELECT COUNT(*) INTO v_total_projects FROM projects;
  SELECT COUNT(*) INTO v_total_shots FROM shots;
  
  SELECT COALESCE(SUM(amount), 0) INTO v_total_credits_sold
  FROM credit_transactions
  WHERE transaction_type = 'purchase';
  
  SELECT COALESCE(SUM(ABS(amount)), 0) INTO v_total_credits_used
  FROM credit_transactions
  WHERE transaction_type = 'deduction';
  
  SELECT COUNT(*) INTO v_failed_jobs
  FROM n8n_jobs
  WHERE status = 'failed';
  
  RETURN jsonb_build_object(
    'total_users', v_total_users,
    'active_users', v_active_users,
    'total_projects', v_total_projects,
    'total_shots', v_total_shots,
    'total_credits_sold', v_total_credits_sold,
    'total_credits_used', v_total_credits_used,
    'failed_jobs', v_failed_jobs
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Suspend/unsuspend user (admin only)
CREATE OR REPLACE FUNCTION admin_suspend_user(
  target_user_id UUID,
  should_suspend BOOLEAN
)
RETURNS JSONB AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_new_status user_status;
BEGIN
  -- Check if caller is admin
  SELECT role = 'admin' INTO v_is_admin
  FROM profiles
  WHERE id = auth.uid();
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  v_new_status := CASE WHEN should_suspend THEN 'suspended'::user_status ELSE 'active'::user_status END;
  
  UPDATE profiles
  SET status = v_new_status
  WHERE id = target_user_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'user_id', target_user_id,
    'status', v_new_status
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get failed jobs (admin only)
CREATE OR REPLACE FUNCTION admin_get_failed_jobs(
  limit_count INTEGER DEFAULT 50
)
RETURNS SETOF n8n_jobs AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  -- Check if caller is admin
  SELECT role = 'admin' INTO v_is_admin
  FROM profiles
  WHERE id = auth.uid();
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  RETURN QUERY
  SELECT *
  FROM n8n_jobs
  WHERE status = 'failed'
  ORDER BY created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- USER FUNCTIONS
-- ----------------------------------------------------------------------------

-- Get current user's credit balance
CREATE OR REPLACE FUNCTION get_user_credit_balance()
RETURNS INTEGER AS $$
DECLARE
  v_balance INTEGER;
BEGIN
  SELECT credit_balance INTO v_balance
  FROM profiles
  WHERE id = auth.uid();
  
  RETURN COALESCE(v_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate project cost estimate
CREATE OR REPLACE FUNCTION get_project_cost_estimate(
  shot_count INTEGER
)
RETURNS JSONB AS $$
DECLARE
  v_settings JSONB;
  v_breakdown_cost INTEGER;
  v_audio_cost INTEGER;
  v_video_cost INTEGER;
  v_total_cost INTEGER;
BEGIN
  -- Get admin settings
  SELECT platform_settings INTO v_settings
  FROM admin_settings
  WHERE id = 1;
  
  v_breakdown_cost := (v_settings->>'credit_cost_breakdown')::INTEGER;
  v_audio_cost := (v_settings->>'credit_cost_audio_per_shot')::INTEGER * shot_count;
  v_video_cost := (v_settings->>'credit_cost_video_per_shot')::INTEGER * shot_count;
  v_total_cost := v_breakdown_cost + v_audio_cost + v_video_cost;
  
  RETURN jsonb_build_object(
    'breakdown', v_breakdown_cost,
    'audio_total', v_audio_cost,
    'video_total', v_video_cost,
    'total_cost', v_total_cost,
    'per_shot', (v_settings->>'credit_cost_audio_per_shot')::INTEGER + (v_settings->>'credit_cost_video_per_shot')::INTEGER
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user can generate (has enough credits)
CREATE OR REPLACE FUNCTION can_user_generate(
  target_shot_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_user_balance INTEGER;
  v_shot_credits INTEGER;
  v_can_generate BOOLEAN;
BEGIN
  -- Get user balance
  SELECT credit_balance INTO v_user_balance
  FROM profiles
  WHERE id = auth.uid();
  
  -- Get shot credit cost
  SELECT audio_credits_used + video_credits_used INTO v_shot_credits
  FROM shots
  WHERE id = target_shot_id;
  
  v_can_generate := v_user_balance >= v_shot_credits;
  
  RETURN jsonb_build_object(
    'can_generate', v_can_generate,
    'user_balance', v_user_balance,
    'required_credits', v_shot_credits,
    'remaining_after', v_user_balance - v_shot_credits
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- HELPER FUNCTION: CHECK IF USER IS ADMIN (bypasses RLS)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- SECURITY DEFINER allows this function to bypass RLS policies
  -- This prevents infinite recursion when checking admin status
  RETURN EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE shots ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exports ENABLE ROW LEVEL SECURITY;
ALTER TABLE n8n_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE avatars ENABLE ROW LEVEL SECURITY;
ALTER TABLE avatar_wardrobes ENABLE ROW LEVEL SECURITY;
ALTER TABLE environments ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- PROFILES POLICIES
-- ----------------------------------------------------------------------------

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
USING (is_admin());

-- Admins can update all profiles
CREATE POLICY "Admins can update all profiles"
ON profiles FOR UPDATE
USING (is_admin());

-- ----------------------------------------------------------------------------
-- ADMIN SETTINGS POLICIES
-- ----------------------------------------------------------------------------

-- Everyone can view admin settings
CREATE POLICY "Anyone can view admin settings"
ON admin_settings FOR SELECT
USING (true);

-- Only admins can update admin settings
CREATE POLICY "Only admins can update admin settings"
ON admin_settings FOR UPDATE
USING (is_admin());

-- ----------------------------------------------------------------------------
-- PROJECTS POLICIES
-- ----------------------------------------------------------------------------

-- Users can view their own projects
CREATE POLICY "Users can view own projects"
ON projects FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own projects
CREATE POLICY "Users can insert own projects"
ON projects FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own projects
CREATE POLICY "Users can update own projects"
ON projects FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own projects
CREATE POLICY "Users can delete own projects"
ON projects FOR DELETE
USING (auth.uid() = user_id);

-- Admins can view all projects
CREATE POLICY "Admins can view all projects"
ON projects FOR SELECT
USING (is_admin());

-- Admins can archive (update) all projects
CREATE POLICY "Admins can update all projects"
ON projects FOR UPDATE
USING (is_admin());

-- ----------------------------------------------------------------------------
-- SHOTS POLICIES
-- ----------------------------------------------------------------------------

-- Users can view shots from their own projects
CREATE POLICY "Users can view own shots"
ON shots FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM projects
    WHERE projects.id = shots.project_id
    AND projects.user_id = auth.uid()
  )
);

-- Users can insert shots into their own projects
CREATE POLICY "Users can insert own shots"
ON shots FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM projects
    WHERE projects.id = shots.project_id
    AND projects.user_id = auth.uid()
  )
);

-- Users can update their own shots
CREATE POLICY "Users can update own shots"
ON shots FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM projects
    WHERE projects.id = shots.project_id
    AND projects.user_id = auth.uid()
  )
);

-- Users can delete their own shots
CREATE POLICY "Users can delete own shots"
ON shots FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM projects
    WHERE projects.id = shots.project_id
    AND projects.user_id = auth.uid()
  )
);

-- Admins can view all shots
CREATE POLICY "Admins can view all shots"
ON shots FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- CREDIT TRANSACTIONS POLICIES
-- ----------------------------------------------------------------------------

-- Users can view their own transactions
CREATE POLICY "Users can view own transactions"
ON credit_transactions FOR SELECT
USING (auth.uid() = user_id);

-- Admins can view all transactions
CREATE POLICY "Admins can view all transactions"
ON credit_transactions FOR SELECT
USING (is_admin());

-- System can insert transactions (via triggers)
-- No direct INSERT policy needed - handled by triggers

-- ----------------------------------------------------------------------------
-- PAYMENT TRANSACTIONS POLICIES
-- ----------------------------------------------------------------------------

-- Users can view their own payments
CREATE POLICY "Users can view own payments"
ON payment_transactions FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own payments
CREATE POLICY "Users can insert own payments"
ON payment_transactions FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Admins can view all payments
CREATE POLICY "Admins can view all payments"
ON payment_transactions FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- EXPORTS POLICIES
-- ----------------------------------------------------------------------------

-- Users can view their own exports
CREATE POLICY "Users can view own exports"
ON exports FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own exports
CREATE POLICY "Users can insert own exports"
ON exports FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can delete their own exports
CREATE POLICY "Users can delete own exports"
ON exports FOR DELETE
USING (auth.uid() = user_id);

-- Admins can view all exports
CREATE POLICY "Admins can view all exports"
ON exports FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- N8N JOBS POLICIES
-- ----------------------------------------------------------------------------

-- Users can view their own jobs
CREATE POLICY "Users can view own jobs"
ON n8n_jobs FOR SELECT
USING (auth.uid() = user_id);

-- Admins can view all jobs
CREATE POLICY "Admins can view all jobs"
ON n8n_jobs FOR SELECT
USING (is_admin());

-- System can insert/update jobs
-- No direct policies needed - handled by application

-- ----------------------------------------------------------------------------
-- NOTIFICATIONS POLICIES
-- ----------------------------------------------------------------------------

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
ON notifications FOR SELECT
USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
ON notifications FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
ON notifications FOR DELETE
USING (auth.uid() = user_id);

-- System can insert notifications
-- Handled by application/triggers

-- ----------------------------------------------------------------------------
-- AVATARS POLICIES (Future)
-- ----------------------------------------------------------------------------

-- Users can view their own avatars
CREATE POLICY "Users can view own avatars"
ON avatars FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own avatars
CREATE POLICY "Users can insert own avatars"
ON avatars FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own avatars
CREATE POLICY "Users can update own avatars"
ON avatars FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own avatars
CREATE POLICY "Users can delete own avatars"
ON avatars FOR DELETE
USING (auth.uid() = user_id);

-- Admins can view all avatars
CREATE POLICY "Admins can view all avatars"
ON avatars FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- AVATAR WARDROBES POLICIES (Future)
-- ----------------------------------------------------------------------------

-- Users can view wardrobes for their own avatars
CREATE POLICY "Users can view own wardrobes"
ON avatar_wardrobes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM avatars
    WHERE avatars.id = avatar_wardrobes.avatar_id
    AND avatars.user_id = auth.uid()
  )
);

-- Users can insert wardrobes for their own avatars
CREATE POLICY "Users can insert own wardrobes"
ON avatar_wardrobes FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM avatars
    WHERE avatars.id = avatar_wardrobes.avatar_id
    AND avatars.user_id = auth.uid()
  )
);

-- Users can delete wardrobes for their own avatars
CREATE POLICY "Users can delete own wardrobes"
ON avatar_wardrobes FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM avatars
    WHERE avatars.id = avatar_wardrobes.avatar_id
    AND avatars.user_id = auth.uid()
  )
);

-- ----------------------------------------------------------------------------
-- ENVIRONMENTS POLICIES (Future)
-- ----------------------------------------------------------------------------

-- Users can view their own environments
CREATE POLICY "Users can view own environments"
ON environments FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own environments
CREATE POLICY "Users can insert own environments"
ON environments FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own environments
CREATE POLICY "Users can update own environments"
ON environments FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own environments
CREATE POLICY "Users can delete own environments"
ON environments FOR DELETE
USING (auth.uid() = user_id);

-- Admins can view all environments
CREATE POLICY "Admins can view all environments"
ON environments FOR SELECT
USING (is_admin());

-- ============================================================================
-- SCHEDULED JOBS (pg_cron)
-- ============================================================================

-- Delete expired exports (runs daily at midnight)
-- Note: This requires pg_cron extension
-- Run manually via Supabase dashboard or setup pg_cron

/*
SELECT cron.schedule(
  'delete-expired-exports',
  '0 0 * * *', -- Every day at midnight
  $$
  DELETE FROM exports
  WHERE expires_at < NOW()
  AND status = 'completed';
  $$
);
*/

-- ============================================================================
-- INITIAL DATA SEEDING
-- ============================================================================

-- This will be done via application on first admin login
-- Or manually via Supabase dashboard

-- ============================================================================
-- SCHEMA VERSION
-- ============================================================================

CREATE TABLE schema_version (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO schema_version (version) VALUES ('1.0.0');

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
