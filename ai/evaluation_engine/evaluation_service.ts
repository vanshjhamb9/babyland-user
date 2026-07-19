import { randomUUID } from 'crypto';

import { ObserverService } from '../observer/observer_service';
import { AiDataStore } from '../shared/data_store';
import { AuditLogger, anonymizeText } from '../shared/security';
import { AiRequestContext, EvaluationRecord } from '../shared/types';
import { ResponseScorer } from './response_scorer';
import { SafetyEvaluator } from './safety_evaluator';

export class EvaluationService {
  constructor(
    private readonly dataStore: AiDataStore,
    private readonly responseScorer: ResponseScorer,
    private readonly safetyEvaluator: SafetyEvaluator,
    private readonly observer: ObserverService,
    private readonly auditLogger: AuditLogger,
  ) {}

  async evaluateResponse(context: AiRequestContext): Promise<EvaluationRecord> {
    const scored = this.responseScorer.score({
      query: context.query,
      aiResponse: context.ai_response,
      latency: context.latency,
      tokenUsage: context.token_usage,
    });

    const safety = this.safetyEvaluator.evaluate(
      context.query,
      context.ai_response,
    );

    const record: EvaluationRecord = {
      id: randomUUID(),
      conversation_id: context.conversation_id,
      query: anonymizeText(context.query),
      ai_response: anonymizeText(context.ai_response),
      response_quality: scored.response_quality,
      medical_accuracy: scored.medical_accuracy,
      safety_score: safety.safetyScore,
      risk_handling_score: safety.riskHandlingScore,
      hallucination_probability: safety.hallucinationProbability,
      latency: context.latency,
      token_usage: context.token_usage,
      flags: safety.violations,
      created_at: new Date().toISOString(),
    };

    await this.dataStore.insertEvaluation(record);
    await this.observer.trackLatency('ai_request', record.latency);
    await this.observer.trackTokenUsage(record.token_usage);
    await this.observer.trackEvaluationScore(record.response_quality);
    await this.observer.trackHallucinationRate(record.hallucination_probability);
    if (record.risk_handling_score < 0.7) {
      await this.observer.trackRiskAlert('HIGH');
    }
    if (context.prompt_version) {
      await this.observer.trackPromptPerformance(
        context.prompt_version,
        record.response_quality,
      );
    }
    await this.observer.track('evaluation_success', {
      conversation_id: context.conversation_id,
      safety_score: record.safety_score,
      hallucination_probability: record.hallucination_probability,
      risk_handling_score: record.risk_handling_score,
      latency: record.latency,
      token_usage: record.token_usage,
    });
    await this.auditLogger.log('ai.evaluation.created', {
      evaluation_id: record.id,
      conversation_id: record.conversation_id,
    });
    return record;
  }
}
