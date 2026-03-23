import { HttpException, HttpStatus } from '@nestjs/common';
import { ProjectErrorMessageInterface, ProjectExceptionInterface } from 'src/exceptions';

export class NotHealthyException extends HttpException implements ProjectExceptionInterface {
  constructor() {
    super('Health check failed', HttpStatus.SERVICE_UNAVAILABLE);
  }
  getErrorMessage(): ProjectErrorMessageInterface {
    return { message: this.message, status: HttpStatus.SERVICE_UNAVAILABLE };
  }
}
