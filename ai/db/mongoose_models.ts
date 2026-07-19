import { Schema, model, models } from 'mongoose';

const evaluationSchema = new Schema(
  {
    id: { type: String, required: true, index: true, unique: true },
    conversation_id: { type: String, required: true, index: true },
    query: { type: String, required: true },
    ai_response: { type: String, required: true },
    response_quality: { type: Number, required: true, min: 0, max: 1 },
    medical_accuracy: { type: Number, required: true, min: 0, max: 1 },
    safety_score: { type: Number, required: true, min: 0, max: 1 },
    risk_handling_score: { type: Number, required: true, min: 0, max: 1 },
    hallucination_probability: { type: Number, required: true, min: 0, max: 1 },
    latency: { type: Number, required: true, min: 0, index: true },
    token_usage: { type: Number, required: true, min: 0 },
    flags: [{ type: String }],
    created_at: { type: String, required: true, index: true },
  },
  { collection: 'ai_response_evaluations' },
);
evaluationSchema.index({ conversation_id: 1, created_at: -1 });
evaluationSchema.index({ safety_score: 1, hallucination_probability: 1 });

const feedbackSchema = new Schema(
  {
    id: { type: String, required: true, index: true, unique: true },
    conversation_id: { type: String, required: true, index: true },
    rating: { type: String, required: true, enum: ['positive', 'negative'] },
    comment: { type: String },
    created_at: { type: String, required: true, index: true },
  },
  { collection: 'ai_user_feedback' },
);
feedbackSchema.index({ conversation_id: 1, created_at: -1 });

const promptVersionSchema = new Schema(
  {
    id: { type: String, required: true, index: true, unique: true },
    version: { type: Number, required: true, index: true },
    prompt: { type: String, required: true },
    source: { type: String, required: true, enum: ['manual', 'optimizer'] },
    status: { type: String, required: true, enum: ['draft', 'active', 'archived'] },
    metadata: { type: Schema.Types.Mixed },
    created_at: { type: String, required: true, index: true },
  },
  { collection: 'ai_prompt_versions' },
);
promptVersionSchema.index({ version: -1 });

const weeklyInsightSchema = new Schema(
  {
    id: { type: String, required: true, index: true, unique: true },
    generated_at: { type: String, required: true, index: true },
    most_searched_symptoms: [{ type: String }],
    high_risk_trends: [{ type: String }],
    user_engagement_patterns: [{ type: String }],
    common_diet_questions: [{ type: String }],
  },
  { collection: 'weekly_ai_insights' },
);
weeklyInsightSchema.index({ generated_at: -1 });

const memorySchema = new Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    user_hash: { type: String, required: true, index: true },
    conversation_id: { type: String, required: true, index: true },
    user_question: { type: String, required: true },
    ai_response: { type: String, required: true },
    topic: { type: String, required: true, index: true },
    health_profile_delta: { type: Schema.Types.Mixed },
    created_at: { type: String, required: true, index: true },
  },
  { collection: 'ai_memory_records' },
);
memorySchema.index({ user_hash: 1, created_at: -1 });
memorySchema.index({ conversation_id: 1, created_at: -1 });

const healthProfileSchema = new Schema(
  {
    user_hash: { type: String, required: true, unique: true, index: true },
    profile: { type: Schema.Types.Mixed, required: true },
    updated_at: { type: String, required: true, index: true },
  },
  { collection: 'ai_health_profiles' },
);

export const EvaluationModel =
  models.EvaluationModel ?? model('EvaluationModel', evaluationSchema);
export const FeedbackModel =
  models.FeedbackModel ?? model('FeedbackModel', feedbackSchema);
export const PromptVersionModel =
  models.PromptVersionModel ?? model('PromptVersionModel', promptVersionSchema);
export const WeeklyInsightModel =
  models.WeeklyInsightModel ?? model('WeeklyInsightModel', weeklyInsightSchema);
export const MemoryModel = models.MemoryModel ?? model('MemoryModel', memorySchema);
export const HealthProfileModel =
  models.HealthProfileModel ?? model('HealthProfileModel', healthProfileSchema);
