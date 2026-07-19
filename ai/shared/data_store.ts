import {
  EvaluationRecord,
  FeedbackRecord,
  HealthProfileRecord,
  MemoryRecord,
  PromptVersion,
  WeeklyInsight,
} from './types';

export interface AiDataStore {
  insertEvaluation(record: EvaluationRecord): Promise<void>;
  listEvaluations(limit?: number): Promise<EvaluationRecord[]>;
  insertFeedback(record: FeedbackRecord): Promise<void>;
  listFeedback(limit?: number): Promise<FeedbackRecord[]>;
  insertPromptVersion(record: PromptVersion): Promise<void>;
  listPromptVersions(): Promise<PromptVersion[]>;
  upsertWeeklyInsight(record: WeeklyInsight): Promise<void>;
  listWeeklyInsights(limit?: number): Promise<WeeklyInsight[]>;
  storeUserMemory(record: MemoryRecord): Promise<void>;
  retrieveUserMemory(
    userHash: string,
    topic?: string,
    limit?: number,
  ): Promise<MemoryRecord[]>;
  updateHealthProfile(record: HealthProfileRecord): Promise<void>;
  retrieveRecentHistory(
    conversationId: string,
    limit?: number,
  ): Promise<MemoryRecord[]>;
  deleteUserMemory(userHash: string): Promise<number>;
}

/**
 * In-memory store for local development and tests.
 * Replace this with Mongo/Postgres repository in production.
 */
export class InMemoryAiDataStore implements AiDataStore {
  private readonly evaluations: EvaluationRecord[] = [];
  private readonly feedback: FeedbackRecord[] = [];
  private readonly promptVersions: PromptVersion[] = [];
  private readonly weeklyInsights: WeeklyInsight[] = [];
  private readonly memoryRecords: MemoryRecord[] = [];
  private readonly healthProfiles = new Map<string, HealthProfileRecord>();

  async insertEvaluation(record: EvaluationRecord): Promise<void> {
    this.evaluations.unshift(record);
  }

  async listEvaluations(limit = 100): Promise<EvaluationRecord[]> {
    return this.evaluations.slice(0, limit);
  }

  async insertFeedback(record: FeedbackRecord): Promise<void> {
    this.feedback.unshift(record);
  }

  async listFeedback(limit = 200): Promise<FeedbackRecord[]> {
    return this.feedback.slice(0, limit);
  }

  async insertPromptVersion(record: PromptVersion): Promise<void> {
    this.promptVersions.unshift(record);
  }

  async listPromptVersions(): Promise<PromptVersion[]> {
    return [...this.promptVersions];
  }

  async upsertWeeklyInsight(record: WeeklyInsight): Promise<void> {
    const index = this.weeklyInsights.findIndex((e) => e.id === record.id);
    if (index >= 0) {
      this.weeklyInsights[index] = record;
      return;
    }
    this.weeklyInsights.unshift(record);
  }

  async listWeeklyInsights(limit = 12): Promise<WeeklyInsight[]> {
    return this.weeklyInsights.slice(0, limit);
  }

  async storeUserMemory(record: MemoryRecord): Promise<void> {
    this.memoryRecords.unshift(record);
  }

  async retrieveUserMemory(
    userHash: string,
    topic?: string,
    limit = 50,
  ): Promise<MemoryRecord[]> {
    return this.memoryRecords
      .filter((memory) => memory.user_hash == userHash)
      .filter((memory) => (topic ? memory.topic == topic : true))
      .slice(0, limit);
  }

  async updateHealthProfile(record: HealthProfileRecord): Promise<void> {
    this.healthProfiles.set(record.user_hash, record);
  }

  async retrieveRecentHistory(
    conversationId: string,
    limit = 20,
  ): Promise<MemoryRecord[]> {
    return this.memoryRecords
      .filter((memory) => memory.conversation_id == conversationId)
      .slice(0, limit);
  }

  async deleteUserMemory(userHash: string): Promise<number> {
    const before = this.memoryRecords.length;
    const kept = this.memoryRecords.filter((memory) => memory.user_hash != userHash);
    this.memoryRecords.length = 0;
    this.memoryRecords.push(...kept);
    this.healthProfiles.delete(userHash);
    return before - kept.length;
  }
}
