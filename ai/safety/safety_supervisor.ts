const BLOCKED_PATTERNS = [
  /you have\s+[a-z\s]+disease/i,
  /take\s+\d+mg\s+of\s+[a-z]+/i,
  /stop seeing your doctor/i,
];

export const MEDICAL_DISCLAIMER =
  'This AI provides general pregnancy guidance and does not replace medical professionals.';

export interface SafetyCheckResult {
  allowed: boolean;
  violations: string[];
  safe_response: string;
}

export class SafetySupervisor {
  enforce(response: string): SafetyCheckResult {
    const violations: string[] = [];
    for (const rule of BLOCKED_PATTERNS) {
      if (rule.test(response)) {
        violations.push(`blocked_pattern:${rule.source}`);
      }
    }

    const safeResponse = this.ensureDisclaimer(
      violations.length > 0
        ? `${response}\n\nPlease consult a licensed doctor for diagnosis and treatment decisions.`
        : response,
    );

    return {
      allowed: violations.length === 0,
      violations,
      safe_response: safeResponse,
    };
  }

  ensureDisclaimer(response: string): string {
    if (response.includes(MEDICAL_DISCLAIMER)) return response;
    return `${response}\n\n${MEDICAL_DISCLAIMER}`;
  }
}
