import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BatchEventsModule } from './batch-events/batch-events.module';

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
      synchronize: true,
    }),
    BatchEventsModule,
  ],
})
export class AppModule {}
