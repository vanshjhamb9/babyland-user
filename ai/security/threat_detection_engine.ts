import { ObserverService } from '../observer/observer_service';

export interface ThreatAssessment {
  suspicious_score: number;
  blocked: boolean;
  reasons: string[];
}

type RequestSignal = {
  ip: string;
  fingerprint: string;
  timestamp: number;
  isInjectionAttempt: boolean;
  isMaliciousPayload: boolean;
};

export class ThreatDetectionEngine {
  private readonly requestWindow = new Map<string, RequestSignal[]>();
  private readonly blockedIps = new Map<string, number>();

  constructor(
    private readonly observer?: ObserverService,
    private readonly blockDurationMs = 10 * 60 * 1000,
  ) {}

  async assess(params: {
    ip: string;
    payloadFingerprint: string;
    isInjectionAttempt: boolean;
    isMaliciousPayload: boolean;
  }): Promise<ThreatAssessment> {
    const now = Date.now();
    const reasons: string[] = [];
    let score = 0;

    const blockedUntil = this.blockedIps.get(params.ip);
    if (blockedUntil && blockedUntil > now) {
      return {
        suspicious_score: 1,
        blocked: true,
        reasons: ['ip_temporarily_blocked'],
      };
    }

    this.recordSignal({
      ip: params.ip,
      fingerprint: params.payloadFingerprint,
      timestamp: now,
      isInjectionAttempt: params.isInjectionAttempt,
      isMaliciousPayload: params.isMaliciousPayload,
    });

    if (params.isInjectionAttempt) {
      score += 0.4;
      reasons.push('prompt_injection_pattern');
    }
    if (params.isMaliciousPayload) {
      score += 0.4;
      reasons.push('malicious_payload_pattern');
    }

    const signals = this.getRecentSignals(params.ip, 60_000);
    if (signals.length > 80) {
      score += 0.35;
      reasons.push('rapid_request_burst');
    }

    const repeatedFingerprint = signals.filter(
      (s) => s.fingerprint == params.payloadFingerprint,
    ).length;
    if (repeatedFingerprint >= 6) {
      score += 0.25;
      reasons.push('repeated_abuse_pattern');
    }

    const injectionAttempts = signals.filter((s) => s.isInjectionAttempt).length;
    if (injectionAttempts >= 5) {
      score += 0.35;
      reasons.push('repeated_injection_attempts');
    }

    const suspiciousScore = Math.min(1, score);
    const blocked = suspiciousScore >= 0.85;
    if (blocked) {
      this.blockedIps.set(params.ip, now + this.blockDurationMs);
    }

    if (this.observer) {
      await this.observer.track('threat_detection', {
        ip: params.ip,
        suspicious_score: suspiciousScore,
        blocked,
        reasons,
      });
    }

    return {
      suspicious_score: suspiciousScore,
      blocked,
      reasons,
    };
  }

  private recordSignal(signal: RequestSignal): void {
    const records = this.requestWindow.get(signal.ip) ?? [];
    records.push(signal);
    const cutoff = Date.now() - 10 * 60 * 1000;
    this.requestWindow.set(
      signal.ip,
      records.filter((record) => record.timestamp >= cutoff),
    );
  }

  private getRecentSignals(ip: string, windowMs: number): RequestSignal[] {
    const records = this.requestWindow.get(ip) ?? [];
    const cutoff = Date.now() - windowMs;
    return records.filter((record) => record.timestamp >= cutoff);
  }
}
