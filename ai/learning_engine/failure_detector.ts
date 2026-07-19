import { EvaluationRecord, FeedbackRecord, LearningIssue } from '../shared/types';

export class FailureDetector {
  detect(
    evaluations: EvaluationRecord[],
    feedback: FeedbackRecord[],
  ): LearningIssue[] {
    const lowRatings = feedback.filter((f) => f.rating === 'negative').length;
    const highHallucinations = evaluations.filter(
      (e) => e.hallucination_probability > 0.3,
    ).length;
    const slowResponses = evaluations.filter((e) => e.latency > 3000).length;
    const highRiskMisses = evaluations.filter(
      (e) => e.risk_handling_score < 0.6,
    ).length;
    const safetyViolations = evaluations.filter((e) => e.flags.length > 0).length;

    const issues: LearningIssue[] = [];
    if (lowRatings > 0) {
      issues.push({
        issue: 'Low user ratings on AI responses',
        frequency: lowRatings,
        severity: lowRatings > 25 ? 'high' : 'medium',
      });
    }
    if (highHallucinations > 0) {
      issues.push({
        issue: 'High hallucination probability responses detected',
        frequency: highHallucinations,
        severity: highHallucinations > 20 ? 'high' : 'medium',
      });
    }
    if (slowResponses > 0) {
      issues.push({
        issue: 'Slow response latency trends',
        frequency: slowResponses,
        severity: slowResponses > 40 ? 'high' : 'medium',
      });
    }
    if (highRiskMisses > 0) {
      issues.push({
        issue: 'Risk handling weaknesses in high-risk conversations',
        frequency: highRiskMisses,
        severity: highRiskMisses > 8 ? 'critical' : 'high',
      });
    }
    if (safetyViolations > 0) {
      issues.push({
        issue: 'Safety violations detected',
        frequency: safetyViolations,
        severity: safetyViolations > 4 ? 'critical' : 'high',
      });
    }
    return issues;
  }
}
