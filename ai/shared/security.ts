export class RateLimiter {
  private readonly calls = new Map<string, number[]>();

  constructor(
    private readonly maxCalls = 60,
    private readonly windowMs = 60_000,
  ) {}

  assertAllowed(key: string): void {
    const now = Date.now();
    const timestamps = this.calls.get(key) ?? [];
    const fresh = timestamps.filter((t) => now - t < this.windowMs);
    if (fresh.length >= this.maxCalls) {
      throw new Error('Rate limit exceeded');
    }
    fresh.push(now);
    this.calls.set(key, fresh);
  }
}

export function anonymizeText(input: string): string {
  return input
      .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[REDACTED_EMAIL]')
      .replace(/\b\d{8,}\b/g, '[REDACTED_NUMBER]')
      .replace(/\b(?:\+?\d{1,3})?[-.\s]?\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b/g, '[REDACTED_PHONE]');
}

export interface AuditLogger {
  log(event: string, payload: Record<string, unknown>): Promise<void>;
}

export class ConsoleAuditLogger implements AuditLogger {
  async log(event: string, payload: Record<string, unknown>): Promise<void> {
    // Replace with durable append-only sink in production.
    console.log('[AUDIT]', event, payload);
  }
}
