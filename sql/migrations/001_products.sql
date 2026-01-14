-- Align products table to schema
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_name = 'products' and column_name = 'createdAt'
  ) then
    alter table products rename column "createdAt" to created_at;
  end if;
end $$;

create table if not exists products (
  id bigserial primary key,
  name text not null unique,
  created_at timestamptz not null default now()
);

alter table products
  add column if not exists created_at timestamptz not null default now();

alter table products
  alter column name set not null;

create unique index if not exists products_name_key on products(name);
