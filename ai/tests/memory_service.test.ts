import { describe, expect, it } from 'vitest';

import { MemoryService } from '../memory_system/memory_service';
import { ConsoleObserverService } from '../observer/observer_service';
import { InMemoryAiDataStore } from '../shared/data_store';
import { MemorySecurity } from '../shared/memory_security';

describe('memory service', () => {
  it('stores and retrieves anonymized user memory', async () => {
    const service = new MemoryService(
      new InMemoryAiDataStore(),
      new MemorySecurity(),
      new ConsoleObserverService(),
    );

    await service.store_user_memory({
      userId: 'user-123',
      conversationId: 'conv-1',
      userQuestion: 'My email is test@example.com',
      aiResponse: 'Drink water and rest',
      topic: 'hydration',
    });

    const rows = await service.retrieve_user_memory({
      userId: 'user-123',
      limit: 10,
    });
    expect(rows.length).toBe(1);
    expect(rows[0].user_question).toContain('[REDACTED_EMAIL]');
  });

  it('updates health profile and supports history/delete operations', async () => {
    const service = new MemoryService(
      new InMemoryAiDataStore(),
      new MemorySecurity(),
      new ConsoleObserverService(),
    );
    await service.update_health_profile({
      userId: 'user-abc',
      profile: { pregnancy_week: 28 },
    });
    await service.store_user_memory({
      userId: 'user-abc',
      conversationId: 'conv-x',
      userQuestion: 'Hello',
      aiResponse: 'Hi',
      topic: 'general',
    });
    const history = await service.retrieve_recent_history({
      conversationId: 'conv-x',
      limit: 5,
    });
    expect(history.length).toBe(1);
    const deleted = await service.delete_user_memory('user-abc');
    expect(deleted).toBeGreaterThanOrEqual(1);
  });
});
