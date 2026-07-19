import { anonymizeText } from './security';

/**
 * Memory Security Layer
 *
 * Ensures:
 * - PII anonymization
 * - Secure data handling
 * - Data retention policy enforcement
 * - Anonymized user identifiers
 */
export class MemorySecurity {
  /**
   * Anonymizes user identifiers to prevent PII leakage.
   */
  anonymizeUserId(userId: string): string {
    // Hash or anonymize user ID
    // In production, use a proper hashing function
    return `user_${this.hashString(userId)}`;
  }

  /**
   * Sanitizes memory content to remove PII.
   */
  sanitizeMemoryContent(content: string): string {
    // Anonymize emails, phones, numbers
    return anonymizeText(content);
  }

  /**
   * Validates that memory data doesn't contain sensitive PII.
   */
  validateMemoryData(data: {
    user_question?: string;
    ai_response?: string;
    topic?: string;
    [key: string]: unknown;
  }): { valid: boolean; violations: string[] } {
    const violations: string[] = [];

    // Check for potential PII in user question
    if (data.user_question) {
      const sanitized = this.sanitizeMemoryContent(data.user_question);
      if (sanitized !== data.user_question) {
        violations.push('pii_detected_in_user_question');
      }
    }

    // Check for potential PII in AI response
    if (data.ai_response) {
      const sanitized = this.sanitizeMemoryContent(data.ai_response);
      if (sanitized !== data.ai_response) {
        violations.push('pii_detected_in_ai_response');
      }
    }

    return {
      valid: violations.length === 0,
      violations,
    };
  }

  /**
   * Enforces data retention policy.
   * Returns true if data should be retained, false if it should be deleted.
   */
  shouldRetainData(timestamp: Date, retentionDays: number = 365): boolean {
    const ageInDays = (Date.now() - timestamp.getTime()) / (1000 * 60 * 60 * 24);
    return ageInDays <= retentionDays;
  }

  /**
   * Simple hash function for user ID anonymization.
   * In production, use crypto.createHash('sha256').
   */
  private hashString(str: string): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash).toString(36);
  }
}
