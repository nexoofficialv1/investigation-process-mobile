import { Router } from 'express';
import { query, withTransaction } from '../db/pool.mjs';
import { requireAuth } from '../middleware/auth.mjs';

const router = Router();
router.use(requireAuth);

router.post('/upload-backup', async (req, res) => {
  const { device_id, backup_version = 1, items = [], backup_payload = null } = req.body || {};
  if (!device_id) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'device_id required' });

  const result = await withTransaction(async (client) => {
    const backup = await client.query(
      `insert into backups (officer_id, device_id, backup_version, backup_payload, item_count)
       values ($1,$2,$3,$4,$5) returning id, created_at`,
      [req.user.officer_id, device_id, backup_version, backup_payload, Array.isArray(items) ? items.length : 0]
    );

    if (Array.isArray(items)) {
      for (const item of items) {
        await client.query(
          `insert into sync_items (officer_id, device_id, entity_type, local_id, payload, local_updated_at)
           values ($1,$2,$3,$4,$5,$6)
           on conflict (officer_id, entity_type, local_id) do update set
             payload=excluded.payload,
             device_id=excluded.device_id,
             local_updated_at=excluded.local_updated_at,
             server_updated_at=now()`,
          [
            req.user.officer_id,
            device_id,
            item.entity_type || 'unknown',
            item.local_id || item.id || crypto.randomUUID?.() || String(Date.now()),
            item.payload || item,
            item.local_updated_at || new Date().toISOString()
          ]
        );
      }
    }
    return backup.rows[0];
  });

  res.json({ ok: true, backup: result, uploaded_items: Array.isArray(items) ? items.length : 0 });
});

router.get('/download', async (req, res) => {
  const since = req.query.since;
  const params = [req.user.officer_id];
  let where = 'officer_id=$1';
  if (since) {
    params.push(since);
    where += ` and server_updated_at > $2`;
  }
  const { rows } = await query(
    `select entity_type, local_id, payload, server_updated_at from sync_items where ${where} order by server_updated_at asc limit 1000`,
    params
  );
  res.json({ items: rows, server_time: new Date().toISOString() });
});

export default router;
