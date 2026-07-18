# INVESTIGO Backend Server — SmartASP/SmarterASP Deployment

## 1. Server requirements

- Node.js 18+
- PostgreSQL database
- HTTPS enabled domain/subdomain

Suggested subdomain:

```text
https://api.investigo.yourdomain.com
```

## 2. Upload files

Upload the full `backend_server` folder contents to your SmartASP app root.

Important files:

```text
package.json
src/server.mjs
web.config
.env
migrations/001_init.sql
```

## 3. Environment

Copy `.env.example` to `.env` and update:

```text
DATABASE_URL=postgres://user:password@host:5432/dbname
JWT_SECRET=long_random_secret
ADMIN_SETUP_CODE=your_private_setup_code
PUBLIC_BASE_URL=https://api.yourdomain.com
```

## 4. Install packages

SmartASP panel / terminal:

```bash
npm install --production
```

## 5. Database migration

```bash
npm run db:migrate
```

If terminal is not available, run `migrations/001_init.sql` from PostgreSQL query tool.

## 6. Create first admin/officer

```bash
node src/scripts/create_admin_officer.mjs "Bappa Roy" "9000000000" "StrongPassword" "Kalna PS" "Purba Bardhaman"
```

## 7. Test

Open:

```text
https://api.yourdomain.com/api/health
```

Expected response:

```json
{
  "status": "ok",
  "service": "INVESTIGO Backend",
  "database": "ok"
}
```

## 8. Mobile app setting

App → Settings → Backend Server:

```text
Backend Mode: Custom Server + PostgreSQL
API Base URL: https://api.yourdomain.com
Mobile: officer mobile
Password: officer password
Test Connection
Login
```

## Notes

- AI/OCR is disabled by default. Enable later by setting AI/OCR keys in `.env`.
- API key must stay server-side only.
- Mobile app should never contain OpenAI/Google OCR keys.
