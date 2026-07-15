# v3.0 Backup, Backend Sync, License Fees Patch

Added:
- Backup & Sync screen for local JSON backup/share/restore.
- Backend screen link for adding Custom Server + PostgreSQL API URL/token and sync.
- License & Fees screen for manual plan/fee/UPI/transaction/activation-code record.
- Dashboard cards: Backup, Backend, License.
- Backend PostgreSQL schema additions: licenses, backup_logs.
- Backend API additions: license request/status endpoints.

Notes:
- App remains offline-first.
- Server/database can be added later manually from Backend Setup.
- Backup is local JSON share/export now; server backup/upload can be connected after backend is deployed.
- License fees are local/manual first. Server-side verification/payment gateway can be added later.
