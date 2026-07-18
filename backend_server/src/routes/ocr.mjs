import { Router } from 'express';
import multer from 'multer';
import { requireAuth } from '../middleware/auth.mjs';

const router = Router();
router.use(requireAuth);
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: Number(process.env.MAX_UPLOAD_MB || 20) * 1024 * 1024 } });

router.post('/scan', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'file required' });

  // Google Vision/Document AI integration later এখানে add হবে। এখন endpoint skeleton রাখা হলো।
  if (process.env.OCR_PROVIDER === 'disabled' || !process.env.OCR_PROVIDER) {
    return res.json({
      provider: 'disabled',
      text: '',
      confidence: null,
      note: 'OCR provider is disabled. Configure Google Vision/Document AI later.',
      warning: 'OCR output must be reviewed and corrected before saving.'
    });
  }

  res.status(501).json({ error: 'OCR_NOT_IMPLEMENTED', message: 'OCR provider selected but integration is not implemented in this patch.' });
});

export default router;
