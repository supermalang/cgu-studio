-- Migration 010: Social CMS RLS + calendar RPC
-- Version: 2.0.0
-- Date: 2026-08-31
-- Description: Row Level Security for the social CMS tables, plus the RPC that
--              backs the content calendar. Safe to re-run: policies are dropped
--              first.

BEGIN;

-- ============================================================================
-- PART 1: Enable RLS
-- ============================================================================

ALTER TABLE social_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_variants   ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_media      ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 2: social_accounts
-- ============================================================================

DROP POLICY IF EXISTS "Users manage own social accounts" ON social_accounts;
DROP POLICY IF EXISTS "Service role manages all social accounts" ON social_accounts;

CREATE POLICY "Users manage own social accounts"
ON social_accounts FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- n8n publishes on the user's behalf and refreshes connection metadata.
CREATE POLICY "Service role manages all social accounts"
ON social_accounts FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================================================
-- PART 3: posts
-- ============================================================================

DROP POLICY IF EXISTS "Users manage own posts" ON posts;
DROP POLICY IF EXISTS "Service role manages all posts" ON posts;
DROP POLICY IF EXISTS "Admins can view all posts" ON posts;

CREATE POLICY "Users manage own posts"
ON posts FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- n8n flips status to publishing/published/failed as workflows run.
CREATE POLICY "Service role manages all posts"
ON posts FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Admins can view all posts"
ON posts FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- ============================================================================
-- PART 4: post_variants
-- ============================================================================

DROP POLICY IF EXISTS "Users manage own post variants" ON post_variants;
DROP POLICY IF EXISTS "Service role manages all post variants" ON post_variants;

CREATE POLICY "Users manage own post variants"
ON post_variants FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Service role manages all post variants"
ON post_variants FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================================================
-- PART 5: post_media
-- ============================================================================

DROP POLICY IF EXISTS "Users manage own post media" ON post_media;
DROP POLICY IF EXISTS "Service role manages all post media" ON post_media;

CREATE POLICY "Users manage own post media"
ON post_media FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- n8n attaches generated media once a job finishes.
CREATE POLICY "Service role manages all post media"
ON post_media FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

COMMIT;

-- ============================================================================
-- PART 6: RPC — content calendar
-- ============================================================================

-- Returns every post overlapping a date window, with its channels and media
-- count folded in, so the calendar renders from a single round trip.
CREATE OR REPLACE FUNCTION get_content_calendar(
  range_start TIMESTAMPTZ,
  range_end TIMESTAMPTZ
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  body TEXT,
  status post_status,
  scheduled_for TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  project_id UUID,
  media_count INTEGER,
  channels JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.title,
    p.body,
    p.status,
    p.scheduled_for,
    p.published_at,
    p.project_id,
    (SELECT COUNT(*)::INTEGER FROM post_media m WHERE m.post_id = p.id),
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'variant_id', v.id,
            'account_id', sa.id,
            'platform', sa.platform,
            'handle', sa.handle,
            'status', v.status,
            'scheduled_for', COALESCE(v.scheduled_for_override, p.scheduled_for),
            'external_url', v.external_url,
            'error_message', v.error_message
          )
          ORDER BY sa.platform
        )
        FROM post_variants v
        JOIN social_accounts sa ON sa.id = v.social_account_id
        WHERE v.post_id = p.id
      ),
      '[]'::jsonb
    )
  FROM posts p
  WHERE p.user_id = auth.uid()
    AND p.status <> 'archived'
    AND COALESCE(p.scheduled_for, p.published_at, p.created_at) >= range_start
    AND COALESCE(p.scheduled_for, p.published_at, p.created_at) < range_end
  ORDER BY COALESCE(p.scheduled_for, p.published_at, p.created_at);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_content_calendar(TIMESTAMPTZ, TIMESTAMPTZ) IS 'Posts in a date window with channels and media count, for the calendar view';

-- ============================================================================
-- PART 7: RPC — schedule a post across its channels
-- ============================================================================

-- Sets the publish time and moves the post and every one of its variants to
-- 'scheduled' in one step, so the calendar can never show a post scheduled
-- with some channels left behind in draft.
CREATE OR REPLACE FUNCTION schedule_post(
  target_post_id UUID,
  publish_at TIMESTAMPTZ
)
RETURNS JSONB AS $$
DECLARE
  v_channel_count INTEGER;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM posts WHERE id = target_post_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Post not found or access denied';
  END IF;

  SELECT COUNT(*) INTO v_channel_count
  FROM post_variants WHERE post_id = target_post_id;

  IF v_channel_count = 0 THEN
    RAISE EXCEPTION 'Cannot schedule a post with no channels selected';
  END IF;

  UPDATE posts
  SET status = 'scheduled',
      scheduled_for = publish_at,
      updated_at = NOW(),
      updated_by = auth.uid()
  WHERE id = target_post_id;

  -- Channels already published or mid-publish are left alone.
  UPDATE post_variants
  SET status = 'scheduled',
      updated_at = NOW()
  WHERE post_id = target_post_id
    AND status NOT IN ('published', 'publishing');

  RETURN jsonb_build_object(
    'success', true,
    'post_id', target_post_id,
    'scheduled_for', publish_at,
    'channel_count', v_channel_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION schedule_post(UUID, TIMESTAMPTZ) IS 'Schedules a post and all of its channel variants atomically';

-- ============================================================================
-- PART 8: Grants
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_content_calendar(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION schedule_post(UUID, TIMESTAMPTZ) TO authenticated;
