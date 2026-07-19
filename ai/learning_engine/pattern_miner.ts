import { EvaluationRecord, LearningIssue } from '../shared/types';

export class PatternMiner {
  mine(evaluations: EvaluationRecord[]): LearningIssue[] {
    const dietQueries = evaluations.filter((e) =>
      /diet|eat|nutrition/i.test(e.query),
    );
    const weakPersonalization = dietQueries.filter(
      (e) => e.response_quality < 0.75,
    ).length;

    const issueList: LearningIssue[] = [];
    if (weakPersonalization > 0) {
      issueList.push({
        issue: 'Diet advice sometimes lacks personalization',
        frequency: weakPersonalization,
        severity: weakPersonalization > 30 ? 'medium' : 'low',
      });
    }
    return issueList;
  }
}
