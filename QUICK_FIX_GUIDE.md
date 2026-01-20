# 🚨 Quick Fix: "relation 'profiles' does not exist"

**Problem:** Error when creating users in Supabase Authentication.

---

## ✅ Solution (3 Steps)

### Step 1: Run Fix SQL

1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Copy & paste this code:

```sql
-- Fix auth trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

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

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

GRANT USAGE ON SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, service_role;
```

4. Click **Run** (bottom right)
5. Wait for "Success" message

---

### Step 2: Test It

1. Go to **Authentication > Users**
2. Click **"Add user"**
3. Enter:
   - Email: `test@example.com`
   - Password: `test123456`
4. Click **"Create user"**
5. Go to **Database > profiles** table
6. **Verify:** You should see the new profile!

---

### Step 3: Fix Orphaned Users (If Any)

If you created users before fixing the trigger, run this:

```sql
-- Find users without profiles
SELECT u.id, u.email
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Create missing profiles
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

## ✅ Done!

Your signup should now work. The auth store also has a **fallback** that creates profiles client-side if the trigger fails.

---

## 📖 Full Documentation

For more details, see:
- **[docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)** - Complete setup guide
- **[database/fix_auth_trigger.sql](database/fix_auth_trigger.sql)** - SQL fix file
- **[database/alternative_fix.sql](database/alternative_fix.sql)** - Alternative solutions

---

## 🆘 Still Not Working?

### Check Permissions

```sql
-- Grant all necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
```

### Verify Trigger Exists

```sql
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
```

Should return 1 row. If not, re-run Step 1.

### Check Logs

Go to **Database > Logs** and look for errors mentioning "profiles" or "handle_new_user".

---

**That's it! You're ready to go.** 🚀
