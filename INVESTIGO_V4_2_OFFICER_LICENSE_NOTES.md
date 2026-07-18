# INVESTIGO v4.2 Officer Login + License Activation

This patch adds the app-side and backend-side officer/license workflow.

## Mobile app additions
- Backend Server Setup now has an Officer Login & License card.
- License dashboard opens server login/license screen instead of only local license.
- Officer can register with private setup code.
- Officer can login with mobile/email + password.
- JWT token is saved automatically in backend settings.
- License status can be checked from backend.
- Activation code can be applied.
- Admin/owner can grant license to an officer mobile from the app using the private setup code.
- Sync is enabled automatically when trial/active license is confirmed.

## Backend additions
- `/api/license/admin/grant` creates active license for an officer mobile using `x-admin-setup-code`.
- `/api/license/activate-manual` activates a granted code for the logged-in officer.
- Backend version updated to 4.2.0.

## SmartASP reminders
Keep `.env` in the server root with separate DB variables:

```env
DB_HOST=PG8001.site4now.net
DB_PORT=6432
DB_NAME=db_acc28e_invrsti
DB_USER=acc28e_invrsti
DB_PASSWORD=YOUR_DB_PASSWORD
DB_SSL=true
NODE_ENV=production
JWT_SECRET=CHANGE_THIS_LONG_SECRET
ADMIN_SETUP_CODE=CHANGE_THIS_PRIVATE_SETUP_CODE
PUBLIC_BASE_URL=http://invrstigo-001-site1.dtempurl.com
```

Restart Node.js after upload.
