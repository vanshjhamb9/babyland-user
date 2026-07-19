import { AiDashboardApi } from './api/ai_dashboard_api';
import { ChatApi } from './api/chat_api';
import { FeedbackApi } from './api/feedback_api';
import { HealthApi } from './api/health_api';
import { PrometheusApi } from './api/prometheus_api';
import { MongoAiDataStore } from './db/mongo_data_store';
import { HallucinationChecker } from './guardrails/hallucination_checker';
import { MedicalSafetyFilter } from './guardrails/medical_safety_filter';
import { ResponseValidator } from './guardrails/response_validator';
import { EvaluationService } from './evaluation_engine/evaluation_service';
import { ResponseScorer } from './evaluation_engine/response_scorer';
import { SafetyEvaluator } from './evaluation_engine/safety_evaluator';
import { FeedbackService } from './feedback_service';
import { InsightEngine } from './insight_engine/insight_engine';
import { ContinuousImprovementLoop } from './jobs/continuous_improvement_loop';
import { FailureDetector } from './learning_engine/failure_detector';
import { LearningAnalyzer } from './learning_engine/learning_analyzer';
import { PatternMiner } from './learning_engine/pattern_miner';
import { ConsoleObserverService } from './observer/observer_service';
import { PromptOptimizer } from './prompt_optimizer/prompt_optimizer';
import { PromptTestingEngine } from './prompt_optimizer/prompt_testing_engine';
import { PromptVersionManager } from './prompt_optimizer/prompt_version_manager';
import { SafetySupervisor } from './safety/safety_supervisor';
import { ThreatDetectionEngine } from './security/threat_detection_engine';
import {
  ConsoleAuditLogger,
  RateLimiter,
} from './shared/security';
import { InMemoryAiDataStore } from './shared/data_store';
import { MemorySecurity } from './shared/memory_security';
import { PerformanceCache } from './shared/performance_cache';
import { ToolExecutor } from './tools/tool_executor';
import { MemoryService } from './memory_system/memory_service';

export function createAiPlatform() {
  const dataStore = process.env.MONGO_URI
    ? new MongoAiDataStore(process.env.MONGO_URI)
    : new InMemoryAiDataStore();
  const observer = new ConsoleObserverService();
  const auditLogger = new ConsoleAuditLogger();
  const safetySupervisor = new SafetySupervisor();
  const threatDetectionEngine = new ThreatDetectionEngine(observer);
  const memorySecurity = new MemorySecurity();
  const performanceCache = new PerformanceCache({
    defaultTtlMs: Number.parseInt(process.env.CACHE_TTL_MS ?? '300000', 10),
    maxEntries: Number.parseInt(process.env.CACHE_MAX_ENTRIES ?? '2000', 10),
    observer,
  });
  const toolExecutor = new ToolExecutor(observer);

  // Guardrails layer
  const hallucinationChecker = new HallucinationChecker();
  const medicalSafetyFilter = new MedicalSafetyFilter();
  const responseValidator = new ResponseValidator(
    safetySupervisor,
    hallucinationChecker,
    medicalSafetyFilter,
  );

  const evaluationService = new EvaluationService(
    dataStore,
    new ResponseScorer(),
    new SafetyEvaluator(safetySupervisor),
    observer,
    auditLogger,
  );
  const feedbackService = new FeedbackService(dataStore, observer, auditLogger);
  const learningAnalyzer = new LearningAnalyzer(
    dataStore,
    new FailureDetector(),
    new PatternMiner(),
    observer,
  );
  const promptOptimizer = new PromptOptimizer(
    new PromptVersionManager(dataStore),
    new PromptTestingEngine(),
    observer,
  );
  const insightEngine = new InsightEngine(dataStore);
  const memoryService = new MemoryService(dataStore, memorySecurity, observer);

  const loop = new ContinuousImprovementLoop(
    evaluationService,
    feedbackService,
    learningAnalyzer,
    promptOptimizer,
    insightEngine,
    dataStore,
    observer,
  );

  const rateLimiter = new RateLimiter(120, 60_000);
  const dashboardApi = new AiDashboardApi(dataStore, rateLimiter, observer);
  const feedbackApi = new FeedbackApi(feedbackService, rateLimiter);
  const chatApi = new ChatApi(
    rateLimiter,
    evaluationService,
    responseValidator,
    memoryService,
    observer,
    performanceCache,
    toolExecutor,
  );
  const healthApi = new HealthApi(dataStore);
  const prometheusApi = new PrometheusApi(observer);

  return {
    loop,
    dashboardApi,
    feedbackApi,
    chatApi,
    healthApi,
    prometheusApi,
    services: {
      evaluationService,
      feedbackService,
      learningAnalyzer,
      promptOptimizer,
      insightEngine,
      safetySupervisor,
      responseValidator,
      hallucinationChecker,
      medicalSafetyFilter,
      memoryService,
      memorySecurity,
      performanceCache,
      toolExecutor,
      threatDetectionEngine,
    },
    observer,
  };
}
