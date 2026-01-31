# Debugging n8n Webhook Integration

## Issue: n8n webhook not receiving data when environment is created

---

## Debug Logs Added

I've added comprehensive console logging throughout the flow. When you create an environment, check your browser console for these logs:

### 1. Environment Creation
```
Environment created, sending to n8n... {
  environmentId: "...",
  hasImageUrl: true/false,
  imageUrl: "...",
  n8nEnabled: true/false,
  n8nEndpoint: "..."
}
```

### 2. n8n Tracking Flow
```
[n8n] sendToN8nWithTracking called { ... }
[n8n] Checking for existing job...
[n8n] Creating new job record...
[n8n] Job created: <job_id>
[n8n] Sending to n8n endpoint... {
  url: "...",
  hasToken: true/false,
  jobId: "...",
  imageUrl: "..."
}
```

### 3. HTTP Request
```
[sendToEndpoint] Called with: { ... }
[sendToEndpoint] Sending POST request... {
  url: "...",
  payload: { ... }
}
[sendToEndpoint] Response received: {
  status: 200,
  ok: true,
  statusText: "OK"
}
```

---

## Checklist: Why n8n Might Not Receive Data

### ✅ 1. Check n8n Configuration in Admin Settings

Open browser console and run after creating an environment:
```javascript
// Check if n8n is enabled
console.log('n8n enabled:', n8nConfig.value?.enabled)
console.log('Environments endpoint:', n8nConfig.value?.endpoints?.environments?.url)
console.log('Has API token:', !!n8nConfig.value?.api_token)
```

**Fix:** Go to Admin Settings → n8n Integration and ensure:
- [ ] n8n Integration is **enabled** (checkbox checked)
- [ ] Environments Endpoint URL is filled (e.g., `https://your-n8n.com/webhook/environments`)
- [ ] API Token is filled

### ✅ 2. Check Database Migration

The n8n_jobs table needs the new columns. Run this in Supabase SQL Editor:

```sql
-- Check if columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'n8n_jobs'
  AND column_name IN ('environment_id', 'avatar_id');
```

**Expected result:** Should return 2 rows showing both columns exist.

**Fix:** If columns don't exist, run:
```sql
-- File: database/migrations/003_add_environment_avatar_to_n8n_jobs.sql
```

### ✅ 3. Check Network Tab in Browser DevTools

1. Open browser DevTools (F12)
2. Go to **Network** tab
3. Create an environment
4. Look for a POST request to your n8n webhook URL

**What to check:**
- [ ] Request is sent (you should see the POST request)
- [ ] Request status (200 OK = success, 4xx/5xx = error)
- [ ] Request payload (click on request → Payload tab)
- [ ] Response (click on request → Response tab)

**Common issues:**
- **404 Not Found**: n8n webhook URL is incorrect
- **401 Unauthorized**: API token is wrong or missing
- **CORS error**: n8n needs to allow your frontend domain
- **No request sent**: n8n config not loaded or disabled

### ✅ 4. Verify n8n Webhook is Active

In your n8n workflow:
- [ ] Webhook node is configured
- [ ] Workflow is **activated** (toggle in top-right)
- [ ] Webhook URL matches exactly what's in admin settings
- [ ] Authentication is set to "Header Auth" with correct token

### ✅ 5. Check CORS Settings

If you see CORS errors in console, your n8n instance needs to allow requests from your frontend domain.

**n8n CORS configuration** (in n8n environment variables):
```env
N8N_CORS_ENABLED=true
N8N_CORS_ORIGIN=https://your-frontend-domain.com
```

### ✅ 6. Test the Webhook Manually

Use curl to test if n8n webhook works:

```bash
curl -X POST https://your-n8n.com/webhook/environments \
  -H "Authorization: Bearer your-api-token" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "environment_created",
    "timestamp": "2026-01-23T12:00:00.000Z",
    "user_id": "test-user-id",
    "user_email": "test@example.com",
    "job_id": "test-job-id",
    "image_url": "https://example.com/test.jpg",
    "environment": {
      "id": "test-env-id",
      "name": "Test Environment"
    }
  }'
```

**Expected:** n8n should receive the webhook and execute the workflow.

---

## Payload Structure Sent to n8n

When an environment is created, this JSON payload is sent:

```json
{
  "event": "environment_created",
  "timestamp": "2026-01-23T12:34:56.789Z",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_email": "user@example.com",
  "job_id": "abc123-job-id-xyz789",
  "image_url": "https://...supabase.co/storage/v1/object/public/Environments/user-id/environment_123.jpg",
  "environment": {
    "id": "env-uuid",
    "user_id": "user-uuid",
    "name": "Modern Office",
    "description": "A modern office space",
    "reference_image_url": "https://...supabase.co/.../environment_123.jpg",
    "environment_specs": {
      "category": "interior",
      "lighting_type": "natural",
      "background_color": "#ffffff",
      "ambient_intensity": 70,
      "visual_style": "modern",
      "mood_tone": "professional",
      "wall_color": "#f5f5f5",
      "floor_type": "wood",
      "include_windows": true,
      "include_props": true,
      "room_size": "medium"
    },
    "is_active": true,
    "created_at": "2026-01-23T12:34:56.789Z",
    "updated_at": "2026-01-23T12:34:56.789Z",
    "created_by": "user-uuid",
    "updated_by": "user-uuid"
  }
}
```

---

## n8n Workflow Requirements

Your n8n workflow must:

1. **Receive the webhook** with the payload above
2. **Update job status to 'generating':**
   ```javascript
   // In Supabase node or HTTP Request node
   UPDATE n8n_jobs
   SET status = 'generating',
       n8n_execution_id = '{{ $execution.id }}',
       updated_at = NOW()
   WHERE id = '{{ $json.job_id }}';
   ```

3. **Process the environment** (your AI operations using `$json.image_url`)

4. **On success, update to 'completed':**
   ```javascript
   UPDATE n8n_jobs
   SET status = 'completed',
       completed_at = NOW(),
       updated_at = NOW()
   WHERE id = '{{ $json.job_id }}';
   ```

5. **On failure, update to 'failed':**
   ```javascript
   UPDATE n8n_jobs
   SET status = 'failed',
       error_message = '{{ $json.error }}',
       updated_at = NOW()
   WHERE id = '{{ $json.job_id }}';
   ```

---

## Quick Diagnosis Steps

### Step 1: Check Console Logs
1. Open browser console (F12)
2. Create an environment
3. Look for logs starting with `[n8n]` or `[sendToEndpoint]`

**If you see:**
- `n8n not configured or disabled` → Go to Admin Settings, enable n8n
- `Missing required parameters` → Check API token is set
- `Connection failed - Check URL and CORS settings` → CORS issue or wrong URL
- `Request timeout (15s)` → n8n not responding or slow
- `HTTP 404` → Wrong webhook URL
- `HTTP 401` → Wrong API token

### Step 2: Verify Database
```sql
-- Check if job was created
SELECT * FROM n8n_jobs
WHERE workflow_type = 'environment_creation'
ORDER BY created_at DESC
LIMIT 5;
```

**If jobs exist:** n8n endpoint might not be receiving them (check network tab).
**If no jobs:** Job creation is failing (check console for errors).

### Step 3: Check n8n Workflow Execution
In n8n dashboard:
- Go to **Executions** tab
- Look for recent webhook triggers
- Click on execution to see details

**If no executions:** Webhook not receiving data (CORS, URL, or token issue).
**If executions exist:** n8n is receiving data correctly!

---

## Common Solutions

### Problem: "n8n not configured or disabled"
**Solution:**
1. Go to `/admin/settings`
2. Check "Enable n8n Integration"
3. Fill in Environments Endpoint URL
4. Fill in API Token
5. Click "Save All Settings"

### Problem: CORS Error
**Solution:** Configure n8n to allow your frontend domain:
```env
# In your n8n .env file
N8N_CORS_ENABLED=true
N8N_CORS_ORIGIN=http://localhost:5173,https://your-domain.com
```

### Problem: 404 Not Found
**Solution:**
1. Check webhook URL in admin settings
2. Copy exact webhook URL from n8n workflow
3. Make sure workflow is activated in n8n

### Problem: Jobs created but n8n not updating status
**Solution:**
1. Check n8n workflow has Supabase node or HTTP Request to update n8n_jobs
2. Verify Supabase credentials in n8n
3. Check n8n execution logs for errors

---

## Still Not Working?

Share the following information:

1. **Console logs** (everything starting with `[n8n]` or `[sendToEndpoint]`)
2. **Network tab** screenshot showing the POST request
3. **Admin settings** screenshot (n8n integration section)
4. **n8n workflow** execution screenshot
5. **Database query result:**
   ```sql
   SELECT * FROM n8n_jobs ORDER BY created_at DESC LIMIT 1;
   ```
