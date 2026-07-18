import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import path from 'path';
import { fileURLToPath } from 'url';

import healthRoutes from './routes/health.mjs';
import authRoutes from './routes/auth.mjs';
import licenseRoutes from './routes/license.mjs';
import syncRoutes from './routes/sync.mjs';
import caseRoutes from './routes/cases.mjs';
import fileRoutes from './routes/files.mjs';
import aiRoutes from './routes/ai.mjs';
import ocrRoutes from './routes/ocr.mjs';
import setupRoutes from './routes/setup.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const uploadDir = process.env.UPLOAD_DIR || path.join(__dirname, '..', 'uploads');

// SmarterASP/iisnode rewrite helper. Some panels forward all requests to the
// startup script as /src/server.mjs and pass the original path in query.
// Restore the real route before Express route matching.
app.use((req, _res, next) => {
  const internalStartupPath = '/src/server.mjs';
  const originalPath = req.query?.originalPath;

  if (req.path === internalStartupPath && typeof originalPath === 'string') {
    const cleanPath = originalPath.trim().replace(/^\/+/, '');
    const restoredPath = cleanPath.length ? `/${cleanPath}` : '/';
    const preservedQuery = new URLSearchParams();

    for (const [key, value] of Object.entries(req.query || {})) {
      if (key === 'originalPath') continue;
      if (Array.isArray(value)) {
        value.forEach((item) => preservedQuery.append(key, String(item)));
      } else if (value !== undefined) {
        preservedQuery.append(key, String(value));
      }
    }

    const queryString = preservedQuery.toString();
    req.url = restoredPath + (queryString ? `?${queryString}` : '');
  } else if (req.url === internalStartupPath) {
    req.url = '/';
  } else if (req.url.startsWith(`${internalStartupPath}/`)) {
    req.url = req.url.substring(internalStartupPath.length);
  }

  next();
});

app.set('trust proxy', 1);
app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

app.use(rateLimit({
  windowMs: 60 * 1000,
  limit: 240,
  standardHeaders: true,
  legacyHeaders: false
}));

app.use('/uploads', express.static(uploadDir));

app.use('/api/health', healthRoutes);
// Compatibility alias for older mobile APKs / SmartASP rewrites that call /health.
app.use('/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/license', licenseRoutes);
app.use('/api/sync', syncRoutes);
app.use('/api/cases', caseRoutes);
app.use('/api/files', fileRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/ocr', ocrRoutes);
app.use('/api/setup', setupRoutes);

app.get('/', (_req, res) => {
  res.json({ app: 'INVESTIGO Backend', version: '4.2.0', status: 'ok' });
});

app.use((req, res) => {
  res.status(404).json({ error: 'NOT_FOUND', message: `Route not found: ${req.method} ${req.originalUrl}` });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(err.statusCode || 500).json({
    error: err.code || 'SERVER_ERROR',
    message: err.message || 'Internal server error'
  });
});

export default app;
