import { describe, expect, it } from 'vitest';

import { PerformanceCache } from '../shared/performance_cache';

describe('performance cache', () => {
  it('caches and deduplicates concurrent loads', async () => {
    const cache = new PerformanceCache({ defaultTtlMs: 10_000 });
    let calls = 0;
    const key = cache.generateKey('ai', { q: 'nausea' });

    const loader = async () => {
      calls += 1;
      await new Promise((resolve) => setTimeout(resolve, 50));
      return { ok: true };
    };

    const [r1, r2, r3] = await Promise.all([
      cache.getOrSet({ key, loader }),
      cache.getOrSet({ key, loader }),
      cache.getOrSet({ key, loader }),
    ]);

    expect(r1).toEqual({ ok: true });
    expect(r2).toEqual({ ok: true });
    expect(r3).toEqual({ ok: true });
    expect(calls).toBe(1);
  });

  it('expires entries after ttl', async () => {
    const cache = new PerformanceCache({ defaultTtlMs: 10 });
    await cache.set('k1', 'v1');
    await new Promise((resolve) => setTimeout(resolve, 20));
    const value = await cache.get('k1');
    expect(value).toBeNull();
  });

  it('supports LRU eviction and utility methods', async () => {
    const cache = new PerformanceCache({
      defaultTtlMs: 1_000,
      maxEntries: 2,
    });
    await cache.set('a', 1);
    await cache.set('b', 2);
    await cache.get('a');
    await new Promise((resolve) => setTimeout(resolve, 2));
    await cache.set('c', 3); // should evict b (least recently used)
    const a = await cache.get('a');
    const b = await cache.get('b');
    const c = await cache.get('c');
    expect([a, b].filter((v) => v !== null).length).toBe(1);
    expect(c).toBe(3);
    expect(cache.generateToolKey('risk', { q: 'headache' })).toContain('tool:risk');
    cache.clearExpired();
    const stats = cache.getStats();
    expect(stats.size).toBeGreaterThanOrEqual(1);
  });

  it('uses redis adapter when provided', async () => {
    const memory = new Map<string, string>();
    const cache = new PerformanceCache({
      redisClient: {
        async get(key) {
          return memory.get(key) ?? null;
        },
        async set(key, value) {
          memory.set(key, value);
        },
        async del(key) {
          memory.delete(key);
        },
      },
    });
    await cache.set('redisKey', { hello: 'world' });
    const value = await cache.get<{ hello: string }>('redisKey');
    expect(value?.hello).toBe('world');
    await cache.clear();
  });
});
