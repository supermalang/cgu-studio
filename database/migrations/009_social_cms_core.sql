-- Migration 009: Social CMS Core
-- Version: 2.0.0
-- Date: 2026-08-31
-- Description: Introduces the social content CMS domain — connected accounts,
--              posts, per-channel variants, and media. The existing avatar /
--              environment generation stack becomes the media source for posts.
--              Non-destructive: no existing table is dropped or rewritten.

BEGIN;

-- ============================================================================
-- PART 1: Enums
-- ============================================================================

CREATE TYPE social_platform AS ENUM (
  'instagram',
  'tiktok',
  'linkedin',
  'facebook',
  'x',
  'youtube',
  'threads',
  'pinterest'
);

-- Lifecycle of a post. Applies to the post as a whole and to each channel
-- variant, which can diverge once publishing starts (one channel can fail
-- while the others succeed).
CREATE TYPE post_status AS ENUM (
  'draft',
  'needs_review',
  'approved',
  'scheduled',
  'publishing',
  'published',
  'failed',
  'archived'
);

CREATE TYPE media_kind AS ENUM ('image', 'video');

-- Where a media asset came from, so generated assets stay traceable back to
-- the avatar / environment that produced them.
CREATE TYPE media_source AS ENUM ('upload', 'generated');

-- ============================================================================
-- PART 2: social_accounts — the channels a user publishes to
-- ============================================================================

CREATE TABLE social_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  platform social_platform NOT NULL,
  handle TEXT NOT NULL,                 -- e.g. "@jelika"
  display_name TEXT,
  avatar_url TEXT,

  -- Identity on the remote platform. OAuth tokens are deliberately NOT stored
  -- here: the client reads this table under RLS, so a token column would be
  -- readable by the browser. n8n holds the credentials and is addressed by
  -- this reference.
  external_account_id TEXT,
  credential_ref TEXT,
  token_expires_at TIMESTAMPTZ,

  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  connected_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),

  -- One connection per handle per platform per user
  CONSTRAINT social_accounts_unique_handle UNIQUE (user_id, platform, handle)
);

CREATE INDEX idx_social_accounts_user ON social_accounts(user_id);
CREATE INDEX idx_social_accounts_active ON social_accounts(user_id, is_active);

COMMENT ON TABLE social_accounts IS 'Social channels a user can publish to';
COMMENT ON COLUMN social_accounts.credential_ref IS 'Opaque handle to the credential held by n8n — never the token itself';

-- ============================================================================
-- PART 3: posts — one piece of content, before per-channel tailoring
-- ============================================================================

CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Internal name for the content calendar; not published anywhere.
  title TEXT NOT NULL,
  -- Default caption. A variant may override it per channel.
  body TEXT,
  hashtags TEXT[] NOT NULL DEFAULT '{}',

  status post_status NOT NULL DEFAULT 'draft',

  -- Default publish time. A variant may override it to stagger channels.
  scheduled_for TIMESTAMPTZ,
  published_at TIMESTAMPTZ,

  -- Campaign grouping, reusing the existing projects table.
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,

  -- Generation context: which avatar/environment this content is built around.
  avatar_id UUID REFERENCES avatars(id) ON DELETE SET NULL,
  environment_id UUID REFERENCES environments(id) ON DELETE SET NULL,

  notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),

  -- A scheduled post must say when.
  CONSTRAINT posts_scheduled_needs_time
    CHECK (status <> 'scheduled' OR scheduled_for IS NOT NULL)
);

CREATE INDEX idx_posts_user_status ON posts(user_id, status);
CREATE INDEX idx_posts_scheduled_for ON posts(user_id, scheduled_for);
CREATE INDEX idx_posts_project ON posts(project_id);
CREATE INDEX idx_posts_environment ON posts(environment_id);
CREATE INDEX idx_posts_avatar ON posts(avatar_id);

COMMENT ON TABLE posts IS 'A piece of social content, channel-agnostic';
COMMENT ON COLUMN posts.title IS 'Internal label shown on the calendar, never published';

-- ============================================================================
-- PART 4: post_variants — the per-channel version that actually publishes
-- ============================================================================

CREATE TABLE post_variants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  social_account_id UUID NOT NULL REFERENCES social_accounts(id) ON DELETE CASCADE,

  -- Denormalised for RLS: lets policies check ownership without joining posts.
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- NULL means "inherit from the parent post".
  body_override TEXT,
  hashtags_override TEXT[],
  scheduled_for_override TIMESTAMPTZ,

  status post_status NOT NULL DEFAULT 'draft',

  -- Result of publishing to the remote platform.
  external_post_id TEXT,
  external_url TEXT,
  published_at TIMESTAMPTZ,
  error_message TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT post_variants_unique_channel UNIQUE (post_id, social_account_id),
  CONSTRAINT post_variants_retry_non_negative CHECK (retry_count >= 0)
);

CREATE INDEX idx_post_variants_post ON post_variants(post_id);
CREATE INDEX idx_post_variants_account ON post_variants(social_account_id);
CREATE INDEX idx_post_variants_user_status ON post_variants(user_id, status);

COMMENT ON TABLE post_variants IS 'Per-channel version of a post; overrides fall back to the parent post';
COMMENT ON COLUMN post_variants.user_id IS 'Denormalised owner, so RLS avoids a join to posts';

-- ============================================================================
-- PART 5: post_media — images and video attached to a post
-- ============================================================================

CREATE TABLE post_media (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  kind media_kind NOT NULL DEFAULT 'image',
  source media_source NOT NULL DEFAULT 'upload',

  file_url TEXT NOT NULL,
  storage_path TEXT,
  thumbnail_url TEXT,
  alt_text TEXT,

  width INTEGER,
  height INTEGER,
  duration_seconds NUMERIC(10, 2),
  file_size_bytes BIGINT,

  -- Ordering within the post (carousels).
  position INTEGER NOT NULL DEFAULT 0,

  -- Provenance for generated assets.
  environment_id UUID REFERENCES environments(id) ON DELETE SET NULL,
  avatar_id UUID REFERENCES avatars(id) ON DELETE SET NULL,
  n8n_job_id UUID REFERENCES n8n_jobs(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT post_media_position_non_negative CHECK (position >= 0)
);

CREATE INDEX idx_post_media_post ON post_media(post_id, position);
CREATE INDEX idx_post_media_user ON post_media(user_id);
CREATE INDEX idx_post_media_job ON post_media(n8n_job_id);

COMMENT ON TABLE post_media IS 'Media attached to a post, uploaded or generated from an avatar/environment';

-- ============================================================================
-- PART 6: Link generation jobs back to posts
-- ============================================================================

ALTER TABLE n8n_jobs
ADD COLUMN post_id UUID REFERENCES posts(id) ON DELETE SET NULL;

CREATE INDEX idx_n8n_jobs_post_id ON n8n_jobs(post_id);

COMMENT ON COLUMN n8n_jobs.post_id IS 'Set when the job generates media for a specific post';

-- ============================================================================
-- PART 7: updated_at triggers
-- ============================================================================

-- Reuses update_updated_at_column() defined in schema.sql.
CREATE TRIGGER update_social_accounts_updated_at
  BEFORE UPDATE ON social_accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_post_variants_updated_at
  BEFORE UPDATE ON post_variants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_post_media_updated_at
  BEFORE UPDATE ON post_media
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMIT;

-- ============================================================================
-- PART 8: New workflow types
-- ============================================================================
-- Kept outside the transaction above: an enum value added inside a transaction
-- cannot be used until that transaction commits, and running these separately
-- avoids that trap entirely.

ALTER TYPE workflow_type ADD VALUE IF NOT EXISTS 'post_media_generation';
ALTER TYPE workflow_type ADD VALUE IF NOT EXISTS 'post_caption_generation';
ALTER TYPE workflow_type ADD VALUE IF NOT EXISTS 'post_publish';
