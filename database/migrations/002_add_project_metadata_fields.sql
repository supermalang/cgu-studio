-- ============================================================================
-- DATABASE MIGRATION: Add Project Metadata Fields
-- Version: 002
-- Date: 2026-01-22
-- Description: Adds new fields to projects table for enhanced video configuration:
--              - Target platform (TikTok, Instagram, etc.)
--              - Target video and clip lengths
--              - Visual style and mood/tone
--              - Background music preferences
-- ============================================================================

-- ============================================================================
-- CREATE NEW ENUM TYPES
-- ============================================================================

-- Target platform enum for social media optimization
CREATE TYPE target_platform AS ENUM (
  'tiktok',
  'instagram_reels',
  'youtube_shorts',
  'facebook',
  'linkedin'
);

-- Visual style enum for creative direction
CREATE TYPE visual_style AS ENUM (
  'professional',
  'casual',
  'cinematic',
  'documentary',
  'educational'
);

-- Mood/tone enum for emotional direction
CREATE TYPE mood_tone AS ENUM (
  'energetic',
  'calm',
  'serious',
  'playful',
  'inspiring'
);

-- ============================================================================
-- ALTER PROJECTS TABLE - ADD NEW COLUMNS
-- ============================================================================

ALTER TABLE projects
-- Platform targeting
ADD COLUMN target_platform target_platform,

-- Video length specifications
ADD COLUMN target_video_length INTEGER,
ADD COLUMN individual_clip_length_min INTEGER DEFAULT 2,
ADD COLUMN individual_clip_length_max INTEGER DEFAULT 8,

-- Creative direction
ADD COLUMN visual_style visual_style,
ADD COLUMN mood_tone mood_tone,

-- Audio preferences
ADD COLUMN background_music_enabled BOOLEAN NOT NULL DEFAULT false;

-- ============================================================================
-- ADD CONSTRAINTS
-- ============================================================================

-- Ensure video length is positive if specified
ALTER TABLE projects
ADD CONSTRAINT ck_video_length_positive
  CHECK (target_video_length IS NULL OR target_video_length > 0);

-- Ensure clip length range is valid (2-60 seconds, min <= max)
ALTER TABLE projects
ADD CONSTRAINT ck_clip_length_range CHECK (
  individual_clip_length_min >= 2 AND
  individual_clip_length_max <= 60 AND
  individual_clip_length_min <= individual_clip_length_max
);

-- ============================================================================
-- ADD COLUMN COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON COLUMN projects.target_platform IS 'Target social media platform for optimization (TikTok, Instagram Reels, YouTube Shorts, Facebook, LinkedIn)';
COMMENT ON COLUMN projects.target_video_length IS 'Desired total video length in seconds';
COMMENT ON COLUMN projects.individual_clip_length_min IS 'Minimum individual clip duration (2-60 seconds)';
COMMENT ON COLUMN projects.individual_clip_length_max IS 'Maximum individual clip duration (2-60 seconds)';
COMMENT ON COLUMN projects.visual_style IS 'Overall visual style/aesthetic (Professional, Casual, Cinematic, Documentary, Educational)';
COMMENT ON COLUMN projects.mood_tone IS 'Emotional tone/mood to convey (Energetic, Calm, Serious, Playful, Inspiring)';
COMMENT ON COLUMN projects.background_music_enabled IS 'Whether background music should be included in the final video';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
