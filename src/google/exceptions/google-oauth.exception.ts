import { HttpException, HttpStatus } from '@nestjs/common';

export class GoogleOAuthException extends HttpException {
  constructor(message: string, statusCode: HttpStatus = HttpStatus.INTERNAL_SERVER_ERROR) {
    super(
      {
        success: false,
        error: 'Google OAuth Error',
        message,
        statusCode,
      },
      statusCode,
    );
  }
}

export class GoogleOAuthTokenException extends GoogleOAuthException {
  constructor(message: string = 'Invalid or expired OAuth token') {
    super(message, HttpStatus.UNAUTHORIZED);
  }
}

export class GoogleOAuthAuthorizationException extends GoogleOAuthException {
  constructor(message: string = 'Authorization failed') {
    super(message, HttpStatus.UNAUTHORIZED);
  }
}

export class GoogleOAuthVerificationException extends GoogleOAuthException {
  constructor(message: string = 'Token verification failed') {
    super(message, HttpStatus.FORBIDDEN);
  }
}

export class GoogleOAuthRevocationException extends GoogleOAuthException {
  constructor(message: string = 'Token revocation failed') {
    super(message, HttpStatus.INTERNAL_SERVER_ERROR);
  }
}
