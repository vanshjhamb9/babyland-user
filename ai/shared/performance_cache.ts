/**
 * Performance Cache
 *
 * Provides response and tool-result caching with:
 * - optional Redis adapter
 * - LRU in-memory fallback
 * - request deduplication
 */
export interface RedisLikeClient {
  get(key: string): Promise<string | null>;
  set(key: string, value: string, mode?: string, duration?: number): Promise<unknown>;
  del(key: string): Promise<unknown>;
}

export interface CacheObserver {
  trackCacheEvent(hit: boolean): Promise<void>;
}

export class PerformanceCache {
  private cache = new Map<string, { data: unknown; expiresAt: number; lastAccess: number }>();
  private inFlight = new Map<string, Promise<unknown>>();
  private hits = 0;
  private misses = 0;
  private evictions = 0;

  private readonly maxEntries: number;
  private readonly defaultTtlMs: number;
  private readonly redisClient?: RedisLikeClient;
  private readonly observer?: CacheObserver;

  constructor(params?: {
    defaultTtlMs?: number;
    maxEntries?: number;
    redisClient?: RedisLikeClient;
    observer?: CacheObserver;
  }) {
    // default 5 minutes
    this.maxEntries = params?.maxEntries ?? 1500;
    this.redisClient = params?.redisClient;
    this.observer = params?.observer;
    this.defaultTtlMs = params?.defaultTtlMs ?? 300_000;
  }

  /**
   * Gets cached value if available and not expired.
   */
  async get<T>(key: string): Promise<T | null> {
    if (this.redisClient) {
      const redisValue = await this.redisClient.get(key);
      if (redisValue != null) {
        this.hits++;
        if (this.observer) await this.observer.trackCacheEvent(true);
        return JSON.parse(redisValue) as T;
      }
    }

    const entry = this.cache.get(key);
    if (!entry) {
      this.misses++;
      if (this.observer) await this.observer.trackCacheEvent(false);
      return null;
    }

    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      this.misses++;
      if (this.observer) await this.observer.trackCacheEvent(false);
      return null;
    }

    entry.lastAccess = Date.now();
    this.hits++;
    if (this.observer) await this.observer.trackCacheEvent(true);
    return entry.data as T;
  }

  /**
   * Sets a cached value with optional TTL.
   */
  async set(key: string, value: unknown, ttlMs?: number): Promise<void> {
    const expiresAt = Date.now() + (ttlMs ?? this.defaultTtlMs);

    if (this.redisClient) {
      await this.redisClient.set(
        key,
        JSON.stringify(value),
        'PX',
        ttlMs ?? this.defaultTtlMs,
      );
    }

    this.cache.set(key, { data: value, expiresAt, lastAccess: Date.now() });
    this.enforceLruLimit();
  }

  /**
   * Generates cache key from request parameters.
   */
  generateKey(prefix: string, params: Record<string, unknown>): string {
    const sortedParams = Object.keys(params)
      .sort()
      .map((k) => `${k}=${JSON.stringify(params[k])}`)
      .join('&');
    return `${prefix}:${sortedParams}`;
  }

  generateToolKey(toolName: string, params: Record<string, unknown>): string {
    return this.generateKey(`tool:${toolName}`, params);
  }

  async getOrSet<T>(params: {
    key: string;
    ttlMs?: number;
    loader: () => Promise<T>;
  }): Promise<T> {
    const cached = await this.get<T>(params.key);
    if (cached != null) return cached;

    const existing = this.inFlight.get(params.key);
    if (existing) return (await existing) as T;

    const loaderPromise = params
      .loader()
      .then(async (value) => {
        await this.set(params.key, value, params.ttlMs);
        this.inFlight.delete(params.key);
        return value;
      })
      .catch((error) => {
        this.inFlight.delete(params.key);
        throw error;
      });

    this.inFlight.set(params.key, loaderPromise);
    return loaderPromise;
  }

  /**
   * Clears expired entries.
   */
  clearExpired(): void {
    const now = Date.now();
    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        this.cache.delete(key);
      }
    }
  }

  /**
   * Clears all cache.
   */
  async clear(): Promise<void> {
    this.cache.clear();
    this.inFlight.clear();
    if (this.redisClient) {
      // We don't delete all redis keys globally here to avoid impacting other modules.
      // Callers can manage namespace-based invalidation.
    }
  }

  /**
   * Gets cache statistics.
   */
  getStats() {
    const totalRequests = this.hits + this.misses;
    return {
      size: this.cache.size,
      hits: this.hits,
      misses: this.misses,
      evictions: this.evictions,
      cacheHitRate: totalRequests == 0 ? 0 : this.hits / totalRequests,
      entries: Array.from(this.cache.entries()).map(([key, entry]) => ({
        key,
        expiresAt: new Date(entry.expiresAt).toISOString(),
        expired: Date.now() > entry.expiresAt,
        lastAccess: new Date(entry.lastAccess).toISOString(),
      })),
    };
  }

  private enforceLruLimit(): void {
    if (this.cache.size <= this.maxEntries) return;
    const entries = Array.from(this.cache.entries());
    entries.sort((a, b) => a[1].lastAccess - b[1].lastAccess);
    const overflow = this.cache.size - this.maxEntries;
    for (let i = 0; i < overflow; i++) {
      this.cache.delete(entries[i][0]);
      this.evictions++;
    }
  }
}
