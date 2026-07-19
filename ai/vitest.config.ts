import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: [
        'guardrails/**/*.ts',
        'api/api_security.ts',
        'api/chat_api.ts',
        'api/feedback_api.ts',
        'api/ai_dashboard_api.ts',
        'evaluation_engine/**/*.ts',
        'memory_system/**/*.ts',
        'prompt_optimizer/**/*.ts',
        'shared/performance_cache.ts',
        'tools/tool_executor.ts',
        'security/threat_detection_engine.ts',
      ],
      thresholds: {
        lines: 85,
        functions: 85,
        branches: 72,
        statements: 85,
      },
    },
  },
});
