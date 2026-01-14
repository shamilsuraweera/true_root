insert into users (id, email, password, role, name, organization, location, account_type, members)
values
  (1, 'shamil@trueroot.lk', 'password', 'farmer', 'Shamil Suraweera', 'True Root Co.', 'Kandy', 'Individual', '[]'::jsonb),
  (2, 'shamilsuraweera@gmail.com', 'Admin@123', 'admin', 'Shamil Suraweera', 'True Root Co.', 'Kandy', 'Individual', '[]'::jsonb)
on conflict (email) do nothing;
