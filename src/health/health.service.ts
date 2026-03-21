import { Injectable } from '@nestjs/common';
import { HealthCheckDTO } from './models/healthCheck.dto';

@Injectable()
export class HealthService {
  isStarted: boolean;

  markStarted() {
    this.isStarted = true;
  }

  // Added comment for testing pre-commit hook
  checkReadiness(): HealthCheckDTO {
    return {
      message: 'ok',
      timestamp: new Date(),
    };
  }
}
