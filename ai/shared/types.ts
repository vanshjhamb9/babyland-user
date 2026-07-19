export type FeedbackRating = 'positive' | 'negative';
export type Severity = 'low' | 'medium' | 'high' | 'critical';
export type RiskLevel = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

export interface EvaluationMetrics {
  response_quality: number;
  medical_accuracy: number;
  safety_score: number;
  risk_handling_score: number;
  hallucination_probability: number;
  latency: number;
  token_usage: number;
}

export interface EvaluationRecord extends EvaluationMetrics {
  id: string;
  conversation_id: string;
  query: string;
  ai_response: string;
  created_at: string;
  flags: string[];
}

export interface FeedbackRecord {
  id: string;
  conversation_id: string;
  rating: FeedbackRating;
  comment?: string;
  created_at: string;
}

export interface LearningIssue {
  issue: string;
  frequency: number;
  severity: Severity;
}

export interface PromptVersion {
  id: string;
  version: number;
  prompt: string;
  source: 'manual' | 'optimizer';
  status: 'draft' | 'active' | 'archived';
  created_at: string;
  metadata?: Record<string, unknown>;
}

export interface WeeklyInsight {
  id: string;
  generated_at: string;
  most_searched_symptoms: string[];
  high_risk_trends: string[];
  user_engagement_patterns: string[];
  common_diet_questions: string[];
}

export interface AiMetricsSnapshot {
  daily_ai_users: number;
  average_response_time: number;
  risk_alert_count: number;
  ai_success_rate: number;
  ai_error_rate: number;
  user_satisfaction_score: number;
  hallucination_rate?: number;
  cache_hit_rate?: number;
  tool_success_rate?: number;
}

export interface AiRequestContext {
  conversation_id: string;
  user_id?: string;
  query: string;
  ai_response: string;
  latency: number;
  token_usage: number;
  prompt_version?: string;
  risk_level?: RiskLevel;
}

export interface MemoryRecord {
  id: string;
  user_hash: string;
  conversation_id: string;
  user_question: string;
  ai_response: string;
  topic: string;
  health_profile_delta?: Record<string, unknown>;
  created_at: string;
}

export interface HealthProfileRecord {
  user_hash: string;
  profile: Record<string, unknown>;
  updated_at: string;
}

export interface ToolExecutionResult<T = unknown> {
  tool: string;
  success: boolean;
  latency_ms: number;
  data?: T;
  error?: string;
}
