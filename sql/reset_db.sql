-- Drop and recreate all core tables (dev only)
drop table if exists ownership_requests cascade;
drop table if exists batch_relations cascade;
drop table if exists batch_events cascade;
drop table if exists batches cascade;
drop table if exists stages cascade;
drop table if exists products cascade;
drop table if exists users cascade;

\i sql/schema.sql
\i sql/seed_users.sql
\i sql/seed_products.sql
