insert into products (name)
values
  ('Cinnamon'),
  ('Tea')
on conflict (name) do nothing;
