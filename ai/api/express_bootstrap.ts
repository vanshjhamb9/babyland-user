import type { Express } from 'express';

import { mountAiRoutes } from './express_routes';

/**
 * One-call integration helper for API gateway servers.
 * It mounts AI routes and starts the continuous improvement schedulers.
 */
export function bootstrapSelfImprovingAi(app: Express) {
  const platform = mountAiRoutes(app);
  platform.loop.startSchedulers();
  return platform;
}
