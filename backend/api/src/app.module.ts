import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { ProductsModule } from './products/products.module';
import { BatchesModule } from './batches/batches.module';
import { BatchEventsModule } from './batch-events/batch-events.module';
import { Product } from './products/product.entity';
import { Batch } from './batches/batch.entity';
import { BatchEvent } from './batch-events/batch-event.entity';


@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: 'localhost',
      port: 5432,
      username: 'true_root',
      password: 'true_root',
      database: 'true_root',
      autoLoadEntities: true,
      synchronize: false,
    }),
    AuthModule,
    ProductsModule,
    BatchesModule,
    BatchEventsModule,
  ],
})
export class AppModule {}
