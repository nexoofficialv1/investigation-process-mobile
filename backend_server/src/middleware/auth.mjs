import jwt from 'jsonwebtoken';

export function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Missing Bearer token' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret_change_me');
    return next();
  } catch (_error) {
    return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Invalid or expired token' });
  }
}

export function signOfficerToken(officer) {
  return jwt.sign(
    {
      officer_id: officer.id,
      role: officer.role,
      ps_name: officer.ps_name,
      district: officer.district
    },
    process.env.JWT_SECRET || 'dev_secret_change_me',
    { expiresIn: '30d' }
  );
}
