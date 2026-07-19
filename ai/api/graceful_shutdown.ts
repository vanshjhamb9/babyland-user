import type { Server } from 'http';

interface LoopController {
  stopSchedulers: () => void;
}

interface PlatformLike {
  loop: LoopController;
}

/**
 * Attaches SIGINT/SIGTERM handlers to stop AI background schedulers
 * and optionally close the HTTP server gracefully.
 */
export function attachGracefulShutdown(params: {
  platform: PlatformLike;
  server?: Server;
  signals?: Array<NodeJS.Signals>;
}): void {
  const { platform, server, signals = ['SIGINT', 'SIGTERM'] } = params;
  let shuttingDown = false;

  const shutdown = (signal: string) => {
    if (shuttingDown) return;
    shuttingDown = true;

    try {
      platform.loop.stopSchedulers();
      console.log(`[AI] stopped schedulers on ${signal}`);
    } catch (error) {
      console.error('[AI] failed to stop schedulers', error);
    }

    if (!server) {
      process.exit(0);
      return;
    }

    server.close((error?: Error) => {
      if (error) {
        console.error('[AI] server close error', error);
        process.exit(1);
        return;
      }
      process.exit(0);
    });
  };

  for (const signal of signals) {
    process.on(signal, () => shutdown(signal));
  }
}
