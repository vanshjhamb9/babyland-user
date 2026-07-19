import { FeedbackService } from '../feedback_service';
import { RateLimiter } from '../shared/security';
import { HttpRequest, HttpResponse } from './http_types';

export class FeedbackApi {
  constructor(
    private readonly feedbackService: FeedbackService,
    private readonly rateLimiter: RateLimiter,
  ) {}

  async postFeedback(
    request: HttpRequest,
  ): Promise<HttpResponse<{ success: boolean; feedback_id?: string; error?: string }>> {
    try {
      this.rateLimiter.assertAllowed(`feedback:${request.ip}`);
      const payload = (request.body ?? {}) as Record<string, unknown>;
      const record = await this.feedbackService.collectFeedback({
        conversation_id: payload.conversation_id,
        rating: payload.rating,
        comment: payload.comment,
      });
      return {
        status: 201,
        data: { success: true, feedback_id: record.id },
      };
    } catch (error) {
      return {
        status: 400,
        data: {
          success: false,
          error: error instanceof Error ? error.message : 'Unknown error',
        },
      };
    }
  }
}
