import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { query } from '../db/pool.mjs';
import { requireAuth } from '../middleware/auth.mjs';

const router = Router();
router.use(requireAuth);

const uploadDir = process.env.UPLOAD_DIR || 'uploads';
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => cb(null, `${Date.now()}-${uuidv4()}${path.extname(file.originalname || '')}`)
});

const upload = multer({
  storage,
  limits: { fileSize: Number(process.env.MAX_UPLOAD_MB || 20) * 1024 * 1024 }
});

router.post('/upload', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'file required' });
  const publicBase = process.env.PUBLIC_BASE_URL || '';
  const publicUrl = `${publicBase}/uploads/${req.file.filename}`;
  const { rows } = await query(
    `insert into uploaded_files (officer_id, original_name, stored_name, mime_type, size_bytes, public_url, entity_type, entity_local_id)
     values ($1,$2,$3,$4,$5,$6,$7,$8) returning *`,
    [req.user.officer_id, req.file.originalname, req.file.filename, req.file.mimetype, req.file.size, publicUrl, req.body.entity_type || null, req.body.entity_local_id || null]
  );
  res.json({ file: rows[0] });
});

export default router;
