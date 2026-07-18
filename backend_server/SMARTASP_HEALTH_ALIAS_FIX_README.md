# INVESTIGO Backend v4.1.5 - SmartASP Health Alias Fix

This hotfix adds `/health` as an alias of `/api/health` so older APKs or SmartASP rewrite paths such as `/src/server.mjs?originalPath=health` return the same health JSON instead of 404.

Upload to hosting root: `src/app.mjs`, `src/routes/health.mjs`, and `package.json`, then restart Node.js.

Test URLs:
- http://invrstigo-001-site1.dtempurl.com/health
- http://invrstigo-001-site1.dtempurl.com/api/health

Both should return `database: ok`.
