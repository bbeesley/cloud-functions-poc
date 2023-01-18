import type { Request, Response } from '@google-cloud/functions-framework';
import winston from 'winston';
import express from 'express';
import { express as lwExpress } from '@google-cloud/logging-winston';
import { https } from 'firebase-functions';

const app = express();
const logger = winston.createLogger();
const loggingMiddleware = await lwExpress.makeMiddleware(logger);
app.use(loggingMiddleware);

app.get('*', async (request, response) => {
  if (request.path === '/api') {
    try {
      await api(request, response);
    } catch (error) {
      logger.error(error.message);
      response.sendStatus(500);
    }
  } else {
    response.sendStatus(404);
  }
});

async function api(request: Request, response: Response): Promise<void> {
  response.setHeader('Cache-Control', 'public, must-revalidate, max-age=60');
  response.send({ ok: true });
}

export const handler = https.onRequest(app);
