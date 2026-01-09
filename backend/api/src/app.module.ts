import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';

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
  ],
})
export class AppModule {}
