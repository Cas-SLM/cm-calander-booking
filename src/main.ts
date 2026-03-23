import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { HealthService } from './health/health.service';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');

  const startUpService = app.get(HealthService);
  startUpService.markStarted();

  await app.listen(process.env.NEST_APP_PORT ?? 3000);
}
bootstrap().catch((error) => console.error(error));
