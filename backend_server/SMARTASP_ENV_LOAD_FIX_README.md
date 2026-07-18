# INVESTIGO v4.1.4 SmartASP Env Load Fix

This hotfix fixes the ESM import order issue where database pool was created before .env was loaded on SmartASP.

Upload/overwrite these files from backend_server into the server root:

- package.json
- src/server.mjs
- src/routes/health.mjs

Keep .env in the same folder as package.json with separate DB variables:

DB_HOST=PG8001.site4now.net
DB_PORT=6432
DB_NAME=db_acc28e_invrsti
DB_USER=acc28e_invrsti
DB_PASSWORD=YOUR_DB_PASSWORD
DB_SSL=true
NODE_ENV=production
JWT_SECRET=Investigo_Jwt_Secret_2026_Change_This
ADMIN_SETUP_CODE=Invstg0_Admin_7Qp92LmX_2026
PUBLIC_BASE_URL=http://invrstigo-001-site1.dtempurl.com

Restart Node.js after upload. Test:
http://invrstigo-001-site1.dtempurl.com/api/health/db-debug?code=Invstg0_Admin_7Qp92LmX_2026
