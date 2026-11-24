# Database: schema, migrations and seed data

True Root uses PostgreSQL through TypeORM. Connection settings come from environment variables
(defaults in brackets), defined once in `backend/api/src/database/db-config.ts`:

| Variable | Purpose |
|---|---|
| `DB_HOST` / `DB_PORT` | server address [`127.0.0.1` / `5432`] |
| `DB_USER` / `DB_PASS` / `DB_NAME` | credentials and database [`true_root` for all three]. `DB_NAME` may **never** be `postgres`, `template0` or `template1`: the API, the migration CLI and the seed refuse to start. |
| `DB_SSL` | `true` for managed databases that require TLS |
| `DB_SYNCHRONIZE` | `false` turns off automatic schema sync [default: on] |
| `DB_MIGRATIONS_RUN` | `true` applies pending migrations when the API starts [default: off] |

You can keep these in `backend/api/.env` (git-ignored; copy `.env.example`) instead of exporting them. Real
environment variables take precedence. You may connect as any role (for example `postgres`), but always to a
dedicated database; create it once with `CREATE DATABASE true_root;`.

## Two ways to manage the schema

| | Development | Production |
|---|---|---|
| Mode | **Auto sync** (default). Tables are created/altered on API start. | **Migrations**. Versioned SQL you review and run. |
| Settings | nothing to set | `DB_SYNCHRONIZE=false` and run `migration:run` (or `DB_MIGRATIONS_RUN=true`) |

Never leave auto sync on for a database that holds real data: it can drop or alter columns without asking.

## Migrations

Run these from `backend/api`. Migration files live in `src/database/migrations/` and are committed to git.

```bash
npm run migration:show                                  # which migrations are applied ([X]) or pending ([ ])
npm run migration:run                                   # apply pending migrations
npm run migration:revert                                # undo the most recent one
npm run migration:generate -- src/database/migrations/AddFoo   # diff entities vs the database
npm run migration:create -- src/database/migrations/Custom     # empty file for hand-written SQL
```

The repository ships `InitialSchema`, which creates every table. A new empty database can be built with
`npm run migration:run` alone, with no need to start the API first.

### Changing the data model

1. Edit the entity (`*.entity.ts`).
2. Point at a database that is **at the previous schema** (migrations applied, `DB_SYNCHRONIZE=false`), then run
   `npm run migration:generate -- src/database/migrations/DescribeChange`. If you used auto sync locally,
   generate against a fresh empty database or schema so the diff is complete.
3. **Read the generated SQL.** TypeORM can express a rename as drop + add (data loss); rewrite those by hand.
4. `npm run migration:run`, test, commit the migration file with the entity change.

### Switching an existing auto-sync database to migrations

The tables already exist, so do not run `InitialSchema` against it. Mark it as applied instead:

```sql
CREATE TABLE IF NOT EXISTS migrations (id SERIAL PRIMARY KEY, "timestamp" bigint NOT NULL, name varchar NOT NULL);
INSERT INTO migrations ("timestamp", name) VALUES (<timestamp from the file name>, 'InitialSchema<timestamp>');
```

Then set `DB_SYNCHRONIZE=false`. Run `migration:generate` once; it should report "no changes". If it finds some,
your database drifted from the entities, so review that migration before applying it.

### Production (compiled build)

The npm scripts use `ts-node`, so they need dev dependencies. On a server that only has the built app, either
run migrations from CI/your machine against the production database, or set `DB_MIGRATIONS_RUN=true` so the
API applies them itself on start (the compiled migrations are included in `dist/`).

## Seed data (demo content)

```bash
cd backend/api
npm run migration:run     # or start the API once, so the tables exist
npm run seed
```

The script runs `sql/seed_data.sql` and is **idempotent**: running it again changes nothing.

It creates:

| Table | Content |
|---|---|
| users | `admin@`, `farmer@`, `trader@`, `exporter@` `trueroot.com`, password `<role>123` (e.g. `farmer123`), matching the login screen's demo chips |
| stages | Harvested, Processing, Packaging, Export |
| products | Ceylon Cinnamon, Black Pepper, Cardamom (owned by the farmer) |
| batches | `DEMO-CIN-001`, `DEMO-PEP-001`, `DEMO-CAR-001`, each with QR payload and a history event |
| ownership_requests | one pending request (trader asks the farmer for 100 kg of cinnamon) |

Notes:
- Passwords are bcrypt-hashed inside the database with the `pgcrypto` extension (`CREATE EXTENSION IF NOT EXISTS pgcrypto`,
  allowed for the database owner on PostgreSQL 13+).
- **Do not seed production.** The demo passwords are public. Delete them or never run the seed there.
- The seed connects with the same `DB_*` variables as the API.

### Reset to a clean demo state (development only)

```bash
psql -h 127.0.0.1 -U true_root -d true_root -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
cd backend/api && npm run migration:run && npm run seed
```

(If that fails with a permission error, run it as the `postgres` superuser.)

## Backups

```bash
pg_dump -h HOST -U true_root -Fc true_root > true_root_$(date +%F).dump     # back up
pg_restore -h HOST -U true_root -d true_root --clean true_root_2026-01-01.dump   # restore
```

Take a backup before every production deploy that includes a migration.
