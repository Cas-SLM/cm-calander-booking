export interface ProjectErrorMessageInterface {
  message: string;
  status: number;
}

export interface ProjectExceptionInterface {
  getErrorMessage(): ProjectErrorMessageInterface;
}
