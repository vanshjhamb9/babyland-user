import { MEDICAL_DISCLAIMER } from '../safety/safety_supervisor';

export interface MedicalFilterResult {
  filtered_response: string;
  violations: string[];
  requires_disclaimer: boolean;
}

/**
 * Medical Safety Filter
 *
 * Blocks diagnosis-style responses, medication prescriptions, and ensures
 * medical disclaimer is present.
 */
export class MedicalSafetyFilter {
  private readonly DIAGNOSIS_PATTERNS = [
    /you have\s+[a-z\s]+disease/i,
    /you are suffering from\s+[a-z\s]+/i,
    /you have been diagnosed with\s+[a-z\s]+/i,
    /diagnosis:\s+[a-z\s]+/i,
    /your condition is\s+[a-z\s]+disease/i,
    /you are diagnosed/i,
  ];

  private readonly PRESCRIPTION_PATTERNS = [
    /take\s+\d+mg\s+of\s+[a-z]+/i,
    /prescribe\s+[a-z\s]+/i,
    /you should take\s+[a-z\s]+medication/i,
    /medication:\s+[a-z\s]+/i,
    /prescription:\s+[a-z\s]+/i,
    /dosage:\s+[a-z\s]+/i,
  ];

  private readonly DOCTOR_REPLACEMENT_PATTERNS = [
    /stop seeing your doctor/i,
    /you don't need a doctor/i,
    /skip the doctor/i,
    /ignore medical advice/i,
    /don't consult/i,
  ];

  filter(response: string): MedicalFilterResult {
    const violations: string[] = [];
    let filtered = response;

    // Check for diagnosis patterns
    for (const pattern of this.DIAGNOSIS_PATTERNS) {
      if (pattern.test(filtered)) {
        violations.push('diagnosis_pattern_detected');
        filtered = this.removeDiagnosisClaims(filtered);
      }
    }

    // Check for prescription patterns
    for (const pattern of this.PRESCRIPTION_PATTERNS) {
      if (pattern.test(filtered)) {
        violations.push('prescription_pattern_detected');
        filtered = this.removePrescriptionClaims(filtered);
      }
    }

    // Check for doctor replacement patterns
    for (const pattern of this.DOCTOR_REPLACEMENT_PATTERNS) {
      if (pattern.test(filtered)) {
        violations.push('doctor_replacement_pattern_detected');
        filtered = this.removeDoctorReplacementClaims(filtered);
      }
    }

    // Ensure disclaimer is present
    const requiresDisclaimer = violations.length > 0 || !filtered.includes(MEDICAL_DISCLAIMER);
    if (requiresDisclaimer) {
      filtered = this.ensureDisclaimer(filtered);
    }

    return {
      filtered_response: filtered,
      violations,
      requires_disclaimer: requiresDisclaimer,
    };
  }

  private removeDiagnosisClaims(text: string): string {
    // Replace diagnosis claims with general guidance
    let cleaned = text;
    for (const pattern of this.DIAGNOSIS_PATTERNS) {
      cleaned = cleaned.replace(
        pattern,
        'If you are experiencing these symptoms, please consult a healthcare provider for proper evaluation.',
      );
    }
    return cleaned;
  }

  private removePrescriptionClaims(text: string): string {
    // Replace prescription claims with general guidance
    let cleaned = text;
    for (const pattern of this.PRESCRIPTION_PATTERNS) {
      cleaned = cleaned.replace(
        pattern,
        'Please consult your healthcare provider for appropriate treatment recommendations.',
      );
    }
    return cleaned;
  }

  private removeDoctorReplacementClaims(text: string): string {
    // Remove or replace doctor replacement claims
    let cleaned = text;
    for (const pattern of this.DOCTOR_REPLACEMENT_PATTERNS) {
      cleaned = cleaned.replace(
        pattern,
        'Always consult with your healthcare provider for medical decisions.',
      );
    }
    return cleaned;
  }

  private ensureDisclaimer(text: string): string {
    if (text.includes(MEDICAL_DISCLAIMER)) {
      return text;
    }
    return `${text}\n\n${MEDICAL_DISCLAIMER}`;
  }
}
