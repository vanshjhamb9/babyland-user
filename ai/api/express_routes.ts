import type { Express, NextFunction, Request, Response } from 'express';

import { ApiSecurity } from './api_security';
import { createAiPlatform } from '../platform';
import { ThreatDetectionEngine } from '../security/threat_detection_engine';
import { HttpRequest } from './http_types';

function toHttpRequest(req: Request): HttpRequest {
  return {
    ip: req.ip || req.socket.remoteAddress || 'unknown',
    body: req.body,
    query: Object.fromEntries(
      Object.entries(req.query ?? {}).map(([k, v]) => [k, String(v)]),
    ),
  };
}

/**
 * Mounts self-improving AI endpoints on an Express app.
 *
 * Routes:
 * - POST /api/ai/feedback
 * - GET /api/ai/metrics
 * - GET /api/ai/insights
 * - GET /api/ai/evaluations
 */
export function mountAiRoutes(app: Express): ReturnType<typeof createAiPlatform> {
  const platform = createAiPlatform();
  const threatEngine = new ThreatDetectionEngine(platform.observer);
  const apiSecurity = new ApiSecurity(threatEngine, platform.observer);

  // Security middleware for all AI endpoints
  const securityMiddleware = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const httpReq = toHttpRequest(req);
      const securityCheck = await apiSecurity.validateRequest(httpReq);

      if (!securityCheck.allowed) {
        const errorResponse = apiSecurity.createErrorResponse(
          400,
          'SECURITY_VIOLATION',
          securityCheck.error_message || 'Request failed security validation',
          securityCheck.violations,
        );
        return res.status(errorResponse.status).json(errorResponse.data);
      }

      // Attach sanitized request to req object
      (req as any).sanitizedRequest = securityCheck.sanitized_request;
      next();
    } catch (error: any) {
      const errorResponse = apiSecurity.createErrorResponse(
        500,
        'SECURITY_MIDDLEWARE_ERROR',
        error?.message ?? 'Security middleware failed',
      );
      res.status(errorResponse.status).json(errorResponse.data);
    }
  };

  app.post('/api/ai/chat', securityMiddleware, async (req, res) => {
    try {
      const httpReq = (req as any).sanitizedRequest || toHttpRequest(req);
      const response = await apiSecurity.withTimeout(
        platform.chatApi.postChat(httpReq),
        30_000,
      );
      res.status(response.status).json(response.data);
    } catch (error: any) {
      const errorResponse = apiSecurity.createErrorResponse(
        504,
        'TIMEOUT_OR_INTERNAL_ERROR',
        error.message || 'Chat request failed',
      );
      res.status(errorResponse.status).json(errorResponse.data);
    }
  });

  app.post('/api/ai/feedback', securityMiddleware, async (req, res) => {
    try {
      const httpReq = (req as any).sanitizedRequest || toHttpRequest(req);
      const response = await apiSecurity.withTimeout(
        platform.feedbackApi.postFeedback(httpReq),
        10_000,
      );
      res.status(response.status).json(response.data);
    } catch (error: any) {
      const errorResponse = apiSecurity.createErrorResponse(
        500,
        'INTERNAL_ERROR',
        error.message || 'Internal server error',
      );
      res.status(errorResponse.status).json(errorResponse.data);
    }
  });

  app.get('/api/ai/metrics', securityMiddleware, async (req, res) => {
    try {
      const httpReq = (req as any).sanitizedRequest || toHttpRequest(req);
      const response = await apiSecurity.withTimeout(
        platform.dashboardApi.getMetrics(httpReq),
        10_000,
      );
      res.status(response.status).json(response.data);
    } catch (error: any) {
      const errorResponse = apiSecurity.createErrorResponse(
        500,
        'INTERNAL_ERROR',
        error.message || 'Internal server error',
      );
      res.status(errorResponse.status).json(errorResponse.data);
    }
  });

  app.get('/api/ai/insights', securityMiddleware, async (req, res) => {
    try {
      const httpReq = (req as any).sanitizedRequest || toHttpRequest(req);
      const response = await apiSecurity.withTimeout(
        platform.dashboardApi.getInsights(httpReq),
        10_000,
      );
      res.status(response.status).json(response.data);
    } catch (error: any) {
      const errorResponse = apiSecurity.createErrorResponse(
        500,
        'INTERNAL_ERROR',
        error.message || 'Internal server error',
      );
      res.status(errorResponse.status).json(errorResponse.data);
    }
  });

  app.get('/api/ai/evaluations', securityMiddleware, async (req, res) => {
    try {
      const httpReq = (req as any).sanitizedRequest || toHttpRequest(req);
      const response = await apiSecurity.withTimeout(
        platform.dashboardApi.getEvaluations(httpReq),
        10_000,
      );
      res.status(response.status).json(response.data);
    } catch (error: any) {
      const errorResponse = apiSecurity.createErrorResponse(
        500,
        'INTERNAL_ERROR',
        error.message || 'Internal server error',
      );
      res.status(errorResponse.status).json(errorResponse.data);
    }
  });

  app.get('/api/ai/health', securityMiddleware, async (req, res) => {
    const response = await platform.healthApi.getHealth(
      (req as any).sanitizedRequest || toHttpRequest(req),
    );
    res.status(response.status).json(response.data);
  });

  app.get('/api/ai/metrics/prometheus', async (_req, res) => {
    res.type('text/plain').send(platform.prometheusApi.getMetricsText());
  });

  return platform;
}
