import { FeedbackRating } from './types';

export function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`Invalid ${field}: non-empty string required`);
  }
  return value.trim();
}

export function assertFeedbackRating(value: unknown): FeedbackRating {
  if (value !== 'positive' && value !== 'negative') {
    throw new Error('Invalid rating: must be positive or negative');
  }
  return value;
}

export function assertFiniteNumber(value: unknown, field: string): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new Error(`Invalid ${field}: finite number required`);
  }
  return value;
}
