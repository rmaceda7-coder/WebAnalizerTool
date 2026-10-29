import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import { createInterface } from 'node:readline';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const exec = promisify(execFile);
const boundSchema = {
  type: 'object', additionalProperties: false,
  properties: {
    expectedUrl: { type: 'string', description: 'Exact URL returned by context discovery.' },
    expectedWindowHandle: { type: 'integer', minimum: 1 },
  }, required: ['expectedUrl', 'expectedWindowHandle'],
};
const tools = [
  { name: 'get_primary_browser_context', description: 'Passively identify the selected Chrome page on the Windows primary monitor. Report its identity before reading/capturing.', inputSchema: { type: 'object', properties: {}, additionalProperties: false } },
  { name: 'read_browser_page', description: 'Read accessibility text of the previously identified page.', inputSchema: boundSchema },
  { name: 'capture_browser_page', description: 'Return a direct PNG image of the bound Chrome window, including visible image-based tables/diagrams. Does not focus, navigate, click, use clipboard, or save a file. Only the visible viewport is captured.', inputSchema: boundSchema },
].map(t => ({ ...t, annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false } }));

export async function runScript(script, args) {
  // Paths resolve from this file, independently of the MCP client's working directory.
  const { stdout } = await exec('powershell.exe', [
    '-NoProfile', '-NonInteractive', '-STA', '-ExecutionPolicy', 'Bypass',
    '-File', join(root, 'scripts', script), ...args,
  ], { cwd: root, windowsHide: true, timeout: 30000, maxBuffer: 32 * 1024 * 1024, encoding: 'utf8' });
  return JSON.parse(stdout.replace(/^\uFEFF/, ''));
}

export function createHandler(run = runScript) {
  return async function handle(message) {
    const { id, method, params = {} } = message;
    if (id === undefined) return; // MCP notifications have no response.
    const result = value => ({ jsonrpc: '2.0', id, result: value });
    const error = (code, text) => ({ jsonrpc: '2.0', id, error: { code, message: text } });
    if (method === 'initialize') return result({
      protocolVersion: ['2024-11-05', '2025-03-26', '2025-06-18', '2025-11-25'].includes(params.protocolVersion) ? params.protocolVersion : '2024-11-05',
      capabilities: { tools: {} }, serverInfo: { name: 'web-analyzer-vision', version: '0.2.0' },
    });
    if (method === 'ping') return result({});
    if (method === 'tools/list') return result({ tools });
    if (method !== 'tools/call') return error(-32601, 'Method not found');
    try {
      const tool = tools.find(t => t.name === params.name);
      if (!tool) return error(-32602, 'Unknown tool');
      const args = params.arguments ?? {};
      if (!args || typeof args !== 'object' || Array.isArray(args)) throw new Error('Arguments must be an object.');
      const bound = tool.name !== 'get_primary_browser_context';
      const keys = bound ? ['expectedUrl', 'expectedWindowHandle'] : [];
      if (Object.keys(args).some(k => !keys.includes(k))) throw new Error('Unexpected argument.');
      if (bound && (typeof args.expectedUrl !== 'string' || !/^https?:\/\/[^\s"\x00-\x1f]+$/i.test(args.expectedUrl) ||
          !Number.isSafeInteger(args.expectedWindowHandle) || args.expectedWindowHandle < 1)) {
        throw new Error('An exact HTTP(S) URL and positive safe integer window handle are required.');
      }
      const cliArgs = bound ? ['-ExpectedUrl', args.expectedUrl, '-ExpectedWindowHandle', String(args.expectedWindowHandle)] : [];
      const script = { get_primary_browser_context: 'Get-PrimaryBrowserContext.ps1', read_browser_page: 'Read-BrowserPage.ps1', capture_browser_page: 'Get-BrowserPageImage.ps1' }[tool.name];
      const output = await run(script, cliArgs);
      if (tool.name === 'capture_browser_page') {
        const { Data, ...metadata } = output;
        if (output.MimeType !== 'image/png' || typeof Data !== 'string' || !Data.startsWith('iVBORw0KGgo')) throw new Error('Capture did not return a PNG.');
        return result({ content: [
          { type: 'text', text: JSON.stringify(metadata) },
          { type: 'image', mimeType: 'image/png', data: Data },
        ] });
      }
      return result({ content: [{ type: 'text', text: JSON.stringify(output) }] });
    } catch (cause) {
      return result({ isError: true, content: [{ type: 'text', text: String(cause.message) }] });
    }
  };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const handle = createHandler();
  // Sequential requests avoid competing desktop reads/captures.
  for await (const line of createInterface({ input: process.stdin, crlfDelay: Infinity })) {
    try {
      const response = await handle(JSON.parse(line));
      if (response) process.stdout.write(JSON.stringify(response) + '\n');
    } catch {
      process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } }) + '\n');
    }
  }
}
