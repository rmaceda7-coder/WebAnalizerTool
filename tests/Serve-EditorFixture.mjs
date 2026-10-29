import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// Opt-in fixture only. This server never opens Chrome or invokes desktop operations.
export async function createEditorFixtureServer() {
  const html = await readFile(new URL('./fixtures/editor.html', import.meta.url));
  return createServer((request, response) => {
    response.setHeader('Cache-Control', 'no-store');
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      response.writeHead(405, { Allow: 'GET, HEAD' });
      response.end();
      return;
    }
    if (new URL(request.url, 'http://127.0.0.1').pathname !== '/editor') {
      response.writeHead(404);
      response.end();
      return;
    }
    response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    response.end(request.method === 'HEAD' ? undefined : html);
  });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const server = await createEditorFixtureServer();
  server.on('error', error => { console.error(error.message); process.exitCode = 1; });
  server.listen(0, '127.0.0.1', () => {
    console.log(`Disposable editor: http://127.0.0.1:${server.address().port}/editor?exercise=1`);
    console.log('Open this URL manually in Chrome on the primary monitor. Stop the server with Ctrl+C.');
  });
}
