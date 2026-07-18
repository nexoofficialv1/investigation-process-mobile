# INVESTIGO v4.1.3 SmartASP DB Separate ENV Fix

This hotfix allows database connection using separate environment variables, avoiding DATABASE_URL parsing problems on SmartASP/File Manager.

Upload/overwrite these files from `backend_server` into your SmartASP website root:

- `package.json`
- `src/db/pool.mjs`
- `src/routes/health.mjs`
- `.env.example` optional

Do not upload the `backend_server` folder itself if your root already contains `package.json`, `src/`, `web.config`.

Recommended `.env` format:

```env
DB_HOST=PG8001.site4now.net
DB_PORT=6432
DB_NAME=db_acc28e_invrsti
DB_USER=acc28e_invrsti
DB_PASSWORD=YOUR_SIMPLE_PASSWORD
DB_SSL=true
NODE_ENV=production
JWT_SECRET=Investigo_Jwt_Secret_2026_Change_This
ADMIN_SETUP_CODE=Invstg0_Admin_7Qp92LmX_2026
PUBLIC_BASE_URL=http://invrstigo-001-site1.dtempurl.com
```

Avoid `#`, `@`, `:`, `/`, `%`, `&`, `?` in DB_PASSWORD. If your password contains `#`, either change it or put it in quotes as `DB_PASSWORD="Bappa#1984"`.

Restart Node.js app after upload. Test:

- `/api/health`
- `/api/health/db-debug?code=YOUR_ADMIN_SETUP_CODE`

Debug should show:

- `connectionMode: "SEPARATE_ENV"`
- `host: "PG8001.site4now.net"`
- `database: "db_acc28e_invrsti"`
- `username: "acc28e_invrsti"`
- `hasPassword: true`
