import { join } from 'path';
import { DataSource } from 'typeorm';
import { buildDbOptions } from './database/db-config';

// Used only by the TypeORM CLI (see the migration:* scripts in package.json).
export default new DataSource({
  ...buildDbOptions(),
  entities: [join(__dirname, '**', '*.entity.{ts,js}')],
  synchronize: false,
});
