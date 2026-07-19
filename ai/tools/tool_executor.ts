import { ObserverService } from '../observer/observer_service';
import { ToolExecutionResult } from '../shared/types';

export interface ToolDefinition<T = unknown> {
  name: string;
  execute: () => Promise<T>;
  fallback?: () => Promise<T>;
  timeoutMs?: number;
  retryAttempts?: number;
}

export class ToolExecutor {
  constructor(private readonly observer?: ObserverService) {}

  async executeParallel(
    tools: ToolDefinition[],
  ): Promise<ToolExecutionResult[]> {
    const startedAt = Date.now();
    const tasks = tools.map((tool) => this.runSingleTool(tool));
    const settled = await Promise.allSettled(tasks);
    const results = settled.map((entry, index) => {
      if (entry.status == 'fulfilled') return entry.value;
      return {
        tool: tools[index].name,
        success: false,
        latency_ms: 0,
        error: entry.reason instanceof Error ? entry.reason.message : String(entry.reason),
      } satisfies ToolExecutionResult;
    });

    if (this.observer) {
      const successful = results.filter((result) => result.success).length;
      await this.observer.track('tool_parallel_execution', {
        tool_count: tools.length,
        success_count: successful,
        failure_count: tools.length - successful,
        total_latency_ms: Date.now() - startedAt,
      });
    }

    return results;
  }

  private async runSingleTool(tool: ToolDefinition): Promise<ToolExecutionResult> {
    const startedAt = Date.now();
    const retries = Math.max(1, tool.retryAttempts ?? 2);
    let lastError: unknown;

    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        const response = await this.withTimeout(
          tool.execute(),
          tool.timeoutMs ?? 8000,
        );
        const latencyMs = Date.now() - startedAt;
        if (this.observer) {
          await this.observer.trackLatency(`tool:${tool.name}`, latencyMs);
          await this.observer.track('tool_success', {
            tool: tool.name,
            attempt,
            latency_ms: latencyMs,
          });
        }
        return {
          tool: tool.name,
          success: true,
          latency_ms: latencyMs,
          data: response,
        };
      } catch (error) {
        lastError = error;
      }
    }

    if (tool.fallback) {
      try {
        const fallbackData = await this.withTimeout(
          tool.fallback(),
          tool.timeoutMs ?? 8000,
        );
        const latencyMs = Date.now() - startedAt;
        if (this.observer) {
          await this.observer.track('tool_fallback_success', {
            tool: tool.name,
            latency_ms: latencyMs,
          });
        }
        return {
          tool: tool.name,
          success: true,
          latency_ms: latencyMs,
          data: fallbackData,
        };
      } catch (fallbackError) {
        lastError = fallbackError;
      }
    }

    const latencyMs = Date.now() - startedAt;
    if (this.observer) {
      await this.observer.track('tool_failure', {
        tool: tool.name,
        latency_ms: latencyMs,
        error: lastError instanceof Error ? lastError.message : String(lastError),
      });
    }

    return {
      tool: tool.name,
      success: false,
      latency_ms: latencyMs,
      error: lastError instanceof Error ? lastError.message : String(lastError),
    };
  }

  private withTimeout<T>(operation: Promise<T>, timeoutMs: number): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      const timer = setTimeout(
        () => reject(new Error(`Tool timeout after ${timeoutMs}ms`)),
        timeoutMs,
      );
      operation
        .then((result) => {
          clearTimeout(timer);
          resolve(result);
        })
        .catch((error) => {
          clearTimeout(timer);
          reject(error);
        });
    });
  }
}
