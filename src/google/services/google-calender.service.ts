import { Injectable, Logger } from '@nestjs/common';
import { calendar_v3, google } from 'googleapis';
import { GoogleOAuthService } from './google-oauth.service';

export interface CalendarEvent {
  id?: string;
  summary: string;
  description?: string;
  location?: string;
  start: {
    dateTime: string;
    timeZone: string;
  };
  end: {
    dateTime: string;
    timeZone: string;
  };
  attendees?: Array<{
    email: string;
    displayName?: string;
  }>;
  reminders?: {
    useDefault: boolean;
    overrides?: Array<{
      method: 'email' | 'popup';
      minutes: number;
    }>;
  };
}

export interface CalendarList {
  id: string;
  summary: string;
  primary?: boolean;
  selected?: boolean;
}

@Injectable()
export class GoogleCalenderService {
  private readonly logger = new Logger(GoogleCalenderService.name);
  private calendar: calendar_v3.Calendar;

  constructor(private readonly googleOAuthService: GoogleOAuthService) {
    this.calendar = google.calendar({ version: 'v3' });
    this.logger.log('Google Calendar service initialized');
  }

  /**
   * List calendars for the authenticated user
   */
  async listCalendars(accessToken: string): Promise<CalendarList[]> {
    try {
      this.calendar.auth = this.googleOAuthService.getOAuth2Client();
      this.googleOAuthService.getOAuth2Client().setCredentials({ access_token: accessToken });

      const response = await this.calendar.calendarList.list();
      const calendars = response.data.items || [];

      return calendars.map((cal) => ({
        id: cal.id || '',
        summary: cal.summary || '',
        primary: cal.primary || false,
        selected: cal.selected || false,
      }));
    } catch (error) {
      this.logger.error('Failed to list calendars', error);
      throw error;
    }
  }

  /**
   * Get calendar by ID
   */
  async getCalendar(calendarId: string, accessToken: string): Promise<CalendarList> {
    try {
      this.calendar.auth = this.googleOAuthService.getOAuth2Client();
      this.googleOAuthService.getOAuth2Client().setCredentials({ access_token: accessToken });

      const response = await this.calendar.calendars.get({
        calendarId,
      });

      const cal = response.data;

      return {
        id: cal.id || '',
        summary: cal.summary || '',
        primary: cal.primary || false,
        selected: cal.selected || false,
      };
    } catch (error) {
      this.logger.error('Failed to get calendar', error);
      throw error;
    }
  }

  /**
   * List events from a specific calendar
   */
  async listEvents(
    calendarId: string,
    accessToken: string,
    timeMin?: string,
    timeMax?: string,
    maxResults = 250,
  ): Promise<CalendarEvent[]> {
    try {
      this.calendar.auth = this.googleOAuthService.getOAuth2Client();
      this.googleOAuthService.getOAuth2Client().setCredentials({ access_token: accessToken });

      const response = await this.calendar.events.list({
        calendarId,
        timeMin: timeMin || new Date().toISOString(),
        timeMax,
        maxResults,
        singleEvents: true,
        orderBy: 'startTime',
      });

      const events = response.data.items || [];

      return events.map((event) => ({
        id: event.id || '',
        summary: event.summary || '',
        description: event.description,
        location: event.location,
        start: {
          dateTime: event.start?.dateTime || '',
          timeZone: event.start?.timeZone || 'UTC',
        },
        end: {
          dateTime: event.end?.dateTime || '',
          timeZone: event.end?.timeZone || 'UTC',
        },
        attendees: event.attendees?.map((attendee) => ({
          email: attendee.email || '',
          displayName: attendee.displayName,
        })),
        reminders: {
          useDefault: event.reminders?.useDefault || false,
          overrides: event.reminders?.overrides?.map((override) => ({
            method: override.method as 'email' | 'popup',
            minutes: override.minutes || 0,
          })),
        },
      }));
    } catch (error) {
      this.logger.error('Failed to list events', error);
      throw error;
    }
  }

  /**
   * Create a new event
   */
  async createEvent(
    calendarId: string,
    event: Omit<CalendarEvent, 'id'>,
    accessToken: string,
  ): Promise<CalendarEvent> {
    try {
      this.calendar.auth = this.googleOAuthService.getOAuth2Client();
      this.googleOAuthService.getOAuth2Client().setCredentials({ access_token: accessToken });

      const response = await this.calendar.events.insert({
        calendarId,
        requestBody: {
          summary: event.summary,
          description: event.description,
          location: event.location,
          start: event.start,
          end: event.end,
          attendees: event.attendees,
          reminders: event.reminders,
        },
      });

      const createdEvent = response.data;

      return {
        id: createdEvent.id || '',
        summary: createdEvent.summary || '',
        description: createdEvent.description,
        location: createdEvent.location,
        start: {
          dateTime: createdEvent.start?.dateTime || '',
          timeZone: createdEvent.start?.timeZone || 'UTC',
        },
        end: {
          dateTime: createdEvent.end?.dateTime || '',
          timeZone: createdEvent.end?.timeZone || 'UTC',
        },
        attendees: createdEvent.attendees?.map((attendee) => ({
          email: attendee.email || '',
          displayName: attendee.displayName,
        })),
        reminders: {
          useDefault: createdEvent.reminders?.useDefault || false,
          overrides: createdEvent.reminders?.overrides?.map((override) => ({
            method: override.method as 'email' | 'popup',
            minutes: override.minutes || 0,
          })),
        },
      };
    } catch (error) {
      this.logger.error('Failed to create event', error);
      throw error;
    }
  }

  /**
   * Update an existing event
   */
  async updateEvent(
    calendarId: string,
    eventId: string,
    event: Partial<CalendarEvent>,
    accessToken: string,
  ): Promise<CalendarEvent> {
    try {
      this.calendar.auth = this.googleOAuthService.getOAuth2Client();
      this.googleOAuthService.getOAuth2Client().setCredentials({ access_token: accessToken });

      const response = await this.calendar.events.update({
        calendarId,
        eventId,
        requestBody: {
          summary: event.summary,
          description: event.description,
          location: event.location,
          start: event.start,
          end: event.end,
          attendees: event.attendees,
          reminders: event.reminders,
        },
      });

      const updatedEvent = response.data;

      return {
        id: updatedEvent.id || '',
        summary: updatedEvent.summary || '',
        description: updatedEvent.description,
        location: updatedEvent.location,
        start: {
          dateTime: updatedEvent.start?.dateTime || '',
          timeZone: updatedEvent.start?.timeZone || 'UTC',
        },
        end: {
          dateTime: updatedEvent.end?.dateTime || '',
          timeZone: updatedEvent.end?.timeZone || 'UTC',
        },
        attendees: updatedEvent.attendees?.map((attendee) => ({
          email: attendee.email || '',
          displayName: attendee.displayName,
        })),
        reminders: {
          useDefault: updatedEvent.reminders?.useDefault || false,
          overrides: updatedEvent.reminders?.overrides?.map((override) => ({
            method: override.method as 'email' | 'popup',
            minutes: override.minutes || 0,
          })),
        },
      };
    } catch (error) {
      this.logger.error('Failed to update event', error);
      throw error;
    }
  }

  /**
   * Delete an event
   */
  async deleteEvent(calendarId: string, eventId: string, accessToken: string): Promise<void> {
    try {
      this.calendar.auth = this.googleOAuthService.getOAuth2Client();
      this.googleOAuthService.getOAuth2Client().setCredentials({ access_token: accessToken });

      await this.calendar.events.delete({
        calendarId,
        eventId,
      });

      this.logger.log(`Event ${eventId} deleted successfully`);
    } catch (error) {
      this.logger.error('Failed to delete event', error);
      throw error;
    }
  }

  /**
   * Get event by ID
   */
  async getEvent(calendarId: string, eventId: string, accessToken: string): Promise<CalendarEvent> {
    try {
      this.calendar.auth = this.googleOAuthService.getOAuth2Client();
      this.googleOAuthService.getOAuth2Client().setCredentials({ access_token: accessToken });

      const response = await this.calendar.events.get({
        calendarId,
        eventId,
      });

      const event = response.data;

      return {
        id: event.id || '',
        summary: event.summary || '',
        description: event.description,
        location: event.location,
        start: {
          dateTime: event.start?.dateTime || '',
          timeZone: event.start?.timeZone || 'UTC',
        },
        end: {
          dateTime: event.end?.dateTime || '',
          timeZone: event.end?.timeZone || 'UTC',
        },
        attendees: event.attendees?.map((attendee) => ({
          email: attendee.email || '',
          displayName: attendee.displayName,
        })),
        reminders: {
          useDefault: event.reminders?.useDefault || false,
          overrides: event.reminders?.overrides?.map((override) => ({
            method: override.method as 'email' | 'popup',
            minutes: override.minutes || 0,
          })),
        },
      };
    } catch (error) {
      this.logger.error('Failed to get event', error);
      throw error;
    }
  }
}
