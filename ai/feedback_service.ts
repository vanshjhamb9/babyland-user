import { randomUUID } from 'crypto';

import { ObserverService } from './observer/observer_service';
import { AiDataStore } from './shared/data_store';
import { AuditLogger, anonymizeText } from './shared/security';
import { FeedbackRecord } from './shared/types';
import { assertFeedbackRating, assertNonEmptyString } from './shared/validation';

export class FeedbackService {
  constructor(
    private readonly dataStore: AiDataStore,
    private readonly observer: ObserverService,
    private readonly auditLogger: AuditLogger,
  ) {}

  async collectFeedback(payload: {
    conversation_id: unknown;
    rating: unknown;
    comment?: unknown;
  }): Promise<FeedbackRecord> {
    const conversationId = assertNonEmptyString(
      payload.conversation_id,
      'conversation_id',
    );
    const rating = assertFeedbackRating(payload.rating);
    const comment =
      typeof payload.comment === 'string' && payload.comment.trim().length > 0
        ? anonymizeText(payload.comment.trim())
        : undefined;

    const record: FeedbackRecord = {
      id: randomUUID(),
      conversation_id: conversationId,
      rating,
      comment,
      created_at: new Date().toISOString(),
    };

    await this.dataStore.insertFeedback(record);
    await this.observer.track('feedback_received', {
      conversation_id: conversationId,
      rating,
      has_comment: Boolean(comment),
    });
    await this.auditLogger.log('ai.feedback.created', {
      feedback_id: record.id,
      conversation_id: record.conversation_id,
      rating: record.rating,
    });
    return record;
  }
}
