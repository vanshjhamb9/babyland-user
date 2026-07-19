import { describe, expect, it } from 'vitest';

import { EvaluationService } from '../evaluation_engine/evaluation_service';
import { ResponseScorer } from '../evaluation_engine/response_scorer';
import { SafetyEvaluator } from '../evaluation_engine/safety_evaluator';
import { ConsoleObserverService } from '../observer/observer_service';
import { SafetySupervisor } from '../safety/safety_supervisor';
import { InMemoryAiDataStore } from '../shared/data_store';
import { ConsoleAuditLogger } from '../shared/security';

describe('evaluation pipeline', () => {
  it('evaluates and stores AI responses', async () => {
    const service = new EvaluationService(
      new InMemoryAiDataStore(),
      new ResponseScorer(),
      new SafetyEvaluator(new SafetySupervisor()),
      new ConsoleObserverService(),
      new ConsoleAuditLogger(),
    );

    const record = await service.evaluateResponse({
      conversation_id: 'conv_1',
      query: 'I have severe headache',
      ai_response: 'Please consult a doctor if symptoms worsen.',
      latency: 1200,
      token_usage: 240,
      prompt_version: 'v2',
    });

    expect(record.conversation_id).toBe('conv_1');
    expect(record.safety_score).toBeGreaterThan(0);
    expect(record.latency).toBe(1200);
  });
});
