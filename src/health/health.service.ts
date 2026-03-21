import { Injectable } from '@nestjs/common';
import { HealthCheckDTO } from './models/healthCheck.dto';

@Injectable()
export class HealthService {
  isStarted: boolean;

  markStarted() {
    this.isStarted = true;
  }

  checkReadiness(): HealthCheckDTO {
    return {
      message: 'ok',
      timestamp: new Date(),
    };
  }
}
