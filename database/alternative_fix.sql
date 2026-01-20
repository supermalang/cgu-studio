-- ============================================================================
-- ALTERNATIVE FIX: Manual Profile Creation
-- If the trigger still doesn't work, use this approach
-- ============================================================================

-- Option 1: Drop the trigger entirely and create profiles manually
-- This is actually recommended for Supabase

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Instead, we'll create profiles from the client-side after signup
-- The auth store in Vue will handle this

-- ============================================================================
-- Option 2: Use Supabase Database Webhooks (Recommended)
-- ============================================================================

-- Go to Supabase Dashboard > Database > Webhooks
-- Create a new webhook with these settings:
--
-- Name: create_profile_on_signup
-- Table: auth.users
-- Events: INSERT
-- Type: HTTP Request
-- HTTP Request: POST to your application endpoint
--
-- Then handle profile creation in your application

-- ============================================================================
-- Option 3: Simplified Trigger with Better Error Handling
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if profile already exists
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = NEW.id) THEN
    RETURN NEW;
  END IF;

  -- Insert new profile
  INSERT INTO public.profiles (
    id,
    full_name,
    created_by,
    updated_by
  )
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1),
      'User'
    ),
    NEW.id,
    NEW.id
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the auth
    RAISE WARNING 'Could not create profile for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- Verify the setup
-- ============================================================================

-- Check if function exists
SELECT
  p.proname as function_name,
  pg_get_functiondef(p.oid) as definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'handle_new_user';

-- Check if trigger exists
SELECT
  t.tgname as trigger_name,
  c.relname as table_name,
  n.nspname as schema_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE t.tgname = 'on_auth_user_created';
