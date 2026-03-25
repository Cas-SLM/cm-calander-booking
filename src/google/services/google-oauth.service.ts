import { Injectable, Logger } from '@nestjs/common';
import { OAuth2Client } from 'google-auth-library';

export interface GoogleOAuthConfig {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
}

export interface GoogleOAuthTokens {
  accessToken: string;
  refreshToken: string;
  expiryDate: number;
}

@Injectable()
export class GoogleOAuthService {
  private readonly logger = new Logger(GoogleOAuthService.name);
  private readonly oauth2Client: OAuth2Client;

  /**
   * Get the OAuth2 client instance
   */
  getOAuth2Client(): OAuth2Client {
    return this.oauth2Client;
  }

  constructor() {
    const config: GoogleOAuthConfig = {
      clientId: process.env.GOOGLE_CLIENT_ID || '',
      clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
      redirectUri: process.env.GOOGLE_REDIRECT_URI || 'http://localhost:3000/auth/google/callback',
    };

    this.oauth2Client = new OAuth2Client(config.clientId, config.clientSecret, config.redirectUri);

    this.logger.log('Google OAuth service initialized');
  }

  /**
   * Generate OAuth2 authorization URL
   */
  generateAuthUrl(): string {
    return this.oauth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: [
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
      prompt: 'consent',
    });
  }

  /**
   * Exchange authorization code for tokens
   */
  async getToken(code: string): Promise<GoogleOAuthTokens> {
    try {
      const { tokens } = await this.oauth2Client.getToken(code);

      if (!tokens.access_token) {
        throw new Error('No access token received');
      }

      return {
        accessToken: tokens.access_token,
        refreshToken: tokens.refresh_token || '',
        expiryDate: tokens.expiry_date || 0,
      };
    } catch (error) {
      this.logger.error('Failed to get OAuth tokens', error);
      throw error;
    }
  }

  /**
   * Verify and decode ID token
   */
  async verifyIdToken(idToken: string): Promise<any> {
    try {
      const ticket = await this.oauth2Client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      return ticket.getPayload();
    } catch (error) {
      this.logger.error('Failed to verify ID token', error);
      throw error;
    }
  }

  /**
   * Refresh access token using refresh token
   */
  async refreshAccessToken(refreshToken: string): Promise<GoogleOAuthTokens> {
    try {
      this.oauth2Client.setCredentials({ refresh_token: refreshToken });
      const { credentials } = await this.oauth2Client.refreshAccessToken();

      return {
        accessToken: credentials.access_token || '',
        refreshToken: credentials.refresh_token || refreshToken,
        expiryDate: credentials.expiry_date || 0,
      };
    } catch (error) {
      this.logger.error('Failed to refresh access token', error);
      throw error;
    }
  }

  /**
   * Revoke tokens
   */
  async revokeTokens(accessToken: string): Promise<void> {
    try {
      await this.oauth2Client.revokeToken(accessToken);
      this.logger.log('Tokens revoked successfully');
    } catch (error) {
      this.logger.error('Failed to revoke tokens', error);
      throw error;
    }
  }
}
