import { describe, expect, it } from 'vitest';

import { ThreatDetectionEngine } from '../security/threat_detection_engine';

describe('threat detection engine', () => {
  it('scores suspicious patterns and blocks high-threat behavior', async () => {
    const engine = new ThreatDetectionEngine();
    let latest = null as Awaited<ReturnType<typeof engine.assess>> | null;
    for (let i = 0; i < 6; i++) {
      latest = await engine.assess({
        ip: '10.0.0.1',
        payloadFingerprint: 'same_payload',
        isInjectionAttempt: true,
        isMaliciousPayload: true,
      });
    }
    expect(latest).not.toBeNull();
    expect((latest as any).suspicious_score).toBeGreaterThan(0.8);
    expect((latest as any).blocked).toBe(true);
  });
});
