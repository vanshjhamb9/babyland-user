import { randomUUID } from 'crypto';

import { ObserverService } from '../observer/observer_service';
import { AiDataStore } from '../shared/data_store';
import { MemorySecurity } from '../shared/memory_security';
import { HealthProfileRecord, MemoryRecord } from '../shared/types';

export class MemoryService {
  constructor(
    private readonly dataStore: AiDataStore,
    private readonly security: MemorySecurity,
    private readonly observer?: ObserverService,
  ) {}

  async store_user_memory(params: {
    userId: string;
    conversationId: string;
    userQuestion: string;
    aiResponse: string;
    topic: string;
    healthProfileDelta?: Record<string, unknown>;
  }): Promise<MemoryRecord> {
    const userHash = this.security.anonymizeUserId(params.userId);
    const sanitizedQuestion = this.security.sanitizeMemoryContent(params.userQuestion);
    const sanitizedResponse = this.security.sanitizeMemoryContent(params.aiResponse);
    const record: MemoryRecord = {
      id: randomUUID(),
      user_hash: userHash,
      conversation_id: params.conversationId,
      user_question: sanitizedQuestion,
      ai_response: sanitizedResponse,
      topic: this.security.sanitizeMemoryContent(params.topic),
      health_profile_delta: params.healthProfileDelta,
      created_at: new Date().toISOString(),
    };
    await this.dataStore.storeUserMemory(record);
    if (this.observer) {
      await this.observer.track('memory_store', {
        user_hash: userHash,
        conversation_id: record.conversation_id,
        topic: record.topic,
      });
      await this.observer.trackLatency('memory_store', 1);
    }
    return record;
  }

  async retrieve_user_memory(params: {
    userId: string;
    topic?: string;
    limit?: number;
  }): Promise<MemoryRecord[]> {
    const userHash = this.security.anonymizeUserId(params.userId);
    return this.dataStore.retrieveUserMemory(userHash, params.topic, params.limit);
  }

  async update_health_profile(params: {
    userId: string;
    profile: Record<string, unknown>;
  }): Promise<void> {
    const userHash = this.security.anonymizeUserId(params.userId);
    const record: HealthProfileRecord = {
      user_hash: userHash,
      profile: params.profile,
      updated_at: new Date().toISOString(),
    };
    await this.dataStore.updateHealthProfile(record);
  }

  async retrieve_recent_history(params: {
    conversationId: string;
    limit?: number;
  }): Promise<MemoryRecord[]> {
    return this.dataStore.retrieveRecentHistory(params.conversationId, params.limit);
  }

  async delete_user_memory(userId: string): Promise<number> {
    const userHash = this.security.anonymizeUserId(userId);
    return this.dataStore.deleteUserMemory(userHash);
  }
}
