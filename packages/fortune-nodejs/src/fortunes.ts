import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import * as url from 'node:url';

const __dirname = url.fileURLToPath(new URL('.', import.meta.url)); // eslint-disable-line @typescript-eslint/naming-convention

const fortunes: string[] = [];

export async function loadFortunes(): Promise<string[]> {
  if (fortunes.length === 0) {
    const fileContent = await readFile(
      resolve(__dirname, '../assets/fortunes.json'),
      { encoding: 'utf8' },
    );
    fortunes.push(...(JSON.parse(fileContent) as string[]));
  }

  return fortunes;
}

export function getRandom(): string {
  const index = Math.floor(Math.random() * fortunes.length);
  const item = fortunes[index];
  if (item) return item;
  throw new TypeError('Cannot get element of empty array');
}
