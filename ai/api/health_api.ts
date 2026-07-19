import { AiDataStore } from '../shared/data_store';
import { HttpRequest, HttpResponse } from './http_types';

export class HealthApi {
  constructor(private readonly dataStore: AiDataStore) {}

  async getHealth(
    _request: HttpRequest,
  ): Promise<HttpResponse<{ healthy: boolean; status: string; active_modules: number }>> {
    try {
      // Basic datastore ping by reading a small set.
      await this.dataStore.listEvaluations(1);
      return {
        status: 200,
        data: {
          healthy: true,
          status: 'ok',
          active_modules: 12,
        },
      };
    } catch (_error) {
      return {
        status: 503,
        data: {
          healthy: false,
          status: 'degraded',
          active_modules: 0,
        },
      };
    }
  }
}
