import express from 'express';

import { attachGracefulShutdown } from '../api/graceful_shutdown';
import { bootstrapSelfImprovingAi } from '../api/express_bootstrap';

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok' });
});

const aiPlatform = bootstrapSelfImprovingAi(app);

const port = Number.parseInt(process.env.PORT ?? '3000', 10);
const server = app.listen(port, () => {
  console.log(`[AI] API running on http://localhost:${port}`);
});

attachGracefulShutdown({
  platform: aiPlatform,
  server,
});
