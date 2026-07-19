import { HttpRequest } from './http_types';
import { ObserverService } from '../observer/observer_service';
import { ThreatDetectionEngine } from '../security/threat_detection_engine';
import { anonymizeText } from '../shared/security';

export interface SecurityCheckResult {
  allowed: boolean;
  sanitized_request: HttpRequest;
  violations: string[];
  error_message?: string;
}

/**
 * API Security Layer
 *
 * Provides:
 * - Input sanitization
 * - Prompt injection detection
 * - Request size limits
 * - Malicious payload detection
 */
export class ApiSecurity {
  private readonly MAX_REQUEST_SIZE = 10_000; // characters
  private readonly MAX_MESSAGE_LENGTH = 5_000;

  // Prompt injection patterns
  private readonly INJECTION_PATTERNS = [
    /ignore\s+(previous|above|all)\s+(instructions|prompts|rules)/i,
    /forget\s+(everything|all|previous)/i,
    /system\s*:\s*override/i,
    /\[INST\]|\[\/INST\]/i,
    /<\|im_start\|>|<\|im_end\|>/i,
    /###\s*(system|assistant|user)\s*:/i,
    /roleplay|pretend|act as/i,
    /you are now/i,
    /new instructions/i,
  ];

  // Malicious payload patterns
  private readonly MALICIOUS_PATTERNS = [
    /<script[^>]*>/i,
    /javascript:/i,
    /on\w+\s*=/i,
    /eval\s*\(/i,
    /document\.(cookie|write)/i,
    /\.\.\/\.\.\//, // Path traversal
  ];

  constructor(
    private readonly threatEngine?: ThreatDetectionEngine,
    private readonly observer?: ObserverService,
  ) {}

  /**
   * Validates and sanitizes an HTTP request.
   */
  async validateRequest(req: HttpRequest): Promise<SecurityCheckResult> {
    const violations: string[] = [];
    let sanitized = { ...req };

    // 1. Check request size
    const requestSize = JSON.stringify(req.body).length;
    if (requestSize > this.MAX_REQUEST_SIZE) {
      violations.push('request_size_exceeded');
      return {
        allowed: false,
        sanitized_request: sanitized,
        violations,
        error_message: `Request size exceeds maximum of ${this.MAX_REQUEST_SIZE} characters`,
      };
    }

    // 2. Sanitize and validate message field
    if (req.body && typeof req.body === 'object') {
      const body = req.body as Record<string, unknown>;

      // Check message field
      if (body.message) {
        const message = String(body.message);

        // Check message length
        if (message.length > this.MAX_MESSAGE_LENGTH) {
          violations.push('message_length_exceeded');
        }

        // Check for prompt injection
        for (const pattern of this.INJECTION_PATTERNS) {
          if (pattern.test(message)) {
            violations.push('prompt_injection_detected');
          }
        }

        // Check for malicious payloads
        for (const pattern of this.MALICIOUS_PATTERNS) {
          if (pattern.test(message)) {
            violations.push('malicious_payload_detected');
          }
        }

        // Sanitize message (remove dangerous characters, anonymize PII)
        const sanitizedMessage = this.sanitizeInput(message);
        sanitized = {
          ...sanitized,
          body: {
            ...body,
            message: sanitizedMessage,
          },
        };
      }

      // Sanitize context if present
      if (body.context && typeof body.context === 'object') {
        const context = body.context as Record<string, unknown>;
        const sanitizedContext: Record<string, unknown> = {};
        for (const [key, value] of Object.entries(context)) {
          if (typeof value === 'string') {
            sanitizedContext[key] = this.sanitizeInput(value);
          } else {
            sanitizedContext[key] = value;
          }
        }
        sanitized = {
          ...sanitized,
          body: {
            ...body,
            context: sanitizedContext,
          },
        };
      }
    }

    // 3. Anonymize IP for logging
    sanitized = {
      ...sanitized,
      ip: anonymizeText(sanitized.ip),
    };

    const injectionDetected = violations.includes('prompt_injection_detected');
    const maliciousDetected = violations.includes('malicious_payload_detected');
    const payloadFingerprint = this.fingerprintPayload(req.body);

    if (this.threatEngine) {
      const threat = await this.threatEngine.assess({
        ip: req.ip,
        payloadFingerprint,
        isInjectionAttempt: injectionDetected,
        isMaliciousPayload: maliciousDetected,
      });
      if (threat.blocked) {
        violations.push('automated_threat_block');
        if (this.observer) {
          await this.observer.trackError(new Error('Threat blocked request'), {
            ip: anonymizeText(req.ip),
            reasons: threat.reasons,
            suspicious_score: threat.suspicious_score,
          });
        }
      }
    }

    const result: SecurityCheckResult = {
      allowed: violations.length === 0,
      sanitized_request: sanitized,
      violations,
      error_message:
        violations.length > 0
          ? `Security violations detected: ${violations.join(', ')}`
          : undefined,
    };

    if (this.observer) {
      await this.observer.track('security_check', {
        ip: sanitized.ip,
        allowed: result.allowed,
        violations: result.violations,
      });
    }

    return result;
  }

  /**
   * Sanitizes input string by removing dangerous characters and anonymizing PII.
   */
  private sanitizeInput(input: string): string {
    // Anonymize PII first
    let sanitized = anonymizeText(input);

    // Remove null bytes and control characters (except newlines and tabs)
    sanitized = sanitized.replace(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/g, '');

    // Remove potential SQL injection patterns (basic)
    sanitized = sanitized.replace(/['";\\]/g, '');

    // Trim and limit length
    sanitized = sanitized.trim().substring(0, this.MAX_MESSAGE_LENGTH);

    return sanitized;
  }

  /**
   * Creates a structured error response.
   */
  createErrorResponse(
    status: number,
    code: string,
    message: string,
    violations?: string[],
  ) {
    return {
      status,
      data: {
        success: false,
        error: {
          code,
          message,
          violations: violations ?? [],
          timestamp: new Date().toISOString(),
        },
      },
    };
  }

  withTimeout<T>(promise: Promise<T>, timeoutMs = 10_000): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error(`Request timed out after ${timeoutMs}ms`));
      }, timeoutMs);
      promise
        .then((result) => {
          clearTimeout(timeout);
          resolve(result);
        })
        .catch((error) => {
          clearTimeout(timeout);
          reject(error);
        });
    });
  }

  private fingerprintPayload(payload: unknown): string {
    const serialized = JSON.stringify(payload ?? {});
    let hash = 0;
    for (let i = 0; i < serialized.length; i++) {
      const code = serialized.charCodeAt(i);
      hash = (hash << 5) - hash + code;
      hash |= 0;
    }
    return `fp_${Math.abs(hash)}`;
  }
}

