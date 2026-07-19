import mongoose from 'mongoose';

import {
  EvaluationModel,
  FeedbackModel,
  HealthProfileModel,
  MemoryModel,
  PromptVersionModel,
  WeeklyInsightModel,
} from '../db/mongoose_models';

async function run() {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    throw new Error('MONGO_URI is required');
  }

  await mongoose.connect(mongoUri);
  await Promise.all([
    EvaluationModel.syncIndexes(),
    FeedbackModel.syncIndexes(),
    PromptVersionModel.syncIndexes(),
    WeeklyInsightModel.syncIndexes(),
    MemoryModel.syncIndexes(),
    HealthProfileModel.syncIndexes(),
  ]);
  console.log('AI index migration completed successfully');
  await mongoose.disconnect();
}

run().catch((error) => {
  console.error('AI index migration failed', error);
  process.exit(1);
});
