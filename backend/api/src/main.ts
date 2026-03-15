import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { CorsOptionsDelegate, CorsOptions } from 'cors';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const allowedOrigins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
  const isDev = process.env.NODE_ENV !== 'production';

  const corsOrigin: CorsOptionsDelegate = (
    origin: string | undefined,
    callback: (err: Error | null, options?: CorsOptions) => void,
  ) => {
    if (!origin) {
      callback(null, { origin: true });
      return;
    }
    if (allowedOrigins.length === 0) {
      callback(null, { origin: isDev });
      return;
    }
    if (allowedOrigins.includes(origin)) {
      callback(null, { origin: true });
      return;
    }
    callback(new Error('Not allowed by CORS'));
  };

  app.enableCors({
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    origin: corsOrigin,
    credentials: true,
  });
  await app.listen(process.env.PORT ?? 3000, '0.0.0.0');
}
void bootstrap();
