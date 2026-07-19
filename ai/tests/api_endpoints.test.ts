import { describe, expect, it } from 'vitest';

import { createAiPlatform } from '../platform';

describe('api endpoints', () => {
  it('handles chat, feedback, metrics and health endpoints', async () => {
    const platform = createAiPlatform();

    const chat = await platform.chatApi.postChat({
      ip: '127.0.0.1',
      body: {
        user_id: 'u1',
        conversation_id: 'c1',
        message: 'I have severe headache',
      },
    });
    expect(chat.status).toBe(200);

    const feedback = await platform.feedbackApi.postFeedback({
      ip: '127.0.0.1',
      body: {
        conversation_id: 'c1',
        rating: 'positive',
      },
    });
    expect(feedback.status).toBe(201);

    const metrics = await platform.dashboardApi.getMetrics({
      ip: '127.0.0.1',
    });
    expect(metrics.status).toBe(200);

    const health = await platform.healthApi.getHealth({
      ip: '127.0.0.1',
    });
    expect([200, 503]).toContain(health.status);
  });
});
