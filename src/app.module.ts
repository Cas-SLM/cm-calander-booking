import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { HealthController, HealthService } from './health';

@Module({
  imports: [],
  controllers: [AppController, HealthController],
  providers: [AppService, HealthService],
})
export class AppModule {}
