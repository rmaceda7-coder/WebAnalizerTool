import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createHandler } from '../scripts/browser-vision-mcp.mjs';

const call = (name, args = {}) => ({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name, arguments: args } });
const bound = { expectedUrl: 'https://example.test/dashboard?scenario=1&view=summary', expectedWindowHandle: 123 };

test('MCP lifecycle and discovery expose only read-only tools', async () => {
  const handle = createHandler();
  const init = await handle({ id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18' } });
  assert.equal(init.result.protocolVersion, '2025-06-18');
  assert.equal(await handle({ method: 'notifications/initialized' }), undefined);
  const list = await handle({ id: 2, method: 'tools/list' });
  assert.equal(list.result.tools.length, 3);
  assert.ok(list.result.tools.every(t => t.annotations.readOnlyHint && !t.annotations.destructiveHint));
  assert.deepEqual((await handle({ id: 3, method: 'ping' })).result, {});
});

test('capture binds URL/handle and returns MCP image content, not base64 text', async () => {
  const handle = createHandler(async (script, args) => {
    assert.equal(script, 'Get-BrowserPageImage.ps1');
    assert.deepEqual(args, ['-ExpectedUrl', bound.expectedUrl, '-ExpectedWindowHandle', '123']);
    return { Data: 'iVBORw0KGgoAAA==', MimeType: 'image/png', Width: 100, Context: { Url: bound.expectedUrl } };
  });
  const response = await handle(call('capture_browser_page', bound));
  assert.equal(response.result.content[1].type, 'image');
  assert.equal(response.result.content[1].mimeType, 'image/png');
  assert.equal(JSON.parse(response.result.content[0].text).Context.Url, bound.expectedUrl);
  assert.ok(!response.result.content[0].text.includes('iVBOR'));
});

test('invalid bindings and unknown arguments fail before desktop access', async () => {
  const handle = createHandler(async () => { assert.fail('Desktop must not be accessed'); });
  for (const args of [{}, { ...bound, expectedWindowHandle: -1 }, { ...bound, expectedUrl: 'file:///secret' },
    { ...bound, expectedUrl: 'https://example.test/"bad' }, { ...bound, expectedWindowHandle: 1.5 }, { ...bound, submit: true }]) {
    assert.equal((await handle(call('capture_browser_page', args))).result.isError, true);
  }
  assert.equal((await handle(call('get_primary_browser_context', { extra: true }))).result.isError, true);
  assert.equal((await handle(call('submit'))).error.code, -32602);
});

test('capture/context errors are explicit and do not return an image', async () => {
  const handle = createHandler(async () => { throw new Error('Browser context changed'); });
  const response = await handle(call('capture_browser_page', bound));
  assert.equal(response.result.isError, true);
  assert.match(response.result.content[0].text, /context changed/);
  assert.ok(response.result.content.every(c => c.type !== 'image'));
  const invalid = createHandler(async () => ({ MimeType: 'image/png', Data: '' }));
  assert.equal((await invalid(call('capture_browser_page', bound))).result.isError, true);
});

test('stdio transport responds to newline JSON-RPC with no startup noise', async () => {
  const child = spawn(process.execPath, [fileURLToPath(new URL('../scripts/browser-vision-mcp.mjs', import.meta.url))], { stdio: ['pipe', 'pipe', 'pipe'] });
  let stdout = ''; let stderr = '';
  child.stdout.on('data', chunk => { stdout += chunk; });
  child.stderr.on('data', chunk => { stderr += chunk; });
  const closed = new Promise((resolve, reject) => { child.on('error', reject); child.on('close', resolve); });
  child.stdin.end('invalid json\n' + JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'tools/list' }) + '\n');
  assert.equal(await closed, 0);
  assert.equal(stderr, '');
  const responses = stdout.trim().split('\n').map(line => JSON.parse(line));
  assert.equal(responses[0].error.code, -32700);
  assert.equal(responses[1].result.tools.length, 3);
});
