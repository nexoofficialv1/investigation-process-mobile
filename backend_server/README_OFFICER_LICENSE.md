# INVESTIGO Backend v4.2 Officer + License

## App flow
1. `/api/auth/register` with `x-admin-setup-code` creates first/admin officer.
2. `/api/auth/login` returns JWT token.
3. `/api/license/status` returns active/trial license for logged-in officer.
4. `/api/license/admin/grant` grants/creates a license for an officer mobile using setup code.
5. `/api/license/activate-manual` activates an already-granted activation code for the logged-in officer.

After deploying this backend, keep `.env` in the SmartASP root:

```env
DB_HOST=PG8001.site4now.net
DB_PORT=6432
DB_NAME=db_acc28e_invrsti
DB_USER=acc28e_invrsti
DB_PASSWORD=YOUR_DB_PASSWORD
DB_SSL=true
NODE_ENV=production
JWT_SECRET=CHANGE_THIS_LONG_RANDOM_SECRET
ADMIN_SETUP_CODE=CHANGE_THIS_PRIVATE_SETUP_CODE
PUBLIC_BASE_URL=http://invrstigo-001-site1.dtempurl.com
```

Restart Node.js after upload.
