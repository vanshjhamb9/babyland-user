import { ObserverService } from '../observer/observer_service';
import { AiDataStore } from '../shared/data_store';
import { LearningIssue } from '../shared/types';
import { FailureDetector } from './failure_detector';
import { PatternMiner } from './pattern_miner';

export interface WeeklyLearningReport {
  generated_at: string;
  total_evaluations: number;
  total_feedback: number;
  issues: LearningIssue[];
}

export class LearningAnalyzer {
  constructor(
    private readonly dataStore: AiDataStore,
    private readonly failureDetector: FailureDetector,
    private readonly patternMiner: PatternMiner,
    private readonly observer: ObserverService,
  ) {}

  async generateWeeklyReport(): Promise<WeeklyLearningReport> {
    const evaluations = await this.dataStore.listEvaluations(5000);
    const feedback = await this.dataStore.listFeedback(5000);

    const detected = this.failureDetector.detect(evaluations, feedback);
    const patterns = this.patternMiner.mine(evaluations);
    const issues = [...detected, ...patterns].sort(
      (a, b) => b.frequency - a.frequency,
    );

    const report: WeeklyLearningReport = {
      generated_at: new Date().toISOString(),
      total_evaluations: evaluations.length,
      total_feedback: feedback.length,
      issues,
    };

    await this.observer.track('weekly_learning_report_generated', {
      issues_count: report.issues.length,
      total_evaluations: report.total_evaluations,
      total_feedback: report.total_feedback,
    });
    return report;
  }
}
