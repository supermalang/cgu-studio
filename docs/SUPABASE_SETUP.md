# Supabase Setup & Troubleshooting Guide

Complete guide for setting up UCG Studio with Supabase, including common issues and solutions.

---

## 🚀 Initial Setup

### Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click "New Project"
3. Fill in:
   - **Name:** UCG Studio
   - **Database Password:** (save this securely)
   - **Region:** Choose closest to your users
4. Wait 2-3 minutes for provisioning

### Step 2: Run Database Schema

1. In Supabase Dashboard, go to **SQL Editor**
2. Copy entire contents of `database/schema.sql`
3. Paste into SQL Editor
4. Click **Run** (bottom right)
5. Wait for "Success" message

**Expected Output:**
```
Success. No rows returned
```

### Step 3: Enable Realtime

1. Go to **Database > Replication**
2. Enable realtime for these tables:
   - ✅ `profiles`
   - ✅ `projects`
   - ✅ `shots`
   - ✅ `notifications`

### Step 4: Get API Keys

1. Go to **Settings > API**
2. Copy these values:
   - **Project URL:** `https://xxxxx.supabase.co`
   - **anon public key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
3. Save to `frontend/.env.local`

### Step 5: Configure Authentication

1. Go to **Authentication > Providers**
2. **Email** should be enabled by default
3. For **Google OAuth** (optional):
   - Enable Google provider
   - Add Google Client ID/Secret
   - Add redirect URL: `https://your-domain.com/auth/callback`

---

## 🐛 Common Issues & Solutions

### Issue 1: "relation 'profiles' does not exist"

**Symptoms:**
- Error when creating user in Authentication tab
- Signup fails with database error

**Cause:** The auth trigger isn't working properly or permissions are missing.

**Solution A: Fix the Trigger (Recommended)**

Run this in SQL Editor:

```sql
-- Drop existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Recreate with proper permissions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, created_by, updated_by)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.id,
    NEW.id
  );
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Could not create profile for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, service_role;
```

**Solution B: Client-Side Creation (Fallback)**

The auth store has been updated to create profiles manually. This works even if the trigger fails.

**Verify Fix:**

1. Go to **Authentication > Users**
2. Click "Add user" (manual)
3. Enter email/password
4. Check **Database > profiles** table
5. You should see the profile created

---

### Issue 2: RLS Policies Blocking Queries

**Symptoms:**
- "new row violates row-level security policy"
- Can't insert/update/delete data

**Solution:**

Check that you're authenticated:

```javascript
// In browser console
const { data: { user } } = await supabase.auth.getUser()
console.log('Current user:', user)
```

If null, log in first. RLS policies require `auth.uid()` to exist.

**For Testing Only:**

Temporarily disable RLS on a table:

```sql
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
```

**Re-enable after testing:**

```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
```

---

### Issue 3: Trigger Not Firing

**Check if trigger exists:**

```sql
SELECT
  t.tgname as trigger_name,
  c.relname as table_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE t.tgname = 'on_auth_user_created';
```

**Check function:**

```sql
SELECT proname, prosrc
FROM pg_proc
WHERE proname = 'handle_new_user';
```

**Manually test the function:**

```sql
-- Create a test user in auth.users
-- Then check if profile was created
SELECT * FROM public.profiles WHERE id = 'test-user-id';
```

---

### Issue 4: Permission Denied Errors

**Symptoms:**
- "permission denied for table profiles"
- "must be owner of table"

**Solution:**

Run permission grants:

```sql
-- Grant permissions to authenticated users
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant to service role (for triggers)
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
```

---

### Issue 5: Function Not Found in Search Path

**Symptoms:**
- "function public.handle_new_user() does not exist"

**Solution:**

Set explicit search path:

```sql
ALTER FUNCTION public.handle_new_user()
SET search_path = public;
```

---

## ✅ Verification Checklist

After setup, verify everything works:

### Database Schema
- [ ] Run `SELECT * FROM schema_version;` → Returns `1.0.0`
- [ ] Run `SELECT * FROM admin_settings;` → Returns 1 row
- [ ] All tables exist (check **Database > Tables**)

### Authentication
- [ ] Create test user in **Authentication > Users**
- [ ] Check **Database > profiles** → Profile exists
- [ ] No errors in logs

### RLS Policies
- [ ] Go to **Database > Tables > profiles > Policies**
- [ ] Should see 4 policies enabled

### Realtime
- [ ] **Database > Replication**
- [ ] Tables `profiles`, `projects`, `shots`, `notifications` enabled

### API Keys
- [ ] **Settings > API** → Copy URL and keys
- [ ] Paste into `frontend/.env.local`
- [ ] Keys not exposed in git (in `.gitignore`)

---

## 🔧 Manual Profile Creation

If triggers completely fail, create profiles manually:

### Option 1: SQL Function

```sql
-- Call this after user signup
INSERT INTO public.profiles (id, full_name, created_by, updated_by)
SELECT
  id,
  COALESCE(raw_user_meta_data->>'full_name', 'User'),
  id,
  id
FROM auth.users
WHERE id = 'USER_ID_HERE';
```

### Option 2: Client-Side (Already Implemented)

The auth store automatically creates profiles if the trigger fails:

```javascript
// This is already in src/stores/auth.js
async function signUp(email, password, fullName) {
  const { data, error } = await supabase.auth.signUp({ ... })

  // Fallback: Create profile manually
  if (data.user) {
    await supabase.from('profiles').insert({
      id: data.user.id,
      full_name: fullName,
      created_by: data.user.id,
      updated_by: data.user.id
    })
  }
}
```

---

## 🚨 Emergency: Reset Everything

If something goes wrong and you need to start fresh:

### 1. Drop All Tables

```sql
-- WARNING: This deletes ALL data!
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

### 2. Re-run Schema

- Copy `database/schema.sql`
- Paste into SQL Editor
- Run

### 3. Re-run Fix

- Copy `database/fix_auth_trigger.sql`
- Paste into SQL Editor
- Run

---

## 📊 Monitoring & Debugging

### View Auth Users

```sql
SELECT
  id,
  email,
  created_at,
  raw_user_meta_data->>'full_name' as full_name
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;
```

### View Profiles

```sql
SELECT
  p.id,
  p.full_name,
  p.credit_balance,
  p.role,
  p.status,
  u.email
FROM public.profiles p
JOIN auth.users u ON p.id = u.id
ORDER BY p.created_at DESC
LIMIT 10;
```

### Find Orphaned Users (No Profile)

```sql
SELECT
  u.id,
  u.email,
  u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;
```

### Create Missing Profiles

```sql
INSERT INTO public.profiles (id, full_name, created_by, updated_by)
SELECT
  u.id,
  COALESCE(u.raw_user_meta_data->>'full_name', 'User'),
  u.id,
  u.id
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;
```

---

## 🎯 Testing Signup Flow

### 1. From Dashboard

1. Go to **Authentication > Users**
2. Click "Add user"
3. Enter email: `test@example.com`
4. Enter password: `test123456`
5. Click "Create user"
6. Check **Database > profiles** → Profile should exist

### 2. From Application

1. Start frontend: `npm run dev`
2. Go to `http://localhost:5173/auth/signup`
3. Fill in form:
   - Full Name: John Doe
   - Email: john@example.com
   - Password: password123
4. Click "Sign up"
5. Should redirect to dashboard
6. Check Supabase **Database > profiles** → Profile exists

### 3. Expected Database State

**auth.users:**
```
id                                   | email              | created_at
-------------------------------------|--------------------|-----------
550e8400-e29b-41d4-a716-446655440000 | test@example.com   | 2026-01-20
```

**public.profiles:**
```
id                                   | full_name | credit_balance | role | status
-------------------------------------|-----------|----------------|------|--------
550e8400-e29b-41d4-a716-446655440000 | User      | 0              | user | active
```

---

## 📝 Best Practices

### 1. Always Use Triggers

Database triggers ensure profiles are created automatically and consistently.

### 2. Add Fallback Logic

Client-side fallback (already implemented) handles edge cases.

### 3. Monitor Logs

Check **Database > Logs** for errors:
```sql
SELECT * FROM postgres_logs
WHERE level = 'error'
ORDER BY timestamp DESC
LIMIT 20;
```

### 4. Test in Development

Always test signup flow in development before deploying.

### 5. Use RLS Policies

Never disable RLS in production. It's your security layer.

---

## 🔐 Security Checklist

- [ ] RLS enabled on all tables
- [ ] Policies tested and working
- [ ] API keys in `.env.local` (not committed)
- [ ] Service role key never exposed client-side
- [ ] Triggers use `SECURITY DEFINER` properly
- [ ] No public schema grants to `anon` role

---

## 📚 Additional Resources

- [Supabase Docs - Auth](https://supabase.com/docs/guides/auth)
- [Supabase Docs - RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase Docs - Triggers](https://supabase.com/docs/guides/database/postgres/triggers)
- [PostgreSQL Triggers](https://www.postgresql.org/docs/current/triggers.html)

---

## 🆘 Still Having Issues?

### 1. Check Supabase Status
Visit [status.supabase.com](https://status.supabase.com)

### 2. View Logs
Go to **Database > Logs** in Supabase Dashboard

### 3. Test Connection
```javascript
// In browser console
const { data, error } = await supabase.from('profiles').select('count')
console.log('Connection test:', data, error)
```

### 4. Contact Support
- Supabase Discord: [discord.supabase.com](https://discord.supabase.com)
- GitHub Issues: [github.com/supabase/supabase](https://github.com/supabase/supabase)

---

**Last Updated:** January 20, 2026
**Schema Version:** 1.0.0
**Status:** Production Ready ✅
