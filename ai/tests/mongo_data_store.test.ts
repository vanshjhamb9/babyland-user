import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { MongoMemoryServer } from 'mongodb-memory-server';

import { MongoAiDataStore } from '../db/mongo_data_store';

const describeIfMongo =
  process.env.RUN_MONGO_TESTS == 'true' ? describe : describe.skip;

describeIfMongo('mongo data store', () => {
  let mongo: MongoMemoryServer;
  let store: MongoAiDataStore;

  beforeAll(async () => {
    mongo = await MongoMemoryServer.create();
    store = new MongoAiDataStore(mongo.getUri());
  }, 60_000);

  afterAll(async () => {
    if (mongo) {
      await mongo.stop();
    }
  });

  it('persists and retrieves evaluations', async () => {
    await store.insertEvaluation({
      id: 'eval1',
      conversation_id: 'conv1',
      query: 'Is nausea normal?',
      ai_response: 'It can be common in early pregnancy.',
      response_quality: 0.9,
      medical_accuracy: 0.9,
      safety_score: 0.95,
      risk_handling_score: 0.9,
      hallucination_probability: 0.05,
      latency: 800,
      token_usage: 120,
      flags: [],
      created_at: new Date().toISOString(),
    });

    const rows = await store.listEvaluations(5);
    expect(rows.length).toBeGreaterThan(0);
    expect(rows[0].conversation_id).toBe('conv1');
  });
});
