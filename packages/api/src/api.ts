import type { Request, Response } from '@google-cloud/functions-framework';

export async function handler(
  request: Request,
  response: Response,
): Promise<void> {
  console.info({ request });
  response.send({ ok: true });
}
