import { ObserverService } from '../observer/observer_service';

export class PrometheusApi {
  constructor(private readonly observer: ObserverService) {}

  getMetricsText(): string {
    return this.observer.exportPrometheusMetrics();
  }
}
