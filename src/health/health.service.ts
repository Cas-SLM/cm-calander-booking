import { Injectable } from '@nestjs/common';
import { HealthCheckDTO } from './models/healthCheck.dto';
import { NotHealthyException } from './exceptions/not-healthy.exception';

@Injectable()
export class HealthService {
  isStarted: boolean;

  markStarted() {
    this.isStarted = true;
  }

  checkLiveness() {
    return Promise.resolve(true);
  }

  checkReadiness(): Promise<HealthCheckDTO> {
    return Promise.resolve({
      message: 'ok',
      timestamp: new Date(),
    });
  }

  async hasStarted(): Promise<HealthCheckDTO> {
    if (!this.isStarted) {
      throw new NotHealthyException();
    }
    return Promise.resolve({
      message: 'ok',
      timestamp: new Date(),
    });
  }
}
