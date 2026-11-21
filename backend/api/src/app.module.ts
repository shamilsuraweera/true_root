import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { ProductsModule } from './products/products.module';
import { BatchesModule } from './batches/batches.module';
import { BatchEventsModule } from './batch-events/batch-events.module';
import { StagesModule } from './stages/stages.module';
import { UsersModule } from './users/users.module';
import { OwnershipRequestsModule } from './ownership-requests/ownership-requests.module';
import { AdminModule } from './admin/admin.module';
import { buildDbOptions } from './database/db-config';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      ...buildDbOptions(),
      autoLoadEntities: true,
    }),

    AuthModule,
    ProductsModule,
    BatchesModule,
    BatchEventsModule,
    StagesModule,
    UsersModule,
    OwnershipRequestsModule,
    AdminModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
