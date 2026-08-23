import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Trust proxy when behind a reverse proxy / load balancer (needed for real client IPs)
  app.set('trust proxy', 1);

  // Enable CORS only for configured origins
  const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000')
    .split(',')
    .map((o) => o.trim())
    .filter((o) => o.length > 0);
  app.enableCors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      callback(new Error(`CORS: origin ${origin} not allowed`));
    },
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Health check endpoint for Render and load balancers
  app.get('/health', (req: any, res: any) => {
    res.status(200).json({ status: 'ok' });
  });

  // Swagger documentation (disabled in production)
  if (process.env.NODE_ENV !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('RoomMate Match API')
      .setDescription('API for RoomMate Match application')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api', app, document);
  }

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Application is running on: port ${port}`);
  if (process.env.NODE_ENV !== 'production') {
    console.log(`Swagger documentation available in non-production builds`);
  }
}

bootstrap();
