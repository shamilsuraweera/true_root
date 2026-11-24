import { existsSync } from 'fs';
import { join, resolve } from 'path';
import type { DataSourceOptions } from 'typeorm';

// Load backend/api/.env (git-ignored) if present, without overriding real env vars.
const envFile = resolve(__dirname, '../../.env');
if (existsSync(envFile)) {
  process.loadEnvFile(envFile);
}

/** Databases the app must never write to (the PostgreSQL maintenance DBs). */
const FORBIDDEN_DATABASES = ['postgres', 'template0', 'template1'];

/**
 * Returns the database name, or throws if it is one of the PostgreSQL system
 * databases. Used by the API, the TypeORM CLI and the seed script.
 */
export function resolveDbName(): string {
  const name = (process.env.DB_NAME ?? 'true_root').trim();
  if (FORBIDDEN_DATABASES.includes(name.toLowerCase())) {
    throw new Error(
      `Refusing to use the "${name}" database: it is a PostgreSQL system database. ` +
        'Set DB_NAME=true_root (or another dedicated database).',
    );
  }
  return name;
}

/**
 * Single source of truth for the database connection, shared by the Nest app
 * (app.module.ts), the TypeORM CLI (data-source.ts) and the seed script.
 *
 * DB_SYNCHRONIZE   default "true". Set to "false" in production and use migrations.
 * DB_MIGRATIONS_RUN set to "true" to apply pending migrations on API start.
 */
export function buildDbOptions(): DataSourceOptions {
  return {
    type: 'postgres',
    host: process.env.DB_HOST ?? '127.0.0.1',
    port: Number(process.env.DB_PORT ?? 5432),
    username: process.env.DB_USER ?? 'true_root',
    password: process.env.DB_PASS ?? 'true_root',
    database: resolveDbName(),
    synchronize: process.env.DB_SYNCHRONIZE !== 'false',
    migrationsRun: process.env.DB_MIGRATIONS_RUN === 'true',
    migrations: [join(__dirname, 'migrations', '*.{ts,js}')],
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  };
}
