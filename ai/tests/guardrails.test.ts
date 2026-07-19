import { describe, expect, it } from 'vitest';

import { HallucinationChecker } from '../guardrails/hallucination_checker';
import { MedicalSafetyFilter } from '../guardrails/medical_safety_filter';
import { ResponseValidator } from '../guardrails/response_validator';
import { SafetySupervisor } from '../safety/safety_supervisor';

describe('guardrails', () => {
  it('detects hallucination-heavy claims', () => {
    const checker = new HallucinationChecker();
    const score = checker.check(
      'You definitely have this disease and you are diagnosed with severe pathology.',
    );
    expect(score).toBeGreaterThan(0.5);
  });

  it('blocks diagnosis and prescription language', () => {
    const filter = new MedicalSafetyFilter();
    const result = filter.filter(
      'Diagnosis: You have a disease. Take 500mg medicine daily.',
    );
    expect(result.violations.length).toBeGreaterThan(0);
    expect(result.filtered_response).toContain(
      'This AI provides general pregnancy guidance',
    );
  });

  it('validates response with supervisor + hallucination + medical filter', () => {
    const validator = new ResponseValidator(
      new SafetySupervisor(),
      new HallucinationChecker(),
      new MedicalSafetyFilter(),
    );
    const result = validator.validate(
      'You are diagnosed with a disease. stop seeing your doctor.',
    );
    expect(result.valid).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
    expect(result.sanitized_response).toContain(
      'does not replace medical professionals',
    );
  });
});
