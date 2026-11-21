import { join } from 'path';
import type { DataSourceOptions } from 'typeorm';

/**
 * Single source of truth for the database connection, shared by the Nest app
 * (app.module.ts) and the TypeORM CLI (data-source.ts).
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
    database: process.env.DB_NAME ?? 'true_root',
    synchronize: process.env.DB_SYNCHRONIZE !== 'false',
    migrationsRun: process.env.DB_MIGRATIONS_RUN === 'true',
    migrations: [join(__dirname, 'migrations', '*.{ts,js}')],
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  };
}
