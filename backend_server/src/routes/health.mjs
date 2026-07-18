import { Router } from 'express';
import { checkDatabase, getSafeDbDebug } from '../db/pool.mjs';

const router = Router();

router.get('/', async (_req, res) => {
  const db = await checkDatabase();
  res.json({
    status: 'ok',
    service: 'INVESTIGO Backend',
    version: '4.2.0',
    database: db.ok ? 'ok' : 'error',
    database_error: db.ok ? undefined : db.code,
    time: new Date().toISOString()
  });
});

router.get('/db-debug', async (req, res) => {
  const supplied = String(req.query.code || req.headers['x-setup-code'] || '');
  const expected = String(process.env.ADMIN_SETUP_CODE || '');

  if (!expected || supplied !== expected) {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Add ?code=YOUR_ADMIN_SETUP_CODE to view safe DB diagnostics.'
    });
  }

  const db = await checkDatabase();
  res.json({
    status: 'ok',
    service: 'INVESTIGO Backend',
    version: '4.2.0',
    database: db.ok ? 'ok' : 'error',
    db_debug: getSafeDbDebug(),
    db_error: db.ok ? null : { code: db.code, message: db.message },
    time: new Date().toISOString()
  });
});

export default router;
