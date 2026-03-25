import { Controller, Get, Query, Redirect, Req, Res } from '@nestjs/common';
import type { Request, Response } from 'express';
import { GoogleOAuthService } from '../services/google-oauth.service';

@Controller('auth/google')
export class GoogleAuthController {
  constructor(private readonly googleOAuthService: GoogleOAuthService) {}

  /**
   * Initiate Google OAuth flow
   */
  @Get('login')
  @Redirect()
  login() {
    const authUrl = this.googleOAuthService.generateAuthUrl();
    return { url: authUrl };
  }

  /**
   * Handle Google OAuth callback
   */
  @Get('callback')
  async callback(@Query('code') code: string, @Query('state') state: string, @Res() res: Response) {
    try {
      if (!code) {
        return res.status(400).json({ error: 'Authorization code not provided' });
      }

      const tokens = await this.googleOAuthService.getToken(code);

      // In a real application, you would:
      // 1. Store tokens in database
      // 2. Create session or JWT
      // 3. Redirect to frontend with success

      res.json({
        message: 'Authentication successful',
        tokens,
      });
    } catch (error) {
      res.status(500).json({
        error: 'Authentication failed',
        message: error.message,
      });
    }
  }

  /**
   * Verify ID token
   */
  @Get('verify')
  async verifyToken(@Query('idToken') idToken: string) {
    try {
      if (!idToken) {
        throw new Error('ID token not provided');
      }

      const payload = await this.googleOAuthService.verifyIdToken(idToken);

      return {
        success: true,
        user: {
          id: payload?.sub,
          email: payload?.email,
          name: payload?.name,
          picture: payload?.picture,
          verified: payload?.email_verified,
        },
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Refresh access token
   */
  @Get('refresh')
  async refreshToken(@Query('refreshToken') refreshToken: string) {
    try {
      if (!refreshToken) {
        throw new Error('Refresh token not provided');
      }

      const tokens = await this.googleOAuthService.refreshAccessToken(refreshToken);

      return {
        success: true,
        tokens,
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Revoke tokens
   */
  @Get('revoke')
  async revokeToken(@Query('accessToken') accessToken: string) {
    try {
      if (!accessToken) {
        throw new Error('Access token not provided');
      }

      await this.googleOAuthService.revokeTokens(accessToken);

      return {
        success: true,
        message: 'Tokens revoked successfully',
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }
}
