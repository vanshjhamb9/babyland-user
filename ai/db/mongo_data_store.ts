import mongoose from 'mongoose';

import { AiDataStore } from '../shared/data_store';
import {
  EvaluationRecord,
  FeedbackRecord,
  HealthProfileRecord,
  MemoryRecord,
  PromptVersion,
  WeeklyInsight,
} from '../shared/types';
import { decryptField, encryptField } from './field_encryption';
import {
  EvaluationModel,
  FeedbackModel,
  HealthProfileModel,
  MemoryModel,
  PromptVersionModel,
  WeeklyInsightModel,
} from './mongoose_models';

export class MongoAiDataStore implements AiDataStore {
  private connected = false;
  private connectPromise?: Promise<void>;

  constructor(private readonly mongoUri: string) {}

  private async ensureConnected(): Promise<void> {
    if (this.connected) return;
    if (!this.connectPromise) {
      this.connectPromise = mongoose.connect(this.mongoUri).then(async () => {
        this.connected = true;
        await Promise.all([
          EvaluationModel.syncIndexes(),
          FeedbackModel.syncIndexes(),
          PromptVersionModel.syncIndexes(),
          WeeklyInsightModel.syncIndexes(),
          MemoryModel.syncIndexes(),
          HealthProfileModel.syncIndexes(),
        ]);
      });
    }
    await this.connectPromise;
  }

  async insertEvaluation(record: EvaluationRecord): Promise<void> {
    await this.ensureConnected();
    await EvaluationModel.create({
      ...record,
      query: encryptField(record.query),
      ai_response: encryptField(record.ai_response),
    });
  }

  async listEvaluations(limit = 100): Promise<EvaluationRecord[]> {
    await this.ensureConnected();
    const docs = await EvaluationModel.find().sort({ created_at: -1 }).limit(limit).lean();
    return docs.map((doc: any) => ({
      ...doc,
      query: decryptField(doc.query),
      ai_response: decryptField(doc.ai_response),
    })) as EvaluationRecord[];
  }

  async insertFeedback(record: FeedbackRecord): Promise<void> {
    await this.ensureConnected();
    await FeedbackModel.create({
      ...record,
      comment: record.comment ? encryptField(record.comment) : undefined,
    });
  }

  async listFeedback(limit = 200): Promise<FeedbackRecord[]> {
    await this.ensureConnected();
    const docs = await FeedbackModel.find().sort({ created_at: -1 }).limit(limit).lean();
    return docs.map((doc: any) => ({
      ...doc,
      comment: doc.comment ? decryptField(doc.comment) : undefined,
    })) as FeedbackRecord[];
  }

  async insertPromptVersion(record: PromptVersion): Promise<void> {
    await this.ensureConnected();
    await PromptVersionModel.create(record);
  }

  async listPromptVersions(): Promise<PromptVersion[]> {
    await this.ensureConnected();
    const docs = await PromptVersionModel.find().sort({ version: -1 }).lean();
    return docs as unknown as PromptVersion[];
  }

  async upsertWeeklyInsight(record: WeeklyInsight): Promise<void> {
    await this.ensureConnected();
    await WeeklyInsightModel.updateOne({ id: record.id }, record, { upsert: true });
  }

  async listWeeklyInsights(limit = 12): Promise<WeeklyInsight[]> {
    await this.ensureConnected();
    const docs = await WeeklyInsightModel.find()
      .sort({ generated_at: -1 })
      .limit(limit)
      .lean();
    return docs as unknown as WeeklyInsight[];
  }

  async storeUserMemory(record: MemoryRecord): Promise<void> {
    await this.ensureConnected();
    await MemoryModel.create({
      ...record,
      user_question: encryptField(record.user_question),
      ai_response: encryptField(record.ai_response),
      topic: encryptField(record.topic),
    });
  }

  async retrieveUserMemory(
    userHash: string,
    topic?: string,
    limit = 50,
  ): Promise<MemoryRecord[]> {
    await this.ensureConnected();
    const docs = await MemoryModel.find({
      user_hash: userHash,
      ...(topic ? { topic: encryptField(topic) } : {}),
    })
      .sort({ created_at: -1 })
      .limit(limit)
      .lean();
    return docs.map((doc: any) => ({
      ...doc,
      user_question: decryptField(doc.user_question),
      ai_response: decryptField(doc.ai_response),
      topic: decryptField(doc.topic),
    })) as MemoryRecord[];
  }

  async updateHealthProfile(record: HealthProfileRecord): Promise<void> {
    await this.ensureConnected();
    await HealthProfileModel.updateOne(
      { user_hash: record.user_hash },
      {
        user_hash: record.user_hash,
        profile: record.profile,
        updated_at: record.updated_at,
      },
      { upsert: true },
    );
  }

  async retrieveRecentHistory(
    conversationId: string,
    limit = 20,
  ): Promise<MemoryRecord[]> {
    await this.ensureConnected();
    const docs = await MemoryModel.find({ conversation_id: conversationId })
      .sort({ created_at: -1 })
      .limit(limit)
      .lean();
    return docs.map((doc: any) => ({
      ...doc,
      user_question: decryptField(doc.user_question),
      ai_response: decryptField(doc.ai_response),
      topic: decryptField(doc.topic),
    })) as MemoryRecord[];
  }

  async deleteUserMemory(userHash: string): Promise<number> {
    await this.ensureConnected();
    const deleteResult = await MemoryModel.deleteMany({ user_hash: userHash });
    await HealthProfileModel.deleteOne({ user_hash: userHash });
    return deleteResult.deletedCount ?? 0;
  }
}
