import { EvaluationMetrics } from '../shared/types';

export function clampScore(value: number): number {
  if (Number.isNaN(value)) return 0;
  return Math.min(1, Math.max(0, value));
}

export function createEvaluationMetrics(
  metrics: Partial<EvaluationMetrics>,
): EvaluationMetrics {
  return {
    response_quality: clampScore(metrics.response_quality ?? 0),
    medical_accuracy: clampScore(metrics.medical_accuracy ?? 0),
    safety_score: clampScore(metrics.safety_score ?? 0),
    risk_handling_score: clampScore(metrics.risk_handling_score ?? 0),
    hallucination_probability: clampScore(metrics.hallucination_probability ?? 0),
    latency: Math.max(0, metrics.latency ?? 0),
    token_usage: Math.max(0, metrics.token_usage ?? 0),
  };
}
