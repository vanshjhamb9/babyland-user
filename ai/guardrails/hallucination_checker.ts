/**
 * Hallucination Checker
 *
 * Detects potentially hallucinated medical claims in AI responses.
 * Uses pattern matching and claim verification heuristics.
 */

const HALLUCINATION_PATTERNS = [
  // Unsupported medical claims
  /you definitely have\s+[a-z\s]+/i,
  /this is definitely\s+[a-z\s]+disease/i,
  /you are diagnosed with\s+[a-z\s]+/i,
  /you have been diagnosed/i,
  /confirmed diagnosis/i,
  /medical test shows\s+[a-z\s]+/i,
  /your blood test indicates\s+[a-z\s]+/i,
  /ultrasound confirms\s+[a-z\s]+/i,
  // Overly specific medical claims without evidence
  /exactly\s+\d+\.\d+\s+[a-z\s]+condition/i,
  /precisely\s+[a-z\s]+disease/i,
  // Unsupported medication claims
  /you must take\s+[a-z\s]+medication/i,
  /prescribed\s+[a-z\s]+for you/i,
  /your doctor will prescribe\s+[a-z\s]+/i,
];

const MEDICAL_CLAIM_INDICATORS = [
  'diagnosis',
  'diagnosed',
  'disease',
  'condition',
  'disorder',
  'syndrome',
  'pathology',
  'prescription',
  'medication',
  'treatment plan',
];

export class HallucinationChecker {
  /**
   * Checks response for hallucinated medical claims.
   * Returns score 0.0 (no hallucination) to 1.0 (high hallucination probability).
   */
  check(response: string): number {
    const lowerResponse = response.toLowerCase();
    let score = 0.0;

    // Pattern matching
    for (const pattern of HALLUCINATION_PATTERNS) {
      if (pattern.test(response)) {
        score += 0.3;
      }
    }

    // Medical claim density check
    const claimCount = MEDICAL_CLAIM_INDICATORS.filter((indicator) =>
      lowerResponse.includes(indicator),
    ).length;
    if (claimCount > 2) {
      score += 0.2;
    }

    // Overly confident language
    const confidenceMarkers = [
      'definitely',
      'certainly',
      'absolutely',
      'confirmed',
      'proven',
      'guaranteed',
    ];
    const confidenceCount = confidenceMarkers.filter((marker) =>
      lowerResponse.includes(marker),
    ).length;
    if (confidenceCount > 1) {
      score += 0.2;
    }

    // Length vs claim ratio (very short responses with many claims are suspicious)
    const wordCount = response.split(/\s+/).length;
    if (wordCount < 50 && claimCount > 1) {
      score += 0.1;
    }

    return Math.min(1.0, score);
  }

  /**
   * Checks if response contains any hallucinated claims.
   */
  hasHallucination(response: string): boolean {
    return this.check(response) > 0.5;
  }
}
