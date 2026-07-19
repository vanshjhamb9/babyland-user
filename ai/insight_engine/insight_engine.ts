import { randomUUID } from 'crypto';

import { AiDataStore } from '../shared/data_store';
import { EvaluationRecord, WeeklyInsight } from '../shared/types';

function topTerms(records: EvaluationRecord[], pattern: RegExp, limit = 5): string[] {
  const counts = new Map<string, number>();
  for (const r of records) {
    const text = r.query.toLowerCase();
    const matches = text.match(pattern) ?? [];
    for (const m of matches) {
      counts.set(m, (counts.get(m) ?? 0) + 1);
    }
  }
  return [...counts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([term]) => term);
}

export class InsightEngine {
  constructor(private readonly dataStore: AiDataStore) {}

  async generateWeeklyInsights(): Promise<WeeklyInsight> {
    const evaluations = await this.dataStore.listEvaluations(10000);
    const highRisk = evaluations.filter((e) => e.risk_handling_score < 0.7);

    const insight: WeeklyInsight = {
      id: randomUUID(),
      generated_at: new Date().toISOString(),
      most_searched_symptoms: topTerms(
        evaluations,
        /\b(headache|nausea|bleeding|fever|pain|dizziness)\b/g,
      ),
      high_risk_trends: topTerms(
        highRisk,
        /\b(bleeding|abdominal pain|blurred vision|severe headache|high fever)\b/g,
      ),
      user_engagement_patterns: [
        `total_evaluations:${evaluations.length}`,
        `high_risk_conversations:${highRisk.length}`,
      ],
      common_diet_questions: topTerms(
        evaluations.filter((e) => /diet|nutrition|eat/i.test(e.query)),
        /\b(diet|nutrition|protein|iron|vegetarian|calcium)\b/g,
      ),
    };

    await this.dataStore.upsertWeeklyInsight(insight);
    return insight;
  }
}
