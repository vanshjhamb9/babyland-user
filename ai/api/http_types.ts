export interface HttpRequest {
  ip: string;
  body?: unknown;
  query?: Record<string, string | undefined>;
}

export interface HttpResponse<T = unknown> {
  status: number;
  data: T;
}
