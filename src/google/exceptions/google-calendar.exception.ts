import { HttpException, HttpStatus } from '@nestjs/common';

export class GoogleCalendarException extends HttpException {
  constructor(message: string, statusCode: HttpStatus = HttpStatus.INTERNAL_SERVER_ERROR) {
    super(
      {
        success: false,
        error: 'Google Calendar Error',
        message,
        statusCode,
      },
      statusCode,
    );
  }
}

export class GoogleCalendarNotFoundException extends GoogleCalendarException {
  constructor(calendarId: string) {
    super(`Calendar not found: ${calendarId}`, HttpStatus.NOT_FOUND);
  }
}

export class GoogleCalendarEventNotFoundException extends GoogleCalendarException {
  constructor(eventId: string) {
    super(`Event not found: ${eventId}`, HttpStatus.NOT_FOUND);
  }
}

export class GoogleCalendarPermissionException extends GoogleCalendarException {
  constructor(message: string = 'Insufficient permissions') {
    super(message, HttpStatus.FORBIDDEN);
  }
}

export class GoogleCalendarQuotaExceededException extends GoogleCalendarException {
  constructor(message: string = 'API quota exceeded') {
    super(message, HttpStatus.TOO_MANY_REQUESTS);
  }
}

export class GoogleCalendarValidationException extends GoogleCalendarException {
  constructor(message: string = 'Invalid calendar data') {
    super(message, HttpStatus.BAD_REQUEST);
  }
}

export class GoogleCalendarConflictException extends GoogleCalendarException {
  constructor(message: string = 'Calendar conflict') {
    super(message, HttpStatus.CONFLICT);
  }
}
