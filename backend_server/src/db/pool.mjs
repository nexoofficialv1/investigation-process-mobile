import pg from 'pg';
const { Pool } = pg;

function firstEnv(keys) {
  for (const key of keys) {
    const value = process.env[key];
    if (typeof value === 'string' && value.trim() !== '') return value.trim();
  }
  return '';
}

function parseDbUrl(value = firstEnv(['DATABASE_URL', 'POSTGRES_URL', 'POSTGRESQL_URL'])) {
  try {
    if (!value) return null;
    const parsed = new URL(value);
    if (!parsed.hostname || !parsed.pathname) return null;
    return {
      protocol: parsed.protocol.replace(':', ''),
      username: decodeURIComponent(parsed.username || ''),
      host: parsed.hostname || '',
      port: parsed.port || '',
      database: parsed.pathname ? parsed.pathname.replace(/^\//, '') : '',
      hasPassword: Boolean(parsed.password)
    };
  } catch (_err) {
    return null;
  }
}

function getSeparateDbConfig() {
  const host = firstEnv(['DB_HOST', 'PGHOST', 'POSTGRES_HOST']);
  const portRaw = firstEnv(['DB_PORT', 'PGPORT', 'POSTGRES_PORT']) || '5432';
  const database = firstEnv(['DB_NAME', 'PGDATABASE', 'POSTGRES_DB', 'DATABASE_NAME']);
  const user = firstEnv(['DB_USER', 'PGUSER', 'POSTGRES_USER', 'DATABASE_USER']);
  const password = firstEnv(['DB_PASSWORD', 'PGPASSWORD', 'POSTGRES_PASSWORD', 'DATABASE_PASSWORD']);

  if (!host || !database || !user) return null;

  return {
    host,
    port: Number(portRaw || 5432),
    database,
    user,
    password,
    hasPassword: Boolean(password)
  };
}

function shouldUseSsl(host = '') {
  const explicit = String(process.env.DB_SSL || '').trim().toLowerCase();
  if (['true', '1', 'yes', 'require', 'required'].includes(explicit)) return true;
  if (['false', '0', 'no', 'disable', 'disabled'].includes(explicit)) return false;

  const parsed = parseDbUrl();
  const dbHost = (host || parsed?.host || firstEnv(['DB_HOST', 'PGHOST']) || '').toLowerCase();
  if (dbHost.includes('site4now.net')) return true;
  return false;
}

function buildPoolConfig() {
  const rawUrl = firstEnv(['DATABASE_URL', 'POSTGRES_URL', 'POSTGRESQL_URL']);
  const parsed = parseDbUrl(rawUrl);

  if (parsed) {
    return {
      mode: 'DATABASE_URL',
      info: parsed,
      config: {
        connectionString: rawUrl,
        ssl: shouldUseSsl(parsed.host) ? { rejectUnauthorized: false } : undefined,
        max: Number(process.env.DB_POOL_MAX || 5),
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: Number(process.env.DB_CONNECT_TIMEOUT_MS || 10000)
      }
    };
  }

  const separate = getSeparateDbConfig();
  if (separate) {
    return {
      mode: 'SEPARATE_ENV',
      info: {
        protocol: 'postgresql',
        username: separate.user,
        host: separate.host,
        port: String(separate.port || ''),
        database: separate.database,
        hasPassword: separate.hasPassword
      },
      config: {
        host: separate.host,
        port: separate.port || 5432,
        database: separate.database,
        user: separate.user,
        password: separate.password || undefined,
        ssl: shouldUseSsl(separate.host) ? { rejectUnauthorized: false } : undefined,
        max: Number(process.env.DB_POOL_MAX || 5),
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: Number(process.env.DB_CONNECT_TIMEOUT_MS || 10000)
      }
    };
  }

  console.warn('Database configuration is missing or invalid. Set DATABASE_URL or DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD.');
  return {
    mode: 'MISSING',
    info: null,
    config: {
      max: Number(process.env.DB_POOL_MAX || 5),
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: Number(process.env.DB_CONNECT_TIMEOUT_MS || 10000)
    }
  };
}

const built = buildPoolConfig();

export const dbInfo = built.info;
export const dbConnectionMode = built.mode;
export const dbSslEnabled = shouldUseSsl(built.info?.host || '');

export const pool = new Pool(built.config);

export async function query(text, params = []) {
  return pool.query(text, params);
}

export async function checkDatabase() {
  try {
    const result = await query('select 1 as ok');
    return { ok: true, row: result.rows?.[0] || null };
  } catch (error) {
    return {
      ok: false,
      code: error.code || error.name || 'DB_ERROR',
      message: error.message || 'Database connection failed'
    };
  }
}

export function getSafeDbDebug() {
  const rawUrl = firstEnv(['DATABASE_URL', 'POSTGRES_URL', 'POSTGRESQL_URL']);
  const info = buildPoolConfig().info;
  return {
    envLoaded: Boolean(process.env.NODE_ENV || process.env.ADMIN_SETUP_CODE || rawUrl || firstEnv(['DB_HOST', 'PGHOST'])),
    databaseUrlPresent: Boolean(rawUrl),
    databaseUrlParsable: Boolean(parseDbUrl(rawUrl)),
    connectionMode: buildPoolConfig().mode,
    protocol: info?.protocol || null,
    host: info?.host || null,
    port: info?.port || null,
    database: info?.database || null,
    username: info?.username || null,
    hasPassword: Boolean(info?.hasPassword),
    separateVarsPresent: {
      DB_HOST: Boolean(firstEnv(['DB_HOST', 'PGHOST', 'POSTGRES_HOST'])),
      DB_PORT: Boolean(firstEnv(['DB_PORT', 'PGPORT', 'POSTGRES_PORT'])),
      DB_NAME: Boolean(firstEnv(['DB_NAME', 'PGDATABASE', 'POSTGRES_DB', 'DATABASE_NAME'])),
      DB_USER: Boolean(firstEnv(['DB_USER', 'PGUSER', 'POSTGRES_USER', 'DATABASE_USER'])),
      DB_PASSWORD: Boolean(firstEnv(['DB_PASSWORD', 'PGPASSWORD', 'POSTGRES_PASSWORD', 'DATABASE_PASSWORD']))
    },
    sslEnabled: shouldUseSsl(info?.host || ''),
    nodeEnv: process.env.NODE_ENV || null
  };
}

export async function withTransaction(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
