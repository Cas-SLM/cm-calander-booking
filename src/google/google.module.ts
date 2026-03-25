import { Module } from '@nestjs/common';
import { GoogleAuthController } from './controllers/google-auth.controller';
import { GoogleCalenderController } from './controllers/google-calender.controller';
import { GoogleOAuthService } from './services/google-oauth.service';
import { GoogleCalenderService } from './services/google-calender.service';

@Module({
  controllers: [GoogleAuthController, GoogleCalenderController],
  providers: [GoogleOAuthService, GoogleCalenderService],
  exports: [GoogleOAuthService, GoogleCalenderService],
})
export class GoogleModule {}
