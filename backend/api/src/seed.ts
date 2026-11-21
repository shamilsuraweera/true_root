import { Client } from 'pg';
import * as fs from 'fs';
import * as path from 'path';

async function runSeed() {
  const client = new Client({
    host: process.env.DB_HOST ?? '127.0.0.1',
    port: Number(process.env.DB_PORT ?? 5432),
    user: process.env.DB_USER ?? 'true_root',
    password: process.env.DB_PASS ?? 'true_root',
    database: process.env.DB_NAME ?? 'true_root',
  });

  try {
    await client.connect();
    console.log('Connected to True Root database. Seeding data...');

    const sqlPath = path.resolve(__dirname, '../../../sql/seed_data.sql');
    if (!fs.existsSync(sqlPath)) {
      throw new Error(`Seed SQL file not found at: ${sqlPath}`);
    }

    const tables = await client.query<{
      users: string | null;
      batches: string | null;
    }>(
      "SELECT to_regclass('users') AS users, to_regclass('batches') AS batches",
    );
    const { users, batches } = tables.rows[0];
    if (!users || !batches) {
      throw new Error(
        'Tables do not exist yet. Start the API once (synchronize) or run `npm run migration:run`, then seed again.',
      );
    }

    const sql = fs.readFileSync(sqlPath, 'utf8');
    await client.query(sql);
    console.log(
      'Database seeded with demo users, stages, products, batches, events and a request.',
    );
    console.log(
      'Logins: admin|farmer|trader|exporter@trueroot.com / <role>123',
    );
  } catch (err) {
    console.error('Seeding failed:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

void runSeed();
