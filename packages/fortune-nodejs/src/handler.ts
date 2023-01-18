import express from 'express';
import { express as lwExpress } from '@google-cloud/logging-winston';
import * as winston from 'winston';
import { getRandom, loadFortunes } from './fortunes.js';
import { K_REVISION, K_SERVICE } from './constants.js';

const app = express();
const port = 8080;
const logger = winston.createLogger();
const loggingMiddleware = await lwExpress.makeMiddleware(logger, {
  redirectToStdout: true,
  serviceContext: {
    service: K_SERVICE!,
    version: K_REVISION!,
  },
});
if (process.env.npm_command === 'start') app.use(loggingMiddleware);

await loadFortunes();

app.get('/fortune', (request, res) => {
  res.setHeader('Cache-Control', 'public, must-revalidate, max-age=60');
  res.send(getRandom());
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
