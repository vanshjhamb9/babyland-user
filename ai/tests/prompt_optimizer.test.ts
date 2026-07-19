import { describe, expect, it } from 'vitest';

import { ConsoleObserverService } from '../observer/observer_service';
import { PromptOptimizer } from '../prompt_optimizer/prompt_optimizer';
import { PromptTestingEngine } from '../prompt_optimizer/prompt_testing_engine';
import { PromptVersionManager } from '../prompt_optimizer/prompt_version_manager';
import { InMemoryAiDataStore } from '../shared/data_store';

describe('prompt optimizer', () => {
  it('creates optimized prompt versions with A/B test output', async () => {
    const optimizer = new PromptOptimizer(
      new PromptVersionManager(new InMemoryAiDataStore()),
      new PromptTestingEngine(),
      new ConsoleObserverService(),
    );

    const result = await optimizer.optimize({
      currentPrompt: 'You are a pregnancy assistant.',
      evaluations: [
        {
          id: '1',
          conversation_id: 'c1',
          query: 'diet tips',
          ai_response: 'general response',
          response_quality: 0.6,
          medical_accuracy: 0.7,
          safety_score: 0.6,
          risk_handling_score: 0.5,
          hallucination_probability: 0.2,
          latency: 900,
          token_usage: 120,
          flags: [],
          created_at: new Date().toISOString(),
        },
      ],
      issues: [
        {
          issue: 'Diet advice sometimes lacks personalization',
          frequency: 37,
          severity: 'medium',
        },
      ],
    });

    expect(result.created_version.version).toBeGreaterThan(0);
    expect(result.optimized_prompt).toContain('evidence-based');
    expect(result.ab_test?.winner_prompt_id).toBeDefined();
  });
});
