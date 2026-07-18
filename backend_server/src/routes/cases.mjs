import { Router } from 'express';
import { query } from '../db/pool.mjs';
import { requireAuth } from '../middleware/auth.mjs';

const router = Router();
router.use(requireAuth);

router.get('/', async (req, res) => {
  const { rows } = await query(
    `select id, local_id, case_type, ps_case_no, ps_case_date, sections, complainant_name, accused_summary,
            sync_version, updated_at
     from cases where officer_id=$1 and deleted_at is null order by updated_at desc limit 200`,
    [req.user.officer_id]
  );
  res.json({ cases: rows });
});

router.post('/upsert', async (req, res) => {
  const body = req.body || {};
  if (!body.local_id) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'local_id is required' });
  const { rows } = await query(
    `insert into cases (officer_id, local_id, case_type, ps_case_no, ps_case_date, sections, complainant_name, accused_summary, payload, sync_version)
     values ($1,$2,$3,$4,$5,$6,$7,$8,$9,1)
     on conflict (officer_id, local_id) do update set
       case_type=excluded.case_type,
       ps_case_no=excluded.ps_case_no,
       ps_case_date=excluded.ps_case_date,
       sections=excluded.sections,
       complainant_name=excluded.complainant_name,
       accused_summary=excluded.accused_summary,
       payload=excluded.payload,
       sync_version=cases.sync_version+1,
       updated_at=now(),
       deleted_at=null
     returning *`,
    [
      req.user.officer_id,
      body.local_id,
      body.case_type || 'case',
      body.ps_case_no || null,
      body.ps_case_date || null,
      body.sections || null,
      body.complainant_name || null,
      body.accused_summary || null,
      body.payload || body
    ]
  );
  res.json({ case: rows[0] });
});

router.delete('/:localId', async (req, res) => {
  await query(`update cases set deleted_at=now(), updated_at=now() where officer_id=$1 and local_id=$2`, [req.user.officer_id, req.params.localId]);
  res.json({ ok: true });
});

export default router;
