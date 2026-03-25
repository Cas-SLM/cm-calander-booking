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

export interface GoogleUserProfile {
  id: string;
  email: string;
  verified_email: boolean;
  name: string;
  given_name: string;
  family_name: string;
  picture: string;
  locale: string;
}

export interface GoogleOAuthCallbackParams {
  code: string;
  state?: string;
  error?: string;
}

export interface GoogleOAuthResponse {
  success: boolean;
  tokens?: GoogleOAuthTokens;
  user?: GoogleUserProfile;
  error?: string;
  message?: string;
}
