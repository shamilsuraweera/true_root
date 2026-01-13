-- Core schema for supply-chain batch tracking MVP (PostgreSQL)

create table if not exists users (
  id bigserial primary key,
  email text not null unique,
  role text not null,
  name text,
  organization text,
  location text,
  account_type text,
  members jsonb,
  created_at timestamptz not null default now()
);

create table if not exists products (
  id bigserial primary key,
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists stages (
  id bigserial primary key,
  name text not null unique,
  sequence int not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists batches (
  id bigserial primary key,
  product_id bigint not null references products(id),
  batch_code text not null unique,
  quantity numeric(14,3) not null,
  unit text not null default 'kg',
  status text not null,
  grade text,
  stage_id bigint references stages(id),
  qr_payload text unique,
  is_disqualified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_batches_product on batches(product_id);
create index if not exists idx_batches_status on batches(status);
create index if not exists idx_batches_stage on batches(stage_id);

create table if not exists batch_events (
  id bigserial primary key,
  batch_id bigint not null references batches(id) on delete cascade,
  type text not null,
  stage_id bigint references stages(id),
  description text,
  quantity_before numeric(14,3),
  quantity_after numeric(14,3),
  status_before text,
  status_after text,
  grade_before text,
  grade_after text,
  actor_user_id bigint references users(id),
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_batch_events_batch on batch_events(batch_id);
create index if not exists idx_batch_events_created_at on batch_events(created_at);

create table if not exists batch_relations (
  id bigserial primary key,
  parent_batch_id bigint not null references batches(id) on delete cascade,
  child_batch_id bigint not null references batches(id) on delete cascade,
  relation_type text not null,
  quantity numeric(14,3),
  created_at timestamptz not null default now()
);

create index if not exists idx_batch_relations_parent on batch_relations(parent_batch_id);
create index if not exists idx_batch_relations_child on batch_relations(child_batch_id);
