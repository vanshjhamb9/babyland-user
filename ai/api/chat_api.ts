import { randomUUID } from 'crypto';

import { EvaluationService } from '../evaluation_engine/evaluation_service';
import { ResponseValidator } from '../guardrails/response_validator';
import { MemoryService } from '../memory_system/memory_service';
import { ObserverService } from '../observer/observer_service';
import { PerformanceCache } from '../shared/performance_cache';
import { RateLimiter } from '../shared/security';
import { assertNonEmptyString } from '../shared/validation';
import { ToolExecutor } from '../tools/tool_executor';
import { HttpRequest, HttpResponse } from './http_types';

export class ChatApi {
  constructor(
    private readonly rateLimiter: RateLimiter,
    private readonly evaluator: EvaluationService,
    private readonly validator: ResponseValidator,
    private readonly memoryService: MemoryService,
    private readonly observer: ObserverService,
    private readonly cache: PerformanceCache,
    private readonly toolExecutor: ToolExecutor,
  ) {}

  async postChat(
    request: HttpRequest,
  ): Promise<HttpResponse<{ success: boolean; data?: unknown; error?: string }>> {
    const start = Date.now();
    try {
      this.rateLimiter.assertAllowed(`chat:${request.ip}`);
      const payload = (request.body ?? {}) as Record<string, unknown>;
      const message = assertNonEmptyString(payload.message, 'message');
      const conversationId =
        typeof payload.conversation_id == 'string' && payload.conversation_id.length > 0
          ? payload.conversation_id
          : randomUUID();
      const userId =
        typeof payload.user_id == 'string' && payload.user_id.length > 0
          ? payload.user_id
          : `anon_${request.ip}`;

      const cacheKey = this.cache.generateKey('chat', {
        userId,
        conversationId,
        message,
      });

      const generatedResponse = await this.cache.getOrSet({
        key: cacheKey,
        ttlMs: 90_000,
        loader: async () => {
          const toolsInput =
            Array.isArray(payload.tools) && payload.tools.length > 0
              ? payload.tools
              : ['risk-check', 'guidance'];
          const tools = toolsInput
            .map((tool) => String(tool))
            .filter((tool) => ['risk-check', 'guidance', 'nutrition'].includes(tool))
            .map((toolName) => this.createTool(toolName, message));
          const toolResults = await this.toolExecutor.executeParallel(tools);
          const summaries = toolResults
            .filter((result) => result.success && typeof result.data == 'string')
            .map((result) => result.data as string);
          if (typeof payload.mock_response == 'string' && payload.mock_response.length > 0) {
            return payload.mock_response;
          }
          return [
            `I understand your concern: ${message}.`,
            ...summaries,
            'Please monitor symptoms and consult a doctor if they worsen.',
          ].join(' ');
        },
      });

      const validation = this.validator.validate(generatedResponse);
      const responseText = validation.sanitized_response;
      const latency = Date.now() - start;
      const tokenUsage = Math.ceil((message.length + responseText.length) / 4);

      const evaluation = await this.evaluator.evaluateResponse({
        conversation_id: conversationId,
        user_id: userId,
        query: message,
        ai_response: responseText,
        latency,
        token_usage: tokenUsage,
      });

      await this.memoryService.store_user_memory({
        userId,
        conversationId,
        userQuestion: message,
        aiResponse: responseText,
        topic:
          typeof payload.topic == 'string' && payload.topic.length > 0
            ? payload.topic
            : 'general',
      });

      await this.observer.trackLatency('ai_request', latency);
      await this.observer.trackTokenUsage(tokenUsage);
      await this.observer.trackEvaluationScore(evaluation.response_quality);
      await this.observer.trackHallucinationRate(
        evaluation.hallucination_probability,
      );

      return {
        status: 200,
        data: {
          success: true,
          data: {
            conversation_id: conversationId,
            reply: responseText,
            validation,
            evaluation,
          },
        },
      };
    } catch (error) {
      return {
        status: 400,
        data: {
          success: false,
          error: error instanceof Error ? error.message : 'Unknown chat error',
        },
      };
    }
  }

  private createTool(toolName: string, message: string) {
    switch (toolName) {
      case 'risk-check':
        return {
          name: 'risk-check',
          execute: async () =>
            /bleeding|fever|pain|fainting|vision/i.test(message)
              ? 'Potential elevated risk detected. Escalate with medical guidance.'
              : 'No acute risk signals detected from current message.',
        };
      case 'nutrition':
        return {
          name: 'nutrition',
          execute: async () =>
            'Nutrition guidance: prioritize hydration, protein, iron-rich foods, and prenatal vitamins.',
        };
      case 'guidance':
      default:
        return {
          name: 'guidance',
          execute: async () =>
            'General guidance: keep a symptom log and schedule follow-up with your care team.',
        };
    }
  }
}
