import { Router } from 'express';
import { query } from '../db/pool.mjs';
import { requireAuth } from '../middleware/auth.mjs';

const router = Router();

function cleanLicense(row) {
  if (!row) return null;
  return {
    id: row.id,
    plan_name: row.plan_name,
    activation_code: row.activation_code,
    payment_ref: row.payment_ref,
    status: row.status,
    starts_at: row.starts_at,
    expires_at: row.expires_at,
    allowed_devices: row.allowed_devices,
    ai_quota_monthly: row.ai_quota_monthly,
    ocr_quota_monthly: row.ocr_quota_monthly,
    created_at: row.created_at,
    updated_at: row.updated_at
  };
}

router.get('/status', requireAuth, async (req, res) => {
  const { rows } = await query(
    `select id, plan_name, activation_code, payment_ref, status, starts_at, expires_at,
            allowed_devices, ai_quota_monthly, ocr_quota_monthly, created_at, updated_at
     from licenses where officer_id=$1 order by created_at desc limit 1`,
    [req.user.officer_id]
  );
  const license = cleanLicense(rows[0]) || {
    plan_name: 'Offline Trial',
    status: 'trial',
    starts_at: null,
    expires_at: null,
    allowed_devices: 1,
    ai_quota_monthly: 0,
    ocr_quota_monthly: 0
  };
  res.json({ license, server_time: new Date().toISOString() });
});

router.post('/activate-manual', requireAuth, async (req, res) => {
  const { activation_code } = req.body || {};
  const code = String(activation_code || '').trim();
  if (!code) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Activation code required' });

  const { rows } = await query(
    `update licenses
       set status='active',
           starts_at=coalesce(starts_at, now()),
           expires_at=coalesce(expires_at, now() + interval '1 year'),
           updated_at=now()
     where officer_id=$1 and activation_code=$2
     returning id, plan_name, activation_code, payment_ref, status, starts_at, expires_at,
               allowed_devices, ai_quota_monthly, ocr_quota_monthly, created_at, updated_at`,
    [req.user.officer_id, code]
  );
  if (!rows[0]) return res.status(404).json({ error: 'NOT_FOUND', message: 'Activation code not found for this officer' });
  res.json({ license: cleanLicense(rows[0]), server_time: new Date().toISOString() });
});

router.post('/admin/grant', async (req, res) => {
  const setupCode = req.headers['x-admin-setup-code'];
  if (setupCode !== process.env.ADMIN_SETUP_CODE) {
    return res.status(403).json({ error: 'FORBIDDEN', message: 'Invalid setup code' });
  }

  const {
    officer_id,
    officer_mobile,
    plan_name = 'Pro Sync',
    activation_code,
    payment_ref = 'MANUAL',
    days = 365,
    allowed_devices = 1,
    ai_quota_monthly = 0,
    ocr_quota_monthly = 0,
    status = 'active'
  } = req.body || {};

  if (!officer_id && !officer_mobile) {
    return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'officer_id or officer_mobile required' });
  }

  const officerResult = officer_id
    ? await query(`select id, name, mobile from officers where id=$1 limit 1`, [officer_id])
    : await query(`select id, name, mobile from officers where mobile=$1 limit 1`, [String(officer_mobile).trim()]);
  const officer = officerResult.rows[0];
  if (!officer) return res.status(404).json({ error: 'NOT_FOUND', message: 'Officer not found' });

  const finalCode = String(activation_code || `INVESTIGO-${Date.now()}`).trim();
  const validDays = Math.max(1, Math.min(3650, Number(days) || 365));
  const { rows } = await query(
    `insert into licenses
       (officer_id, plan_name, activation_code, payment_ref, status, starts_at, expires_at,
        allowed_devices, ai_quota_monthly, ocr_quota_monthly)
     values ($1,$2,$3,$4,$5,now(),now() + ($6::int * interval '1 day'),$7,$8,$9)
     returning id, plan_name, activation_code, payment_ref, status, starts_at, expires_at,
               allowed_devices, ai_quota_monthly, ocr_quota_monthly, created_at, updated_at`,
    [
      officer.id,
      String(plan_name || 'Pro Sync'),
      finalCode,
      String(payment_ref || 'MANUAL'),
      String(status || 'active'),
      validDays,
      Number(allowed_devices) || 1,
      Number(ai_quota_monthly) || 0,
      Number(ocr_quota_monthly) || 0
    ]
  );

  res.status(201).json({ officer, license: cleanLicense(rows[0]), server_time: new Date().toISOString() });
});

export default router;
