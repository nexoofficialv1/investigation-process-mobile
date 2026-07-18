import { Router } from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { query } from '../db/pool.mjs';

const router = Router();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function requireSetupCode(req, res, next) {
  const supplied = String(req.query.code || req.headers['x-setup-code'] || req.body?.setup_code || '');
  const expected = String(process.env.ADMIN_SETUP_CODE || '');
  if (!expected || supplied !== expected) {
    return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Invalid setup code.' });
  }
  next();
}

router.get('/migrate', requireSetupCode, async (_req, res) => {
  try {
    const migrationPath = path.join(__dirname, '..', '..', 'migrations', '001_init.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');
    await query(sql);
    res.json({ status: 'ok', message: 'Database migration completed.', migration: '001_init.sql' });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      error: error.code || error.name || 'MIGRATION_ERROR',
      message: error.message || 'Migration failed'
    });
  }
});

export default router;
