import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import { getDataSourceToken } from '@nestjs/typeorm';
import compression from 'compression';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    rawBody: true,
  });

  // Enable gzip compression to reduce payload sizes
  app.use(compression());

  // Trust proxy when behind a reverse proxy / load balancer (needed for real client IPs)
  app.set('trust proxy', 1);

  // Graceful shutdown on SIGTERM/SIGINT
  app.enableShutdownHooks();

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
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    maxAge: 86400,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: false },
      validationError: { target: false, value: false },
    }),
  );

  // Health check endpoint for Render and load balancers
  app.use('/health', async (req: any, res: any) => {
    const dataSource = app.get(getDataSourceToken());
    try {
      await dataSource.query('SELECT 1');
      res.status(200).json({
        status: 'ok',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      res.status(503).json({
        status: 'error',
        message: 'Database not reachable',
      });
    }
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
  const server = await app.listen(port, '0.0.0.0');

  // Tune keep-alive for high-concurrency scenarios
  server.keepAliveTimeout = 65000;
  server.headersTimeout = 66000;

  console.log(`Application is running on: port ${port}`);
  if (process.env.NODE_ENV !== 'production') {
    console.log(`Swagger documentation available in non-production builds`);
  }
}

bootstrap();
