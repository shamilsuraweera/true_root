-- Drop and recreate database (dev only). Run as postgres.
drop database if exists true_root;
create database true_root owner true_root;
\c true_root
set role true_root;
\i sql/schema.sql
\i sql/seed_users.sql
\i sql/seed_products.sql
