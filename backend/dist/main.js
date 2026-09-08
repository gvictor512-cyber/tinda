"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const typeorm_1 = require("@nestjs/typeorm");
const compression_1 = __importDefault(require("compression"));
const app_module_1 = require("./app.module");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule, {
        rawBody: true,
    });
    app.use((0, compression_1.default)());
    app.set('trust proxy', 1);
    app.enableShutdownHooks();
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
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: false },
        validationError: { target: false, value: false },
    }));
    app.use('/health', async (req, res) => {
        const dataSource = app.get((0, typeorm_1.getDataSourceToken)());
        try {
            await dataSource.query('SELECT 1');
            res.status(200).json({
                status: 'ok',
                uptime: process.uptime(),
                timestamp: new Date().toISOString(),
            });
        }
        catch (error) {
            res.status(503).json({
                status: 'error',
                message: 'Database not reachable',
            });
        }
    });
    if (process.env.NODE_ENV !== 'production') {
        const config = new swagger_1.DocumentBuilder()
            .setTitle('RoomMate Match API')
            .setDescription('API for RoomMate Match application')
            .setVersion('1.0')
            .addBearerAuth()
            .build();
        const document = swagger_1.SwaggerModule.createDocument(app, config);
        swagger_1.SwaggerModule.setup('api', app, document);
    }
    const port = process.env.PORT || 3000;
    const server = await app.listen(port, '0.0.0.0');
    server.keepAliveTimeout = 65000;
    server.headersTimeout = 66000;
    console.log(`Application is running on: port ${port}`);
    if (process.env.NODE_ENV !== 'production') {
        console.log(`Swagger documentation available in non-production builds`);
    }
}
bootstrap();
//# sourceMappingURL=main.js.map