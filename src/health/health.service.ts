import { Injectable } from '@nestjs/common';
import { HealthCheckDTO } from './models/healthCheck.dto';

@Injectable()
export class HealthService {
  isStarted: boolean;

  markStarted() {
    this.isStarted = true;
  }

  // Updated comment for Husky testing
  checkReadiness(): HealthCheckDTO {
    return {
      message: 'ok',
      timestamp: new Date(),
    };
  }
}
