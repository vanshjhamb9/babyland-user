import { describe, expect, it } from 'vitest';

import { ConsoleObserverService } from '../observer/observer_service';
import { ToolExecutor } from '../tools/tool_executor';

describe('tool executor', () => {
  it('executes tools in parallel and returns settled results', async () => {
    const executor = new ToolExecutor(new ConsoleObserverService());
    const results = await executor.executeParallel([
      {
        name: 'toolA',
        execute: async () => 'a',
      },
      {
        name: 'toolB',
        execute: async () => {
          await new Promise((resolve) => setTimeout(resolve, 30));
          return 'b';
        },
      },
    ]);
    expect(results.length).toBe(2);
    expect(results.every((r) => r.success)).toBe(true);
  });

  it('uses fallback when primary tool fails', async () => {
    const executor = new ToolExecutor();
    const [result] = await executor.executeParallel([
      {
        name: 'unstableTool',
        execute: async () => {
          throw new Error('boom');
        },
        fallback: async () => 'fallback',
      },
    ]);
    expect(result.success).toBe(true);
    expect(result.data).toBe('fallback');
  });

  it('returns failure when tool times out without fallback', async () => {
    const executor = new ToolExecutor();
    const [result] = await executor.executeParallel([
      {
        name: 'slowTool',
        execute: async () => {
          await new Promise((resolve) => setTimeout(resolve, 80));
          return 'slow';
        },
        timeoutMs: 10,
        retryAttempts: 1,
      },
    ]);
    expect(result.success).toBe(false);
    expect(result.error).toContain('timeout');
  });
});
