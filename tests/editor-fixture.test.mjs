import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createEditorFixtureServer } from './Serve-EditorFixture.mjs';

test('opt-in server serves only the disposable editor without a browser', async t => {
  const server = await createEditorFixtureServer();
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  t.after(() => new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve())));
  assert.equal(server.address().address, '127.0.0.1');
  const base = `http://127.0.0.1:${server.address().port}`;
  const page = await fetch(`${base}/editor?exercise=1`);
  assert.equal(page.status, 200);
  assert.equal(page.headers.get('content-type'), 'text/html; charset=utf-8');
  assert.equal(page.headers.get('cache-control'), 'no-store');
  const html = await page.text();
  assert.match(html, /<label for="editor">Disposable code editor<\/label>/);
  assert.match(html, /<textarea id="editor"/);
  for (const path of ['/', '/src/WindowsBrowser.psm1', '/fixtures/editor.html']) {
    const response = await fetch(`${base}${path}`);
    assert.equal(response.status, 404);
    await response.text();
  }
  const head = await fetch(`${base}/editor`, { method: 'HEAD' });
  assert.equal(head.status, 200);
  assert.equal(await head.text(), '');
  const post = await fetch(`${base}/editor`, { method: 'POST', body: 'SELECT 1;' });
  assert.equal(post.status, 405);
  assert.equal(post.headers.get('allow'), 'GET, HEAD');
  assert.equal(await post.text(), '');
});
