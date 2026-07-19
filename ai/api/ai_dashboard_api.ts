import { ObserverService } from '../observer/observer_service';
import { AiDataStore } from '../shared/data_store';
import { RateLimiter } from '../shared/security';
import { AiMetricsSnapshot } from '../shared/types';
import { HttpRequest, HttpResponse } from './http_types';

export class AiDashboardApi {
  constructor(
    private readonly dataStore: AiDataStore,
    private readonly rateLimiter: RateLimiter,
    private readonly observer?: ObserverService,
  ) {}

  async getMetrics(
    request: HttpRequest,
  ): Promise<HttpResponse<AiMetricsSnapshot | { error: string }>> {
    try {
      this.rateLimiter.assertAllowed(`metrics:${request.ip}`);
      const evaluations = await this.dataStore.listEvaluations(10000);
      const feedback = await this.dataStore.listFeedback(10000);
      const uniqueConversations = new Set(
        evaluations.map((evaluation) => evaluation.conversation_id),
      );
      const avgLatency =
        evaluations.length === 0
          ? 0
          : evaluations.reduce((sum, e) => sum + e.latency, 0) /
            evaluations.length;
      const riskAlerts = evaluations.filter(
        (evaluation) => evaluation.risk_handling_score < 0.7,
      ).length;
      const successCount = evaluations.filter(
        (evaluation) => evaluation.safety_score >= 0.8,
      ).length;
      const errorCount = evaluations.length - successCount;
      const positiveFeedback = feedback.filter(
        (feedbackEntry) => feedbackEntry.rating === 'positive',
      ).length;
      const satisfaction =
        feedback.length === 0 ? 0 : positiveFeedback / feedback.length;

      return {
        status: 200,
        data: {
          daily_ai_users: uniqueConversations.size,
          average_response_time: Number(avgLatency.toFixed(2)),
          risk_alert_count: riskAlerts,
          ai_success_rate:
            evaluations.length === 0 ? 0 : successCount / evaluations.length,
          ai_error_rate:
            evaluations.length === 0 ? 0 : errorCount / evaluations.length,
          user_satisfaction_score: Number(satisfaction.toFixed(4)),
          hallucination_rate:
            evaluations.length === 0
              ? 0
              : evaluations.reduce(
                  (sum, evaluation) => sum + evaluation.hallucination_probability,
                  0,
                ) / evaluations.length,
          cache_hit_rate: this.observer
            ? (this.observer as any).getMetrics?.().cache?.hit_rate ?? 0
            : 0,
          tool_success_rate: this.observer
            ? this.calculateGlobalToolSuccess((this.observer as any).getMetrics?.())
            : 0,
        },
      };
    } catch (error) {
      return {
        status: 429,
        data: {
          error: error instanceof Error ? error.message : 'Unknown error',
        },
      };
    }
  }

  async getInsights(
    request: HttpRequest,
  ): Promise<HttpResponse<unknown[] | { error: string }>> {
    try {
      this.rateLimiter.assertAllowed(`insights:${request.ip}`);
      const insights = await this.dataStore.listWeeklyInsights(12);
      return { status: 200, data: insights };
    } catch (error) {
      return {
        status: 429,
        data: {
          error: error instanceof Error ? error.message : 'Unknown error',
        },
      };
    }
  }

  async getEvaluations(
    request: HttpRequest,
  ): Promise<HttpResponse<unknown[] | { error: string }>> {
    try {
      this.rateLimiter.assertAllowed(`evaluations:${request.ip}`);
      const limitParam = request.query?.limit;
      const limit =
        typeof limitParam === 'string' ? Number.parseInt(limitParam, 10) : 50;
      const evaluations = await this.dataStore.listEvaluations(
        Number.isFinite(limit) && limit > 0 ? Math.min(limit, 500) : 50,
      );
      return { status: 200, data: evaluations };
    } catch (error) {
      return {
        status: 429,
        data: {
          error: error instanceof Error ? error.message : 'Unknown error',
        },
      };
    }
  }

  private calculateGlobalToolSuccess(observerMetrics: any): number {
    const entries = Object.values(observerMetrics?.toolSuccessRate ?? {}) as Array<{
      success_rate: number;
    }>;
    if (entries.length == 0) return 0;
    return entries.reduce((sum, entry) => sum + entry.success_rate, 0) / entries.length;
  }
}
