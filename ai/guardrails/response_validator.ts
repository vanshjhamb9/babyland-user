import { SafetyCheckResult } from '../safety/safety_supervisor';
import { SafetySupervisor } from '../safety/safety_supervisor';
import { HallucinationChecker } from './hallucination_checker';
import { MedicalSafetyFilter } from './medical_safety_filter';

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  sanitized_response: string;
  safety_check: SafetyCheckResult;
  hallucination_score: number;
  medical_violations: string[];
}

export class ResponseValidator {
  private safetySupervisor: SafetySupervisor;
  private hallucinationChecker: HallucinationChecker;
  private medicalSafetyFilter: MedicalSafetyFilter;

  constructor(
    safetySupervisor: SafetySupervisor,
    hallucinationChecker: HallucinationChecker,
    medicalSafetyFilter: MedicalSafetyFilter,
  ) {
    this.safetySupervisor = safetySupervisor;
    this.hallucinationChecker = hallucinationChecker;
    this.medicalSafetyFilter = medicalSafetyFilter;
  }

  validate(response: string): ValidationResult {
    const errors: string[] = [];
    let sanitized = response;

    // 1. Safety Supervisor Check
    const safetyCheck = this.safetySupervisor.enforce(sanitized);
    if (!safetyCheck.allowed) {
      errors.push(...safetyCheck.violations);
    }
    sanitized = safetyCheck.safe_response;

    // 2. Hallucination Check
    const hallucinationScore = this.hallucinationChecker.check(sanitized);
    if (hallucinationScore > 0.7) {
      errors.push(`high_hallucination_probability:${hallucinationScore.toFixed(2)}`);
    }

    // 3. Medical Safety Filter
    const medicalCheck = this.medicalSafetyFilter.filter(sanitized);
    if (medicalCheck.violations.length > 0) {
      errors.push(...medicalCheck.violations);
    }
    sanitized = medicalCheck.filtered_response;

    return {
      valid: errors.length === 0,
      errors,
      sanitized_response: sanitized,
      safety_check: safetyCheck,
      hallucination_score: hallucinationScore,
      medical_violations: medicalCheck.violations,
    };
  }
}
