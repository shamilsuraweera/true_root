insert into users (id, email, role, name, organization, location, account_type, members)
values
  (1, 'shamil@trueroot.lk', 'farmer', 'Shamil Suraweera', 'True Root Co.', 'Kandy', 'Individual', '[]'::jsonb)
on conflict (id) do nothing;
