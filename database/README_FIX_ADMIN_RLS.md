# Fix: Infinite Recursion in Admin RLS Policies

## Problem

When logging in as an admin user and navigating to the projects page, you encounter:
```
{code: '42P17', details: null, hint: null, message: 'infinite recursion detected in policy for relation "profiles"'}
```

This happens because the admin RLS policies query the `profiles` table to check if the user is an admin, which triggers RLS policies on the `profiles` table itself, causing infinite recursion.

## Solution

We've created a `SECURITY DEFINER` function called `is_admin()` that bypasses RLS to safely check if the current user is an admin. All admin policies now use this function instead of querying the profiles table directly.

## How to Apply the Fix

### Option 1: Run the Migration Script (Recommended)

1. **Open Supabase Dashboard**
   - Go to your project dashboard at https://app.supabase.com

2. **Navigate to SQL Editor**
   - Click on "SQL Editor" in the left sidebar

3. **Copy and Run the Migration**
   - Open the file: `database/fix_admin_rls_recursion.sql`
   - Copy the entire contents
   - Paste it into a new query in the SQL Editor
   - Click "Run" to execute

4. **Verify the Fix**
   - The script will output the result of `SELECT is_admin()`
   - If you're logged in as an admin, it should return `true`
   - If you're logged in as a regular user, it should return `false`

### Option 2: Apply to Fresh Database

If you're setting up a new database, you can use the updated `schema.sql` file:

1. **Delete Existing Schema** (if any)
   - ⚠️ Warning: This will delete all data!
   - Only do this for development/testing databases

2. **Run Updated Schema**
   - Navigate to SQL Editor in Supabase Dashboard
   - Copy the entire contents of `database/schema.sql`
   - Paste and run in the SQL Editor

## Testing the Fix

After applying the migration:

1. **Login as Admin**
   - Use an account with `role = 'admin'` in the profiles table

2. **Navigate to Projects Page**
   - Go to `/projects` in your application
   - The page should load without errors

3. **Verify Admin Access**
   - You should be able to see all projects (not just your own)
   - The infinite recursion error should be gone

4. **Test Regular User** (optional)
   - Login with a regular user account
   - Navigate to `/projects`
   - Verify they can only see their own projects

## What Changed

### New Function
```sql
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$;
```

### Updated Policies
All admin policies now use `is_admin()` instead of:
```sql
EXISTS (
  SELECT 1 FROM profiles
  WHERE id = auth.uid() AND role = 'admin'
)
```

**Before:**
```sql
CREATE POLICY "Admins can view all projects"
ON projects FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);
```

**After:**
```sql
CREATE POLICY "Admins can view all projects"
ON projects FOR SELECT
USING (is_admin());
```

## Files Modified

1. ✅ `database/fix_admin_rls_recursion.sql` - Migration script (NEW)
2. ✅ `database/schema.sql` - Updated with is_admin() function and fixed policies
3. ✅ `database/README_FIX_ADMIN_RLS.md` - This file (NEW)

## Troubleshooting

### Issue: "function is_admin() does not exist"
**Solution:** Make sure you ran the migration script completely. The function must be created before the policies.

### Issue: Still getting infinite recursion
**Solution:**
1. Verify the migration script ran successfully
2. Check that all admin policies were recreated with `is_admin()`
3. Try logging out and back in
4. Clear your browser cache

### Issue: Admin can't see other users' data
**Solution:**
1. Verify your user's role is 'admin' in the profiles table:
   ```sql
   SELECT id, full_name, role FROM profiles WHERE id = auth.uid();
   ```
2. If role is not 'admin', update it:
   ```sql
   UPDATE profiles SET role = 'admin' WHERE id = auth.uid();
   ```

## Need Help?

If you continue experiencing issues:
1. Check the Supabase logs for detailed error messages
2. Verify all policies were updated by running:
   ```sql
   SELECT tablename, policyname, permissive, roles, cmd, qual
   FROM pg_policies
   WHERE schemaname = 'public'
   ORDER BY tablename, policyname;
   ```
3. Make sure your database user has the necessary permissions

## Support

For additional support or questions about this fix, please refer to:
- Supabase RLS documentation: https://supabase.com/docs/guides/auth/row-level-security
- PostgreSQL RLS policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
