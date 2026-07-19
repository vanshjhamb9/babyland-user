export interface ObserverService {
  track(eventType: string, payload: Record<string, unknown>): Promise<void>;
  trackLatency(operation: string, latencyMs: number): Promise<void>;
  trackTokenUsage(tokens: number): Promise<void>;
  trackEvaluationScore(score: number): Promise<void>;
  trackRiskAlert(riskLevel: string): Promise<void>;
  trackPromptPerformance(promptVersion: string, score: number): Promise<void>;
  trackHallucinationRate(probability: number): Promise<void>;
  trackToolResult(tool: string, success: boolean, latencyMs: number): Promise<void>;
  trackCacheEvent(hit: boolean): Promise<void>;
  trackError(error: Error, context?: Record<string, unknown>): Promise<void>;
  exportPrometheusMetrics(): string;
}

export class ConsoleObserverService implements ObserverService {
  private metrics: {
    latency: Map<string, number[]>;
    tokenUsage: number[];
    evaluationScores: number[];
    riskAlerts: Map<string, number>;
    promptPerformance: Map<string, number[]>;
    hallucinationRates: number[];
    toolSuccess: Map<string, { success: number; failure: number; latencies: number[] }>;
    cache: { hits: number; misses: number };
    errors: number;
  } = {
    latency: new Map(),
    tokenUsage: [],
    evaluationScores: [],
    riskAlerts: new Map(),
    promptPerformance: new Map(),
    hallucinationRates: [],
    toolSuccess: new Map(),
    cache: { hits: 0, misses: 0 },
    errors: 0,
  };

  async track(eventType: string, payload: Record<string, unknown>): Promise<void> {
    // Replace with your centralized AI telemetry sink.
    console.log('[OBSERVER]', eventType, payload);
  }

  async trackLatency(operation: string, latencyMs: number): Promise<void> {
    const latencies = this.metrics.latency.get(operation) ?? [];
    latencies.push(latencyMs);
    if (latencies.length > 1000) latencies.shift(); // Keep last 1000
    this.metrics.latency.set(operation, latencies);
    await this.track('latency', { operation, latencyMs });
  }

  async trackTokenUsage(tokens: number): Promise<void> {
    this.metrics.tokenUsage.push(tokens);
    if (this.metrics.tokenUsage.length > 1000) this.metrics.tokenUsage.shift();
    await this.track('token_usage', { tokens });
  }

  async trackEvaluationScore(score: number): Promise<void> {
    this.metrics.evaluationScores.push(score);
    if (this.metrics.evaluationScores.length > 1000) this.metrics.evaluationScores.shift();
    await this.track('evaluation_score', { score });
  }

  async trackRiskAlert(riskLevel: string): Promise<void> {
    const count = this.metrics.riskAlerts.get(riskLevel) ?? 0;
    this.metrics.riskAlerts.set(riskLevel, count + 1);
    await this.track('risk_alert', { riskLevel });
  }

  async trackPromptPerformance(promptVersion: string, score: number): Promise<void> {
    const scores = this.metrics.promptPerformance.get(promptVersion) ?? [];
    scores.push(score);
    if (scores.length > 1000) scores.shift();
    this.metrics.promptPerformance.set(promptVersion, scores);
    await this.track('prompt_performance', { promptVersion, score });
  }

  async trackHallucinationRate(probability: number): Promise<void> {
    this.metrics.hallucinationRates.push(probability);
    if (this.metrics.hallucinationRates.length > 1000) {
      this.metrics.hallucinationRates.shift();
    }
    await this.track('hallucination_probability', { probability });
  }

  async trackToolResult(
    tool: string,
    success: boolean,
    latencyMs: number,
  ): Promise<void> {
    const metric = this.metrics.toolSuccess.get(tool) ?? {
      success: 0,
      failure: 0,
      latencies: [],
    };
    if (success) metric.success += 1;
    else metric.failure += 1;
    metric.latencies.push(latencyMs);
    if (metric.latencies.length > 1000) metric.latencies.shift();
    this.metrics.toolSuccess.set(tool, metric);
    await this.track('tool_result', { tool, success, latency_ms: latencyMs });
  }

  async trackCacheEvent(hit: boolean): Promise<void> {
    if (hit) this.metrics.cache.hits += 1;
    else this.metrics.cache.misses += 1;
    await this.track('cache_event', { hit });
  }

  async trackError(error: Error, context?: Record<string, unknown>): Promise<void> {
    this.metrics.errors++;
    await this.track('error', {
      error: error.message,
      stack: error.stack,
      ...context,
    });
  }

  getMetrics() {
    const avgLatency = (op: string) => {
      const latencies = this.metrics.latency.get(op) ?? [];
      return latencies.length > 0
        ? latencies.reduce((a, b) => a + b, 0) / latencies.length
        : 0;
    };

    const avgTokenUsage =
      this.metrics.tokenUsage.length > 0
        ? this.metrics.tokenUsage.reduce((a, b) => a + b, 0) / this.metrics.tokenUsage.length
        : 0;

    const avgEvaluationScore =
      this.metrics.evaluationScores.length > 0
        ? this.metrics.evaluationScores.reduce((a, b) => a + b, 0) /
          this.metrics.evaluationScores.length
        : 0;

    return {
      latency: {
        ai_request: avgLatency('ai_request'),
        memory_retrieval: avgLatency('memory_retrieval'),
        tool_execution: avgLatency('tool_execution'),
      },
      tokenUsage: {
        average: avgTokenUsage,
        total: this.metrics.tokenUsage.reduce((a, b) => a + b, 0),
      },
      evaluationScores: {
        average: avgEvaluationScore,
        count: this.metrics.evaluationScores.length,
      },
      riskAlerts: Object.fromEntries(this.metrics.riskAlerts),
      promptPerformance: Object.fromEntries(
        Array.from(this.metrics.promptPerformance.entries()).map(([v, scores]) => [
          v,
          scores.length > 0 ? scores.reduce((a, b) => a + b, 0) / scores.length : 0,
        ]),
      ),
      hallucinationRate: {
        average:
          this.metrics.hallucinationRates.length > 0
            ? this.metrics.hallucinationRates.reduce((a, b) => a + b, 0) /
              this.metrics.hallucinationRates.length
            : 0,
        count: this.metrics.hallucinationRates.length,
      },
      toolSuccessRate: Object.fromEntries(
        Array.from(this.metrics.toolSuccess.entries()).map(([tool, v]) => [
          tool,
          {
            success_rate:
              v.success + v.failure == 0 ? 0 : v.success / (v.success + v.failure),
            average_latency:
              v.latencies.length > 0
                ? v.latencies.reduce((a, b) => a + b, 0) / v.latencies.length
                : 0,
          },
        ]),
      ),
      cache: {
        hits: this.metrics.cache.hits,
        misses: this.metrics.cache.misses,
        hit_rate:
          this.metrics.cache.hits + this.metrics.cache.misses == 0
            ? 0
            : this.metrics.cache.hits /
              (this.metrics.cache.hits + this.metrics.cache.misses),
      },
      errors: this.metrics.errors,
    };
  }

  exportPrometheusMetrics(): string {
    const m = this.getMetrics() as any;
    const lines: string[] = [];
    lines.push('# HELP ai_latency_ms Average AI latency in milliseconds');
    lines.push('# TYPE ai_latency_ms gauge');
    lines.push(`ai_latency_ms{operation="ai_request"} ${m.latency.ai_request}`);
    lines.push(
      `ai_latency_ms{operation="memory_retrieval"} ${m.latency.memory_retrieval}`,
    );
    lines.push(`ai_latency_ms{operation="tool_execution"} ${m.latency.tool_execution}`);
    lines.push('# HELP ai_token_usage_average Average token usage');
    lines.push('# TYPE ai_token_usage_average gauge');
    lines.push(`ai_token_usage_average ${m.tokenUsage.average}`);
    lines.push('# HELP ai_hallucination_rate_average Average hallucination probability');
    lines.push('# TYPE ai_hallucination_rate_average gauge');
    lines.push(`ai_hallucination_rate_average ${m.hallucinationRate.average}`);
    lines.push('# HELP ai_cache_hit_rate Cache hit rate');
    lines.push('# TYPE ai_cache_hit_rate gauge');
    lines.push(`ai_cache_hit_rate ${m.cache.hit_rate}`);
    lines.push('# HELP ai_observer_errors_total Observer error count');
    lines.push('# TYPE ai_observer_errors_total counter');
    lines.push(`ai_observer_errors_total ${m.errors}`);
    return lines.join('\n');
  }
}
