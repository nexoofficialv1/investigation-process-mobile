create extension if not exists pgcrypto;

create table if not exists officers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  mobile text unique not null,
  email text unique,
  password_hash text not null,
  rank text,
  ps_name text not null,
  district text,
  role text not null default 'officer',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists officer_devices (
  id uuid primary key default gen_random_uuid(),
  officer_id uuid not null references officers(id) on delete cascade,
  device_id text not null,
  device_name text,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  unique(officer_id, device_id)
);

create table if not exists licenses (
  id uuid primary key default gen_random_uuid(),
  officer_id uuid not null references officers(id) on delete cascade,
  plan_name text not null default 'Offline Trial',
  activation_code text,
  payment_ref text,
  status text not null default 'trial',
  starts_at timestamptz,
  expires_at timestamptz,
  allowed_devices int not null default 1,
  ai_quota_monthly int not null default 0,
  ocr_quota_monthly int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists cases (
  id uuid primary key default gen_random_uuid(),
  officer_id uuid not null references officers(id) on delete cascade,
  local_id text not null,
  case_type text not null default 'case',
  ps_case_no text,
  ps_case_date date,
  sections text,
  complainant_name text,
  accused_summary text,
  payload jsonb not null default '{}'::jsonb,
  sync_version int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique(officer_id, local_id)
);

create table if not exists sync_items (
  id uuid primary key default gen_random_uuid(),
  officer_id uuid not null references officers(id) on delete cascade,
  device_id text,
  entity_type text not null,
  local_id text not null,
  payload jsonb not null default '{}'::jsonb,
  local_updated_at timestamptz,
  server_updated_at timestamptz not null default now(),
  unique(officer_id, entity_type, local_id)
);

create table if not exists backups (
  id uuid primary key default gen_random_uuid(),
  officer_id uuid not null references officers(id) on delete cascade,
  device_id text not null,
  backup_version int not null default 1,
  backup_payload jsonb,
  item_count int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists uploaded_files (
  id uuid primary key default gen_random_uuid(),
  officer_id uuid not null references officers(id) on delete cascade,
  original_name text,
  stored_name text not null,
  mime_type text,
  size_bytes bigint,
  public_url text,
  entity_type text,
  entity_local_id text,
  created_at timestamptz not null default now()
);

create table if not exists ai_usage_logs (
  id uuid primary key default gen_random_uuid(),
  officer_id uuid references officers(id) on delete set null,
  task text not null,
  entity_type text,
  entity_local_id text,
  provider text,
  request_chars int not null default 0,
  response_chars int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  officer_id uuid references officers(id) on delete set null,
  action text not null,
  entity_type text,
  entity_local_id text,
  details jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_cases_officer_updated on cases(officer_id, updated_at desc);
create index if not exists idx_sync_items_officer_updated on sync_items(officer_id, server_updated_at desc);
create index if not exists idx_backups_officer_created on backups(officer_id, created_at desc);
