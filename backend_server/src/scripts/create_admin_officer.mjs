import dotenv from 'dotenv';
dotenv.config();
import bcrypt from 'bcryptjs';
import { query, pool } from '../db/pool.mjs';

const [name, mobile, password, psName, district] = process.argv.slice(2);
if (!name || !mobile || !password || !psName) {
  console.log('Usage: node src/scripts/create_admin_officer.mjs "Name" "Mobile" "Password" "Kalna PS" "Purba Bardhaman"');
  process.exit(1);
}

try {
  const hash = await bcrypt.hash(password, 12);
  const { rows } = await query(
    `insert into officers (name, mobile, password_hash, ps_name, district, role)
     values ($1,$2,$3,$4,$5,'admin')
     on conflict (mobile) do update set password_hash=excluded.password_hash, role='admin', ps_name=excluded.ps_name, district=excluded.district
     returning id, name, mobile, ps_name, district, role`,
    [name, mobile, hash, psName, district || null]
  );
  console.log('Admin officer ready:', rows[0]);
} finally {
  await pool.end();
}
