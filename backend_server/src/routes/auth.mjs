import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { query } from '../db/pool.mjs';
import { signOfficerToken, requireAuth } from '../middleware/auth.mjs';

const router = Router();

router.post('/register', async (req, res) => {
  const setupCode = req.headers['x-admin-setup-code'];
  if (setupCode !== process.env.ADMIN_SETUP_CODE) {
    return res.status(403).json({ error: 'FORBIDDEN', message: 'Invalid setup code' });
  }
  const { name, mobile, email, password, rank, ps_name, district, role = 'officer' } = req.body || {};
  if (!name || !mobile || !password || !ps_name) {
    return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'name, mobile, password and ps_name are required' });
  }
  const hash = await bcrypt.hash(password, 12);
  const { rows } = await query(
    `insert into officers (name, mobile, email, password_hash, rank, ps_name, district, role)
     values ($1,$2,$3,$4,$5,$6,$7,$8)
     returning id, name, mobile, email, rank, ps_name, district, role, created_at`,
    [name, mobile, email || null, hash, rank || null, ps_name, district || null, role]
  );
  res.status(201).json({ officer: rows[0] });
});

router.post('/login', async (req, res) => {
  const { mobile, email, password, device_id } = req.body || {};
  if ((!mobile && !email) || !password) {
    return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'mobile/email and password are required' });
  }
  const { rows } = await query(
    `select * from officers where ${mobile ? 'mobile=$1' : 'email=$1'} and is_active=true limit 1`,
    [mobile || email]
  );
  const officer = rows[0];
  if (!officer) return res.status(401).json({ error: 'INVALID_LOGIN', message: 'Invalid login details' });
  const ok = await bcrypt.compare(password, officer.password_hash);
  if (!ok) return res.status(401).json({ error: 'INVALID_LOGIN', message: 'Invalid login details' });

  if (device_id) {
    await query(
      `insert into officer_devices (officer_id, device_id, last_seen_at)
       values ($1,$2,now())
       on conflict (officer_id, device_id) do update set last_seen_at=now()`,
      [officer.id, device_id]
    );
  }

  const token = signOfficerToken(officer);
  res.json({
    token,
    officer: {
      id: officer.id, name: officer.name, mobile: officer.mobile, email: officer.email,
      rank: officer.rank, ps_name: officer.ps_name, district: officer.district, role: officer.role
    }
  });
});

router.get('/me', requireAuth, async (req, res) => {
  const { rows } = await query(
    `select id, name, mobile, email, rank, ps_name, district, role, is_active, created_at from officers where id=$1`,
    [req.user.officer_id]
  );
  res.json({ officer: rows[0] || null });
});

export default router;
