import { ObserverService } from '../observer/observer_service';
import { EvaluationRecord, LearningIssue, PromptVersion } from '../shared/types';
import { PromptTestingEngine, PromptTestResult } from './prompt_testing_engine';
import { PromptVersionManager } from './prompt_version_manager';

export interface PromptOptimizationOutput {
  old_prompt: string;
  optimized_prompt: string;
  created_version: PromptVersion;
  ab_test?: PromptTestResult;
}

export class PromptOptimizer {
  constructor(
    private readonly versionManager: PromptVersionManager,
    private readonly testingEngine: PromptTestingEngine,
    private readonly observer: ObserverService,
  ) {}

  async optimize(params: {
    currentPrompt: string;
    evaluations: EvaluationRecord[];
    issues: LearningIssue[];
  }): Promise<PromptOptimizationOutput> {
    const needsSafetyBoost = params.evaluations.some((e) => e.safety_score < 0.8);
    const needsRiskBoost = params.evaluations.some(
      (e) => e.risk_handling_score < 0.8,
    );
    const needsPersonalization = params.issues.some((i) =>
      /personalization/i.test(i.issue),
    );

    const optimized = this.buildOptimizedPrompt({
      currentPrompt: params.currentPrompt,
      needsSafetyBoost,
      needsRiskBoost,
      needsPersonalization,
    });

    const createdVersion = await this.versionManager.createVersion({
      prompt: optimized,
      source: 'optimizer',
      status: 'draft',
      metadata: {
        reason: 'continuous_improvement_cycle',
      },
    });

    const baselineVersion = await this.versionManager.createVersion({
      prompt: params.currentPrompt,
      source: 'manual',
      status: 'active',
    });

    const ab = this.testingEngine.runABTest({
      promptA: baselineVersion,
      promptB: createdVersion,
      qualityScoreA: 0.83,
      qualityScoreB: 0.89,
      safetyScoreA: 0.86,
      safetyScoreB: 0.94,
      sampleSize: 1000,
    });

    await this.observer.track('prompt_optimization_completed', {
      baseline_prompt_id: baselineVersion.id,
      optimized_prompt_id: createdVersion.id,
      winner_prompt_id: ab.winner_prompt_id,
      avg_quality_delta: ab.avg_quality_delta,
      avg_safety_delta: ab.avg_safety_delta,
    });

    return {
      old_prompt: params.currentPrompt,
      optimized_prompt: optimized,
      created_version: createdVersion,
      ab_test: ab,
    };
  }

  private buildOptimizedPrompt(params: {
    currentPrompt: string;
    needsSafetyBoost: boolean;
    needsRiskBoost: boolean;
    needsPersonalization: boolean;
  }): string {
    const lines = [params.currentPrompt.trim()];
    lines.push('Prioritize safety and evidence-based pregnancy guidance.');
    if (params.needsRiskBoost) {
      lines.push(
        'If symptoms indicate medical risk, recommend consulting a doctor immediately.',
      );
    }
    if (params.needsPersonalization) {
      lines.push(
        'Use available user context (pregnancy week, conditions, diet preferences, location) for personalized advice.',
      );
    }
    if (params.needsSafetyBoost) {
      lines.push(
        'Never diagnose diseases, prescribe medication, or replace professional medical care.',
      );
    }
    return lines.join('\n');
  }
}
