import { describe, expect, it } from 'vitest';

import { FeedbackService } from '../feedback_service';
import { InsightEngine } from '../insight_engine/insight_engine';
import { ContinuousImprovementLoop } from '../jobs/continuous_improvement_loop';
import { FailureDetector } from '../learning_engine/failure_detector';
import { LearningAnalyzer } from '../learning_engine/learning_analyzer';
import { PatternMiner } from '../learning_engine/pattern_miner';
import { ConsoleObserverService } from '../observer/observer_service';
import { PromptOptimizer } from '../prompt_optimizer/prompt_optimizer';
import { PromptTestingEngine } from '../prompt_optimizer/prompt_testing_engine';
import { PromptVersionManager } from '../prompt_optimizer/prompt_version_manager';
import { InMemoryAiDataStore } from '../shared/data_store';
import { ConsoleAuditLogger } from '../shared/security';
import { EvaluationService } from '../evaluation_engine/evaluation_service';
import { ResponseScorer } from '../evaluation_engine/response_scorer';
import { SafetyEvaluator } from '../evaluation_engine/safety_evaluator';
import { SafetySupervisor } from '../safety/safety_supervisor';

describe('feedback engine and self-improvement loop', () => {
  it('accepts feedback and keeps loop operational', async () => {
    const store = new InMemoryAiDataStore();
    const observer = new ConsoleObserverService();
    const feedbackService = new FeedbackService(store, observer, new ConsoleAuditLogger());
    const evaluationService = new EvaluationService(
      store,
      new ResponseScorer(),
      new SafetyEvaluator(new SafetySupervisor()),
      observer,
      new ConsoleAuditLogger(),
    );
    const loop = new ContinuousImprovementLoop(
      evaluationService,
      feedbackService,
      new LearningAnalyzer(store, new FailureDetector(), new PatternMiner(), observer),
      new PromptOptimizer(
        new PromptVersionManager(store),
        new PromptTestingEngine(),
        observer,
      ),
      new InsightEngine(store),
      store,
      observer,
    );

    await loop.onUserFeedback({
      conversation_id: 'conv-9',
      rating: 'negative',
      comment: 'response was too generic',
    });
    const feedbackRows = await store.listFeedback(10);
    expect(feedbackRows.length).toBe(1);
    expect(feedbackRows[0].rating).toBe('negative');
  });
});
