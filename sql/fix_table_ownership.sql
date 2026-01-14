-- Fix table ownership for true_root role (run as postgres or table owner)
alter table if exists users owner to true_root;
alter table if exists products owner to true_root;
alter table if exists stages owner to true_root;
alter table if exists batches owner to true_root;
alter table if exists batch_events owner to true_root;
alter table if exists batch_relations owner to true_root;
alter table if exists ownership_requests owner to true_root;
