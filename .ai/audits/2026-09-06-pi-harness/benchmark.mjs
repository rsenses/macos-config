// Opt-in microbenchmark: <=12 single provider completions, no tool execution.
// Run: PI_SDK_ROOT=/absolute/path/to/pi-coding-agent node benchmark.mjs --run
import { writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
if (!process.argv.includes('--run')) throw new Error('Requires explicit --run (uses provider quota)');
const root = process.env.PI_SDK_ROOT;
if (!root) throw new Error('Set PI_SDK_ROOT to the installed coding-agent package');
const { ModelRuntime } = await import(pathToFileURL(join(root, 'dist/core/model-runtime.js')));
const runtime = await ModelRuntime.create({ allowModelNetwork: false });
const profiles = [
  { id: 'luna-low', provider: 'openai-codex', model: 'gpt-5.6-luna', reasoning: 'low' },
  { id: 'luna-medium', provider: 'openai-codex', model: 'gpt-5.6-luna', reasoning: 'medium' },
  { id: 'luna-max', provider: 'openai-codex', model: 'gpt-5.6-luna', reasoning: 'max' },
  { id: 'flash-low', provider: 'opencode-go', model: 'deepseek-v4-flash', reasoning: 'low' },
];
const tasks = [
  {
    id: 'lookup-tool',
    prompt: `Locate process cancellation implementation. Use exactly one read tool call, no prose. Manifest: src/ui.ts renders widgets; src/index.ts calls terminateProcessTree imported from ./lifecycle.ts; src/lifecycle.ts defines terminateProcessTree and signalProcessTree; src/queue.ts defines Semaphore. Read src/lifecycle.ts from line 1 for at most 100 lines. Do not execute shell or edit.`,
    tools: [{ name: 'read', description: 'Read a local file range', parameters: { type: 'object', properties: { path: { type: 'string' }, offset: { type: 'integer' }, limit: { type: 'integer' } }, required: ['path', 'offset', 'limit'], additionalProperties: false } }],
    check: (msg) => { const tools = msg.content.filter(x => x.type === 'toolCall'); return tools.length === 1 && tools[0].name === 'read' && tools[0].arguments.path === 'src/lifecycle.ts' && tools[0].arguments.offset === 1 && tools[0].arguments.limit === 100; },
  },
  {
    id: 'concurrency-review',
    prompt: `Review this cancellation algorithm: on abort signalProcessTree(proc, 'SIGTERM'); install once('exit', () => clearTimeout(timer)); timer=setTimeout(() => { if (proc.exitCode===null) signalProcessTree(proc,'SIGKILL'); },1000). Parent exits immediately on SIGTERM, grandchild ignores SIGTERM. Which fix preserves cancellation of descendants? A: check proc.killed instead. B: track process group existence independently of parent exit and keep escalation until group is gone or deadline reached. C: await parent's close event then return. D: extend grace to 10 seconds. Return only JSON {"choice":"letter","descendantMaySurvive":boolean}.`,
    check: (msg) => { const x = parse(msg); return x.choice === 'B' && x.descendantMaySurvive === true; },
  },
  {
    id: 'source-synthesis',
    prompt: `Extract ONLY from these synthetic fixtures (not real pricing). [A dated 2026-01-01]: plan $10/month, base monthly allowance $60. [B dated 2026-09-06]: current plan $10/month; effective model allowances Flash $30, Pro $15, Luna $15; Flash rates offpeak input .22 output .66 cached .007, peak doubles all three. [C dated 2026-09-06]: requests depend on token mix, estimated counts are not guaranteed. No source measures latency or quality. Return only JSON {"planUsd":number,"flashAllowanceUsd":number,"proAllowanceUsd":number,"flashPeakOutputPerMillionUsd":number,"requestsGuaranteed":boolean,"flashFasterProven":boolean,"currentSource":"A or B"}.`,
    check: (msg) => { const x = parse(msg); return x.planUsd === 10 && x.flashAllowanceUsd === 30 && x.proAllowanceUsd === 15 && x.flashPeakOutputPerMillionUsd === 1.32 && x.requestsGuaranteed === false && x.flashFasterProven === false && x.currentSource === 'B'; },
  },
];
function parse(msg) { const s = msg.content.filter(x => x.type === 'text').map(x => x.text).join('\n').replace(/^```(?:json)?\s*|\s*```$/g, '').trim(); return JSON.parse(s); }
const rows = [];
const blocked = new Set();
let calls = 0;
const output = join(dirname(fileURLToPath(import.meta.url)), 'benchmark-results.json');
async function persist() { await writeFile(output, JSON.stringify({ date: new Date().toISOString(), methodology: 'Single completion per synthetic task/profile. No tools executed, no autonomous coding, no repetitions. Not a quality/latency benchmark of full agents. Infrastructure failures skip the remaining profile requests. Provider retries disabled. No raw reasoning or credentials stored.', calls, rows }, null, 2) + '\n'); }
for (let t = 0; t < tasks.length; t++) {
  // Rotate profile order to reduce systematic warmup/order bias, not statistical randomization.
  const order = [...profiles.slice(t), ...profiles.slice(0, t)];
  for (const p of order) {
    const task = tasks[t];
    if (blocked.has(p.id)) continue;
    const model = runtime.getModel(p.provider, p.model);
    if (!model || !runtime.hasConfiguredAuth(p.provider)) { rows.push({ profile:p.id, task:task.id, status:'unavailable', reason:'Model or configured credentials absent' }); blocked.add(p.id); await persist(); continue; }
    if (calls >= 12) throw new Error('Hard invocation budget reached');
    const start = performance.now(); calls++;
    console.log(`START ${calls} ${p.id} ${task.id}`);
    const row = { profile:p.id, task:task.id, requestedModel:`${p.provider}/${p.model}`, reasoning:p.reasoning };
    try {
      const msg = await runtime.completeSimple(model, { systemPrompt:'Follow the task exactly. Use only supplied evidence. Output no extra explanation.', messages:[{ role:'user', content:task.prompt, timestamp:Date.now() }], ...(task.tools ? {tools:task.tools} : {}) }, { reasoning:p.reasoning, maxTokens:8192, maxRetries:0, timeoutMs:120000, signal:AbortSignal.timeout(125000), transport:'sse', sessionId:`pi-harness-bench-${p.id}-${task.id}`, headers:p.provider==='opencode-go'? {'x-opencode-session':`pi-harness-bench-${p.id}-${task.id}`, 'User-Agent':'pi-harness-benchmark/1.0'}:undefined });
      row.durationMs = Math.round(performance.now()-start);
      row.stopReason = msg.stopReason; row.model = `${msg.provider}/${msg.model}`; row.usage = msg.usage;
      // Persist final text/tool calls only, never model reasoning blocks.
      row.answer = msg.content.filter(x => x.type==='text'||x.type==='toolCall').map(x=>x.type==='text'?{type:x.type,text:x.text}:{type:x.type,name:x.name,arguments:x.arguments});
      row.status = ['error','aborted'].includes(msg.stopReason)?'error':'completed';
      try { row.correct = row.status==='completed' && task.check(msg); } catch { row.correct=false; }
      if (row.status==='error') { row.error = String(msg.errorMessage||msg.stopReason).replace(/https:\/\/opencode\.ai\/workspace\/[^\s"}]+/g, '[billing URL redacted]').slice(0,500); blocked.add(p.id); }
    } catch (error) { row.durationMs=Math.round(performance.now()-start); row.status='error'; row.error=String(error.message).slice(0,500); blocked.add(p.id); }
    rows.push(row); await persist();
    console.log(`END ${p.id} ${task.id} ${row.status} correct=${row.correct} ${row.durationMs}ms`);
  }
}
console.log(`Saved ${calls} completions to ${output}`);
