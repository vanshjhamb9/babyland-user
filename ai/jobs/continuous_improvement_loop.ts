import { EvaluationService } from '../evaluation_engine/evaluation_service';
import { FeedbackService } from '../feedback_service';
import { InsightEngine } from '../insight_engine/insight_engine';
import { LearningAnalyzer } from '../learning_engine/learning_analyzer';
import { ObserverService } from '../observer/observer_service';
import { PromptOptimizer } from '../prompt_optimizer/prompt_optimizer';
import { AiDataStore } from '../shared/data_store';
import { AiRequestContext } from '../shared/types';

export class ContinuousImprovementLoop {
  private dailyTimer?: NodeJS.Timeout;
  private weeklyTimer?: NodeJS.Timeout;
  private optimizeTimer?: NodeJS.Timeout;

  constructor(
    private readonly evaluationService: EvaluationService,
    private readonly feedbackService: FeedbackService,
    private readonly learningAnalyzer: LearningAnalyzer,
    private readonly promptOptimizer: PromptOptimizer,
    private readonly insightEngine: InsightEngine,
    private readonly dataStore: AiDataStore,
    private readonly observer: ObserverService,
  ) {}

  async onAiResponse(context: AiRequestContext): Promise<void> {
    await this.evaluationService.evaluateResponse(context);
  }

  async onUserFeedback(payload: {
    conversation_id: string;
    rating: 'positive' | 'negative';
    comment?: string;
  }): Promise<void> {
    await this.feedbackService.collectFeedback(payload);
  }

  startSchedulers(): void {
    const guarded = async (jobName: string, job: () => Promise<void>) => {
      try {
        await job();
      } catch (error) {
        await this.observer.track('scheduler_error', {
          job: jobName,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    };

    // daily evaluation analysis
    this.dailyTimer = setInterval(() => {
      void guarded('daily_evaluation_analysis', async () => {
      const evaluations = await this.dataStore.listEvaluations(5000);
      await this.observer.track('daily_evaluation_analysis', {
        total: evaluations.length,
      });
      });
    }, 24 * 60 * 60 * 1000);

    // weekly learning report and insights
    this.weeklyTimer = setInterval(() => {
      void guarded('weekly_learning_cycle', async () => {
      const report = await this.learningAnalyzer.generateWeeklyReport();
      const insights = await this.insightEngine.generateWeeklyInsights();
      await this.observer.track('weekly_learning_cycle', {
        issues_count: report.issues.length,
        insights_id: insights.id,
      });
      });
    }, 7 * 24 * 60 * 60 * 1000);

    // prompt optimization cycle (every 3 days)
    this.optimizeTimer = setInterval(() => {
      void guarded('prompt_optimization_cycle', async () => {
      const evaluations = await this.dataStore.listEvaluations(4000);
      const report = await this.learningAnalyzer.generateWeeklyReport();
      const result = await this.promptOptimizer.optimize({
        currentPrompt:
          'You are a pregnancy assistant. Provide safe and practical guidance.',
        evaluations,
        issues: report.issues,
      });
      await this.observer.track('prompt_optimization_cycle', {
        optimized_prompt_version: result.created_version.version,
        winner_prompt_id: result.ab_test?.winner_prompt_id,
      });
      });
    }, 3 * 24 * 60 * 60 * 1000);
  }

  stopSchedulers(): void {
    if (this.dailyTimer) clearInterval(this.dailyTimer);
    if (this.weeklyTimer) clearInterval(this.weeklyTimer);
    if (this.optimizeTimer) clearInterval(this.optimizeTimer);
  }
}
