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
    responseStatus?: 'needsAction' | 'declined' | 'tentative' | 'accepted';
  }>;
  reminders?: {
    useDefault: boolean;
    overrides?: Array<{
      method: 'email' | 'popup';
      minutes: number;
    }>;
  };
  conferenceData?: {
    createRequest?: {
      requestId: string;
      conferenceSolutionKey?: {
        type: string;
      };
    };
  };
}

export interface CalendarList {
  id: string;
  summary: string;
  description?: string;
  location?: string;
  timeZone: string;
  primary?: boolean;
  selected?: boolean;
  accessRole: 'owner' | 'reader' | 'writer' | 'freeBusyReader';
  backgroundColor?: string;
  foregroundColor?: string;
  hidden?: boolean;
  deleted?: boolean;
  summaryOverride?: string;
  colorId?: string;
}

export interface CalendarEventCreateRequest {
  summary: string;
  description?: string;
  location?: string;
  start: {
    dateTime: string;
    timeZone?: string;
  };
  end: {
    dateTime: string;
    timeZone?: string;
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
  conferenceData?: {
    createRequest: {
      requestId: string;
    };
  };
}

export interface CalendarEventUpdateRequest extends Partial<CalendarEventCreateRequest> {}

export interface CalendarListRequest {
  timeMin?: string;
  timeMax?: string;
  maxResults?: number;
  singleEvents?: boolean;
  orderBy?: 'startTime' | 'updated';
  showDeleted?: boolean;
  showHiddenInvitations?: boolean;
}

export interface CalendarEventResponse {
  success: boolean;
  event?: CalendarEvent;
  events?: CalendarEvent[];
  error?: string;
  message?: string;
}

export interface CalendarListResponse {
  success: boolean;
  calendars?: CalendarList[];
  calendar?: CalendarList;
  error?: string;
  message?: string;
}
