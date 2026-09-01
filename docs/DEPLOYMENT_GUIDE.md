# Jelika - Deployment Guide

**Target:** Production deployment on DigitalOcean VM  
**Timeline:** Complete by February 14, 2026  
**Solo Developer:** Yes

---

## Pre-Deployment Checklist

- [ ] Domain purchased (jelika.app)
- [ ] DigitalOcean droplet created (4 CPU, 8GB RAM, 100GB SSD, Ubuntu 22.04)
- [ ] Supabase project created
- [ ] Database schema applied
- [ ] GitHub repository created
- [ ] All API keys obtained (ElevenLabs, Veo 3, SendGrid, Wave, Orange Money)

---

## Step 1: Server Setup (30 minutes)

### 1.1 Create DigitalOcean Droplet

```bash
# Specs:
# - 4 CPU cores
# - 8GB RAM
# - 100GB SSD
# - Ubuntu 22.04 LTS
# - Region: Choose closest to target users (West Africa)
```

### 1.2 Initial Server Configuration

```bash
# SSH into server
ssh root@your-server-ip

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose -y

# Create non-root user
adduser jelika
usermod -aG sudo jelika
usermod -aG docker jelika

# Switch to new user
su - jelika
```

### 1.3 Configure Firewall

```bash
# Enable UFW
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw deny from any to any
sudo ufw enable
```

### 1.4 Setup SSH Keys (Disable Password Auth)

```bash
# On local machine, generate key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy to server
ssh-copy-id jelika@your-server-ip

# On server, disable password authentication
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart sshd
```

---

## Step 2: DNS Configuration (15 minutes)

### 2.1 Cloudflare Setup

1. Add domain to Cloudflare
2. Update nameservers at domain registrar
3. Create DNS A records:
   - `app.jelika.app` → Server IP
   - `n8n.jelika.app` → Server IP
   - `jelika.app` → Server IP (marketing site, future)

### 2.2 Verify DNS

```bash
dig app.jelika.app
dig n8n.jelika.app
```

---

## Step 3: Clone Repository & Environment Setup (10 minutes)

```bash
# Clone repository
cd /var/www
sudo git clone https://github.com/your-username/jelika.git
sudo chown -R jelika:jelika jelika
cd jelika

# Create environment file
cd deployment
cp .env.example .env
nano .env  # Fill in all variables
```

### Environment Variables to Fill:

```bash
# Supabase (from Supabase dashboard)
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=

# n8n (generate random secure passwords)
N8N_USER=admin
N8N_PASSWORD=
N8N_API_KEY=

# AI Services (from provider dashboards)
OPENAI_API_KEY=
VEO3_API_KEY=
SENDGRID_API_KEY=

# Payment Providers
WAVE_API_KEY=
ORANGE_MONEY_API_KEY=

# Monitoring
SENTRY_DSN=

# Security (generate random)
REDIS_PASSWORD=
GRAFANA_PASSWORD=
```

---

## Step 4: SSL Certificates (15 minutes)

### 4.1 Initial Certificate Generation

```bash
# Stop any web servers
sudo systemctl stop nginx || true

# Install Certbot
sudo apt install certbot -y

# Generate certificates
sudo certbot certonly --standalone \
  -d app.jelika.app \
  -d n8n.jelika.app \
  --email your-email@example.com \
  --agree-tos

# Certificates saved to:
# /etc/letsencrypt/live/app.jelika.app/fullchain.pem
# /etc/letsencrypt/live/app.jelika.app/privkey.pem
```

### 4.2 Copy Certificates to Deployment

```bash
sudo mkdir -p /var/www/jelika/deployment/ssl
sudo cp /etc/letsencrypt/live/app.jelika.app/fullchain.pem \
   /var/www/jelika/deployment/ssl/
sudo cp /etc/letsencrypt/live/app.jelika.app/privkey.pem \
   /var/www/jelika/deployment/ssl/
sudo chown -R jelika:jelika /var/www/jelika/deployment/ssl
```

---

## Step 5: Build & Deploy (20 minutes)

### 5.1 Build Frontend

```bash
cd /var/www/jelika/frontend
npm install
npm run build
```

### 5.2 Start Docker Containers

```bash
cd /var/www/jelika/deployment
docker-compose up -d
```

### 5.3 Verify Services

```bash
# Check all containers are running
docker-compose ps

# Check logs
docker-compose logs -f vue-app
docker-compose logs -f n8n
docker-compose logs -f nginx

# Test endpoints
curl -I https://app.jelika.app
curl -I https://n8n.jelika.app
```

---

## Step 6: Supabase Setup (20 minutes)

### 6.1 Apply Database Schema

1. Go to Supabase Dashboard
2. Navigate to SQL Editor
3. Paste contents of `database/schema.sql`
4. Execute

### 6.2 Enable Realtime

1. Go to Database → Replication
2. Enable realtime for tables:
   - `shots`
   - `projects`
   - `notifications`

### 6.3 Configure Storage Buckets

1. Go to Storage
2. Create buckets:
   - `user-uploads` (Private, 2MB file limit)
   - `generated-media` (Public, 50MB file limit)
   - `user-assets` (Private, 5MB file limit)

### 6.4 Create Admin User

```sql
-- In Supabase SQL Editor
INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
VALUES (
  'admin@jelika.app',
  crypt('your_admin_password', gen_salt('bf')),
  NOW()
);

-- Set as admin
UPDATE profiles
SET role = 'admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@jelika.app');
```

---

## Step 7: n8n Workflow Setup (30 minutes)

### 7.1 Access n8n Dashboard

```
https://n8n.jelika.app
Login: admin / [your_password_from_.env]
```

### 7.2 Configure Credentials

1. **OpenAI/Anthropic/Google**
   - Settings → Credentials → Add
   - Choose provider
   - Add API key

2. **ElevenLabs**
   - Note: Uses user-provided keys, no global credential needed

3. **Veo 3**
   - Add as HTTP Request credential

4. **SendGrid**
   - Settings → Credentials → SendGrid API
   - Add API key

### 7.3 Import Workflows

1. Import each workflow from `n8n/workflows/` directory
2. Activate all workflows
3. Test each webhook endpoint:

```bash
# Test script breakdown
curl -X POST https://n8n.jelika.app/webhook/script-breakdown \
  -H "X-API-Key: your_n8n_api_key" \
  -H "Content-Type: application/json" \
  -d '{"script": "Test script", "ai_budget_percentage": 80}'
```

---

## Step 8: Monitoring Setup (20 minutes)

### 8.1 Configure Sentry

1. Create Sentry project at sentry.io
2. Copy DSN to `.env`
3. Restart vue-app container:
   ```bash
   docker-compose restart vue-app
   ```

### 8.2 Access Grafana

```
http://your-server-ip:3001
Login: admin / [your_grafana_password]
```

1. Add Loki data source
2. Import dashboard from `deployment/grafana-dashboard.json`

### 8.3 Setup UptimeRobot

1. Go to uptimerobot.com
2. Add monitors:
   - `https://app.jelika.app` (5 min interval)
   - `https://n8n.jelika.app` (5 min interval)

---

## Step 9: Backup Configuration (15 minutes)

### 9.1 Daily Supabase Backups

```bash
# Create backup script
nano /var/www/jelika/scripts/backup-supabase.sh
```

```bash
#!/bin/bash
# Backup Supabase data
DATE=$(date +%Y%m%d)
pg_dump -h db.your-project.supabase.co \
  -U postgres \
  -d postgres \
  > /var/www/jelika/backups/database/backup-$DATE.sql

# Upload to S3
aws s3 cp /var/www/jelika/backups/database/backup-$DATE.sql \
  s3://jelika-backups/database/

# Delete backups older than 30 days
find /var/www/jelika/backups/database/ -type f -mtime +30 -delete
```

### 9.2 Setup Cron Jobs

```bash
crontab -e
```

```cron
# Daily backup at 2 AM
0 2 * * * /var/www/jelika/scripts/backup-supabase.sh

# Weekly n8n workflow backup
0 3 * * 0 /var/www/jelika/scripts/backup-n8n.sh
```

---

## Step 10: Final Testing (30 minutes)

### 10.1 User Flow Testing

1. **Signup:**
   - Go to https://app.jelika.app/signup
   - Create test account
   - Verify email works

2. **Project Creation:**
   - Create new project
   - Paste test script
   - Verify script breakdown works

3. **Generation:**
   - Add ElevenLabs API key in settings
   - Generate audio for one shot
   - Generate video for one shot
   - Verify Realtime updates

4. **Export:**
   - Export project
   - Verify ZIP download works

5. **Payment:**
   - Test Wave/Orange Money webhook (sandbox mode)
   - Verify credits added

### 10.2 Performance Testing

```bash
# Load test with Apache Bench
ab -n 100 -c 10 https://app.jelika.app/
```

---

## Step 11: Go Live Checklist

- [ ] All tests passing
- [ ] SSL certificates valid
- [ ] Backups configured and tested
- [ ] Monitoring active (Sentry, Grafana, UptimeRobot)
- [ ] Error logging working
- [ ] All environment variables set
- [ ] Admin account created
- [ ] Payment webhooks tested
- [ ] Domain DNS propagated
- [ ] Documentation complete

---

## Post-Launch Monitoring (First 24 Hours)

### Monitor These Metrics:

1. **Error Rate**
   - Check Sentry dashboard every hour
   - Alert on >5 errors/hour

2. **Response Times**
   - Check Grafana dashboard
   - Alert on >3s average response time

3. **Docker Health**
   ```bash
   watch -n 60 'docker-compose ps'
   ```

4. **Disk Space**
   ```bash
   df -h  # Should have >20GB free
   ```

5. **Generation Success Rate**
   - Check n8n execution logs
   - Alert on >10% failure rate

---

## Troubleshooting

### Vue App Won't Start

```bash
# Check logs
docker-compose logs vue-app

# Common fixes:
# 1. Missing environment variables
docker-compose down
nano .env
docker-compose up -d

# 2. Build failed
cd ../frontend
npm run build
docker-compose restart vue-app
```

### n8n Workflows Failing

```bash
# Check n8n logs
docker-compose logs n8n

# Common issues:
# 1. Missing API keys
# 2. Webhook URL incorrect
# 3. Credentials not configured
```

### SSL Certificate Issues

```bash
# Renew certificates
sudo certbot renew

# Copy to deployment
sudo cp /etc/letsencrypt/live/app.jelika.app/* \
   /var/www/jelika/deployment/ssl/

# Restart nginx
docker-compose restart nginx
```

---

## Rollback Procedure

If deployment fails:

```bash
# Stop all containers
docker-compose down

# Restore from last working commit
git checkout [last_working_commit]

# Rebuild and restart
docker-compose up -d --build
```

---

## Success Criteria

✅ Users can signup and login  
✅ Projects can be created  
✅ Script breakdown works  
✅ Audio/video generation works  
✅ Export functionality works  
✅ Payments process successfully  
✅ No critical errors in first 24 hours  
✅ Average response time <2 seconds  
✅ Uptime >99.9% in first week

---

**Deployment Complete! 🎉**

Monitor closely for first 48 hours, then establish weekly check-in routine.
