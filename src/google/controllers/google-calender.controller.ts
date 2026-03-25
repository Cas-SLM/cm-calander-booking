import { Body, Controller, Delete, Get, Param, Post, Put, Query } from '@nestjs/common';
import {
  GoogleCalenderService,
  CalendarEvent,
  CalendarList,
} from '../services/google-calender.service';

@Controller('calendar')
export class GoogleCalenderController {
  constructor(private readonly googleCalenderService: GoogleCalenderService) {}

  /**
   * List calendars for the authenticated user
   */
  @Get('calendars')
  async listCalendars(@Query('accessToken') accessToken: string): Promise<CalendarList[]> {
    return this.googleCalenderService.listCalendars(accessToken);
  }

  /**
   * Get calendar by ID
   */
  @Get('calendars/:calendarId')
  async getCalendar(
    @Param('calendarId') calendarId: string,
    @Query('accessToken') accessToken: string,
  ): Promise<CalendarList> {
    return this.googleCalenderService.getCalendar(calendarId, accessToken);
  }

  /**
   * List events from a specific calendar
   */
  @Get('calendars/:calendarId/events')
  async listEvents(
    @Param('calendarId') calendarId: string,
    @Query('accessToken') accessToken: string,
    @Query('timeMin') timeMin?: string,
    @Query('timeMax') timeMax?: string,
    @Query('maxResults') maxResults?: number,
  ): Promise<CalendarEvent[]> {
    return this.googleCalenderService.listEvents(
      calendarId,
      accessToken,
      timeMin,
      timeMax,
      maxResults,
    );
  }

  /**
   * Get event by ID
   */
  @Get('calendars/:calendarId/events/:eventId')
  async getEvent(
    @Param('calendarId') calendarId: string,
    @Param('eventId') eventId: string,
    @Query('accessToken') accessToken: string,
  ): Promise<CalendarEvent> {
    return this.googleCalenderService.getEvent(calendarId, eventId, accessToken);
  }

  /**
   * Create a new event
   */
  @Post('calendars/:calendarId/events')
  async createEvent(
    @Param('calendarId') calendarId: string,
    @Query('accessToken') accessToken: string,
    @Body() event: Omit<CalendarEvent, 'id'>,
  ): Promise<CalendarEvent> {
    return this.googleCalenderService.createEvent(calendarId, event, accessToken);
  }

  /**
   * Update an existing event
   */
  @Put('calendars/:calendarId/events/:eventId')
  async updateEvent(
    @Param('calendarId') calendarId: string,
    @Param('eventId') eventId: string,
    @Query('accessToken') accessToken: string,
    @Body() event: Partial<CalendarEvent>,
  ): Promise<CalendarEvent> {
    return this.googleCalenderService.updateEvent(calendarId, eventId, event, accessToken);
  }

  /**
   * Delete an event
   */
  @Delete('calendars/:calendarId/events/:eventId')
  async deleteEvent(
    @Param('calendarId') calendarId: string,
    @Param('eventId') eventId: string,
    @Query('accessToken') accessToken: string,
  ): Promise<void> {
    return this.googleCalenderService.deleteEvent(calendarId, eventId, accessToken);
  }
}
