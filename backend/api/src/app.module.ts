import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthModule } from './auth/auth.module';
import { ProductsModule } from './products/products.module';
import { BatchesModule } from './batches/batches.module';
import { BatchEventsModule } from './batch-events/batch-events.module';
import { StagesModule } from './stages/stages.module';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST ?? '127.0.0.1',
      port: Number(process.env.DB_PORT ?? 5432),
      username: process.env.DB_USER ?? 'true_root',
      password: process.env.DB_PASS ?? 'true_root',
      database: process.env.DB_NAME ?? 'true_root',
      autoLoadEntities: true,
      synchronize: true, // change to false once stable + use migrations
    }),

    AuthModule,
    ProductsModule,
    BatchesModule,
    BatchEventsModule,
    StagesModule,
  ],
})
export class AppModule {}
