import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// IMPORTANT for ESM/SmartASP:
// Load .env BEFORE importing app/routes/db modules. Static imports are evaluated
// before this file's body, so we use dynamic import after dotenv is loaded.
dotenv.config();
dotenv.config({ path: path.join(__dirname, '..', '.env'), override: true });
dotenv.config({ path: path.join(__dirname, '.env'), override: false });

const { default: app } = await import('./app.mjs');

const port = Number(process.env.PORT || 3000);

app.listen(port, '0.0.0.0', () => {
  console.log(`INVESTIGO backend running on port ${port}`);
});
