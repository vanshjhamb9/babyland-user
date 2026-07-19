import { PromptVersion } from '../shared/types';

export interface PromptTestResult {
  prompt_a_id: string;
  prompt_b_id: string;
  winner_prompt_id: string;
  sample_size: number;
  avg_quality_delta: number;
  avg_safety_delta: number;
}

export class PromptTestingEngine {
  runABTest(params: {
    promptA: PromptVersion;
    promptB: PromptVersion;
    qualityScoreA: number;
    qualityScoreB: number;
    safetyScoreA: number;
    safetyScoreB: number;
    sampleSize: number;
  }): PromptTestResult {
    const combinedA = (params.qualityScoreA + params.safetyScoreA) / 2;
    const combinedB = (params.qualityScoreB + params.safetyScoreB) / 2;
    const winner = combinedB > combinedA ? params.promptB.id : params.promptA.id;

    return {
      prompt_a_id: params.promptA.id,
      prompt_b_id: params.promptB.id,
      winner_prompt_id: winner,
      sample_size: params.sampleSize,
      avg_quality_delta: params.qualityScoreB - params.qualityScoreA,
      avg_safety_delta: params.safetyScoreB - params.safetyScoreA,
    };
  }
}
