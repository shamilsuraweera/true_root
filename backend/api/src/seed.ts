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

    const sql = fs.readFileSync(sqlPath, 'utf8');
    await client.query(sql);
    console.log('Database seeded successfully with demo users, products, stages, batches, and events!');
  } catch (err) {
    console.error('Seeding failed:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

void runSeed();

