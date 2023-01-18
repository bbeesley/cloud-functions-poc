import type { Request, Response } from '@google-cloud/functions-framework';
import winston from 'winston';
import { LoggingWinston } from '@google-cloud/logging-winston';
import { K_REVISION, K_SERVICE } from './constants.js';

const loggingWinston = new LoggingWinston({
  serviceContext: {
    service: K_SERVICE!,
    version: K_REVISION!,
  },
});

const logger = winston.createLogger({
  level: 'info',
  transports: [
    new winston.transports.Console(),
    // Add Cloud Logging
    loggingWinston,
  ],
});

export async function handler(
  request: Request,
  response: Response,
): Promise<void> {
  logger.info({ message: 'received request', request });
  response.send({ ok: true });
}
