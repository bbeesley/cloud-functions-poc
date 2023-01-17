import Hapi from '@hapi/hapi';
import pino from 'hapi-pino';
import { getRandom, loadFortunes } from './fortunes.js';

async function init() {
  await loadFortunes();
  const server = Hapi.server({
    port: 8080,
    host: '0.0.0.0',
  });

  server.route({
    method: 'GET',
    path: '/fortune',
    handler(request) {
      request.log('info', 'received request for fortune cookie');
      return getRandom();
    },
  });
  await server.register({
    plugin: pino,
    options: {
      redact: ['req.headers.authorization'],
      mergeHapiLogData: true,
    },
  });

  await server.start();
  console.log('Server running on %s', server.info.uri);
}

process.on('unhandledRejection', (error) => {
  console.log(error);
  process.exit(1);
});

await init();
