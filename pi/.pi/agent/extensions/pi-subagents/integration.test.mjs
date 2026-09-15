// Runs real Pi extension loading and subprocess protocol with a fake provider-free pi binary.
// PI_SDK_ROOT=/path/to/pi-coding-agent node --test integration.test.mjs
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdir, mkdtemp, writeFile, rm, readFile, realpath } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { execFile } from 'node:child_process';
import { tmpdir, homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const sdkRoot = process.env.PI_SDK_ROOT;
const here = dirname(fileURLToPath(import.meta.url));
test('actual extension loading, allowlists, protocol, usage and failure hook', {skip: !sdkRoot}, async () => {
  const { DefaultResourceLoader, SettingsManager } = await import(pathToFileURL(join(sdkRoot, 'dist/index.js')));
  const dir = await mkdtemp(join(tmpdir(), 'pi-subagent-integration-'));
  const oldPath = process.env.PATH;
  const oldFixture = process.env.PI_TEST_FIXTURE;
  try {
    const script = `#!${process.execPath}\nconst fs=require('node:fs');fs.writeFileSync(process.env.PI_TEST_FIXTURE+'.args',JSON.stringify(process.argv.slice(2)));process.stdout.write(fs.readFileSync(process.env.PI_TEST_FIXTURE,'utf8'));\n`;
    await writeFile(join(dir,'pi'),script,{mode:0o700});
    process.env.PATH = `${dir}:${oldPath}`;
    process.env.PI_TEST_FIXTURE = join(dir,'events.jsonl');
    const load = async (paths) => {
      const loader = new DefaultResourceLoader({cwd:dir,agentDir:join(dir,'agent'),settingsManager:SettingsManager.inMemory({packages:[]}),noExtensions:true,noSkills:true,noPromptTemplates:true,noThemes:true,additionalExtensionPaths:paths});
      await loader.reload();
      assert.deepEqual(loader.getExtensions().errors,[]);
      return loader.getExtensions().extensions;
    };
    const loaded = await load([join(here,'index.ts')]);
    const ext = loaded.find(e=>e.tools.has('subagent'));
    assert.ok(ext);
    const registered = ext.tools.get('subagent');
    const tool = registered.definition ?? registered;
    // Fake registry covering every configured agent/profile model. All are reasoning
    // models supporting off/minimal/low/medium/high; only Luna maps `max`, so any
    // other level (e.g. xhigh) exercises the unsupported-thinking fail path.
    const thinkMap = {off:'off',minimal:'minimal',low:'low',medium:'medium',high:'high'};
    const fakeModel = (providerModel, extraMap = {}) => {
      const [provider, id] = providerModel.split('/');
      return {provider, id, reasoning:true, contextWindow:272000, thinkingLevelMap:{...thinkMap, ...extraMap}};
    };
    const MODELS = {
      deepseek: fakeModel('opencode-go/deepseek-v4.1-flash'),      // scout frontmatter
      glm: fakeModel('opencode-go/glm-5.3-flash'),                 // worker frontmatter
      luna: fakeModel('openai-codex/gpt-5.6-luna', {max:'max'}),   // researcher/planner + habitual profile
      sol: fakeModel('openai-codex/gpt-5.6-sol'),                  // diseno profile
      astra: fakeModel('openai-codex/gpt-6-astra'),                // plan-reviewer + delicado profile
    };
    const byModel = new Map(Object.values(MODELS).map(m => [`${m.provider}/${m.id}`, m]));
    const scopedModels = Object.values(MODELS).map(m => ({model:{provider:m.provider, id:m.id}}));
    const ctx = {
      cwd:dir,
      scopedModels,
      modelRegistry:{find:(p,id)=>byModel.get(`${p}/${id}`)},
      hasUI:true,
      ui:{select:async (_title, options)=>options[0], notify:()=>{}},
    };
    const usage = {input:10,output:2,cacheRead:5,cacheWrite:0,totalTokens:17,cost:{input:.01,output:.02,cacheRead:0,cacheWrite:0,total:.03}};
    const scoutModel = MODELS.deepseek;
    const event = (reason,text,extra={})=>({type:'message_end',message:{role:'assistant',provider:scoutModel.provider,model:scoutModel.id,stopReason:reason,content:[{type:'text',text}],usage,...extra}});
    await writeFile(process.env.PI_TEST_FIXTURE,JSON.stringify(event('stop','**Status**: complete\nVerified.'))+'\n');
    const success = await tool.execute('s',{agent:'scout',task:'Locate fixture',thinking:'low'},undefined,undefined,ctx);
    assert.equal(success.details.status,'complete');
    assert.equal(success.usage.input,10);
    assert.equal(success.usage.cost.total,.03);
    assert.equal(success.details.results[0].thinking,'low');
    const argv = JSON.parse(await readFile(process.env.PI_TEST_FIXTURE+'.args','utf8'));
    // Scout frontmatter pins opencode-go/deepseek-v4.1-flash; no fallback to Luna.
    assert.equal(argv[argv.indexOf('--model')+1],'opencode-go/deepseek-v4.1-flash');
    assert.equal(argv[argv.indexOf('--tools')+1],'read,grep,find,ls');
    assert.ok(!argv.includes('--no-context-files'));
    assert.equal(argv[argv.indexOf('--system-prompt')+1], join(here, 'SYSTEM.md'));
    await mkdir(join(dir,'.pi'),{recursive:true});
    await writeFile(join(dir,'.pi/SYSTEM.md'),'Preserve explicit project policy');
    for(const role of ['researcher','worker']) {
      await tool.execute('r',{agent:role,task:'Role fixture'},undefined,undefined,ctx);
      const roleArgs=JSON.parse(await readFile(process.env.PI_TEST_FIXTURE+'.args','utf8'));
      assert.ok(!roleArgs.includes('--system-prompt'), 'Explicit project SYSTEM must not be replaced');
      const allowed=roleArgs[roleArgs.indexOf('--tools')+1].split(',');
      assert.ok(!allowed.includes('subagent'));
      if(role==='researcher') { assert.deepEqual(allowed,['codex-research','web_fetch']); }
      else { for(const t of ['safe_bash','ast_grep','web_fetch','grep','write'])assert.ok(allowed.includes(t)); }
    }
    await writeFile(process.env.PI_TEST_FIXTURE,[event('toolUse','Partial evidence'),event('error','',{errorMessage:'fixture quota'})].map(JSON.stringify).join('\n')+'\n');
    const failed = await tool.execute('f',{agent:'scout',task:'Failure'},undefined,undefined,ctx);
    assert.equal(failed.details.status,'failed');
    assert.match(failed.content[0].text,/fixture quota/);
    assert.match(failed.content[0].text,/Partial evidence/);
    const hooks = ext.handlers.get('tool_result');
    assert.ok(hooks?.length);
    const overrides = await Promise.all(hooks.map(h=>h({toolName:'subagent',details:failed.details},ctx)));
    assert.ok(overrides.some(x=>x?.isError===true));
    await writeFile(process.env.PI_TEST_FIXTURE,JSON.stringify(event('length','unfinished'))+'\n');
    const partial = await tool.execute('p',{agent:'scout',task:'Incomplete'},undefined,undefined,ctx);
    assert.equal(partial.details.status,'partial');
    const cancelled = new AbortController();cancelled.abort();
    const aborted = await tool.execute('a',{agent:'scout',task:'Cancelled'},cancelled.signal,undefined,ctx);
    assert.equal(aborted.details.status,'cancelled');
    await assert.rejects(tool.execute('u',{agent:'missing',task:'Invalid'},undefined,undefined,ctx),/Unknown agent/);
    await assert.rejects(tool.execute('u',{agent:'scout',task:'Invalid'},undefined,undefined,{...ctx,modelRegistry:{find:()=>undefined}}),/model unavailable/);
    globalThis.__pi_subagents.registerAgent({name:'unsupported-tool',description:'fixture',tools:['imaginary'],model:'openai-codex/gpt-5.6-luna',thinking:'low',systemPrompt:'test',filePath:''});
    await assert.rejects(tool.execute('u',{agent:'unsupported-tool',task:'Invalid'},undefined,undefined,ctx),/Unavailable tool imaginary/);
    globalThis.__pi_subagents.unregisterAgent('unsupported-tool');
    // ── Planner profiles: exact model/thinking per named profile, no fallback. ──
    await writeFile(process.env.PI_TEST_FIXTURE, JSON.stringify(event('stop','**Status**: complete\nProfile fixture.'))+'\n');
    const profileCases = [
      ['habitual','habitual','openai-codex/gpt-5.6-luna','high'],
      ['diseno','diseño','openai-codex/gpt-5.6-sol','medium'],
      ['delicado','delicado','openai-codex/gpt-6-astra','low'],
    ];
    for (const [name, label, expectedModel, expectedThinking] of profileCases) {
      const run = await tool.execute('pf',{agent:'planner',task:'Profile fixture',profile:name},undefined,undefined,ctx);
      assert.equal(run.details.status,'complete',name);
      const child = run.details.results[0];
      assert.equal(child.profile,name);
      assert.equal(child.profileLabel,label);
      assert.equal(child.requestedModel,expectedModel);
      assert.equal(child.thinking,expectedThinking);
      const profileArgs = JSON.parse(await readFile(process.env.PI_TEST_FIXTURE+'.args','utf8'));
      assert.equal(profileArgs[profileArgs.indexOf('--model')+1],expectedModel);
      assert.equal(profileArgs[profileArgs.indexOf('--thinking')+1],expectedThinking);
    }
    // A same-level explicit thinking override alongside a profile is accepted.
    const sameLevel = await tool.execute('pf',{agent:'planner',task:'Profile fixture',profile:'diseno',thinking:'medium'},undefined,undefined,ctx);
    assert.equal(sameLevel.details.status,'complete');
    assert.equal(sameLevel.details.results[0].profile,'diseno');

    // Omitting profile still requires a real approval and records the selected
    // effective profile; headless execution and cancellation cannot spawn.
    const withoutProfile = await tool.execute('np',{agent:'planner',task:'No profile fixture'},undefined,undefined,ctx);
    assert.equal(withoutProfile.details.status,'complete');
    assert.equal(withoutProfile.details.results[0].profile,'habitual');
    const profileArgsFile = process.env.PI_TEST_FIXTURE+'.args';
    await rm(profileArgsFile,{force:true});
    const cancelledUi = {...ctx,ui:{select:async (_title, options)=>options.at(-1), notify:()=>{}}};
    await assert.rejects(tool.execute('pc',{agent:'planner',task:'Cancel fixture',profile:'habitual'},undefined,undefined,cancelledUi),/cancelled/);
    assert.equal(existsSync(profileArgsFile),false,'cancelled planner must not spawn');
    await assert.rejects(tool.execute('ph',{agent:'planner',task:'Headless fixture',profile:'habitual'},undefined,undefined,{...ctx,hasUI:false,ui:undefined}),/no UI/);
    assert.equal(existsSync(profileArgsFile),false,'headless planner must not spawn');
    const abortedPlanner = new AbortController();
    abortedPlanner.abort();
    const abortedPlannerResult = await tool.execute('pa',{agent:'planner',task:'Abort fixture',profile:'habitual'},abortedPlanner.signal,undefined,ctx);
    assert.equal(abortedPlannerResult.details.status,'cancelled');
    assert.equal(existsSync(profileArgsFile),false,'aborted planner must not spawn');
    // Fail-fast paths below must all reject before the fake child spawns: the
    // recorded args file is removed first and must stay absent after each reject.
    await rm(profileArgsFile,{force:true});
    const noRegistry = {...ctx, modelRegistry:{find:()=>undefined}};
    const narrowScope = {...ctx, scopedModels:[{model:{provider:'openai-codex', id:'gpt-5.6-luna'}}]};
    const failFast = [
      [{agent:'scout',task:'x',profile:'habitual'}, /only valid for the "planner" agent/],
      [{agent:'planner',task:'x',profile:'nope'}, /Unknown profile/],
      [{agent:'planner',task:'x',profile:'habitual',thinking:'medium'}, /conflicting explicit override/],
      [{agent:'planner',task:'x',profile:'delicado'}, /Configured model unavailable: openai-codex\/gpt-6-astra/],
      [{agent:'planner',task:'x',profile:'delicado'}, /not in this session's scoped models/],
      [{agent:'planner',task:'x',thinking:'xhigh'}, /Unsupported thinking xhigh/],
    ];
    for (const [index, [params, pattern]] of failFast.entries()) {
      const failCtx = index === 3 ? noRegistry : index === 4 ? narrowScope : ctx;
      await assert.rejects(tool.execute('ff'+index,{...params},undefined,undefined,failCtx), pattern);
      assert.equal(existsSync(profileArgsFile), false, `spawned despite failure ${index}`);
    }
    // All researcher/worker custom extensions resolve, without calling them.
    const custom = await load([join(here,'../web-fetch/index.ts'),join(here,'../ast-grep.ts'),join(here,'tools/safe-bash.ts'),join(homedir(),'.pi/agent/npm/node_modules/pi-gpt-search/src/index.ts')]);
    const names = new Set(custom.flatMap(e=>[...e.tools.keys()]));
    for(const name of ['web_fetch','ast_grep','safe_bash','codex-research']) assert.ok(names.has(name),name);
    const fetchRegistration = custom.find(e=>e.tools.has('web_fetch')).tools.get('web_fetch');
    const fetchTool = fetchRegistration.definition ?? fetchRegistration;
    const originalFetch = globalThis.fetch;
    const artifactDirs = new Set();
    let requests=0;
    try {
      globalThis.fetch = async () => { requests++;return new Response(`version${requests}\n${'content '.repeat(3000)}`, {headers:{'content-type':'text/plain'}}); };
      const first=await fetchTool.execute('w',{url:'https://example.org/doc'},undefined);
      artifactDirs.add(dirname(first.details.artifact));
      assert.equal(first.details.truncated,true);
      assert.ok(first.content[0].text.length < 13000);
      const cached=await fetchTool.execute('w',{url:'https://example.org/doc'},undefined);
      assert.equal(requests,1);
      assert.equal(cached.details.artifact,first.details.artifact);
      const refreshed=await fetchTool.execute('w',{url:'https://example.org/doc',refresh:true,artifact:first.details.artifact},undefined);
      assert.equal(requests,2);
      assert.notEqual(refreshed.details.artifact,first.details.artifact);
      const recovered=await fetchTool.execute('w',{url:'https://example.org/doc',artifact:first.details.artifact,limit:15},undefined);
      assert.equal(requests,2);
      assert.match(recovered.content[0].text,/version1/);
      globalThis.fetch = async () => new Response(`<html><head><title>Fixture article</title></head><body><article><h1>Fixture article</h1>${('<p>This is a meaningful paragraph about tested bounded document extraction and preserving evidence in a local fixture without any external network request.</p>').repeat(15)}</article></body></html>`,{headers:{'content-type':'text/html'}});
      const html = await fetchTool.execute('h',{url:'https://example.org/article'},undefined);
      assert.match(html.content[0].text,/meaningful paragraph/);
      assert.match(html.details.title,/Fixture article/);
    } finally { globalThis.fetch=originalFetch;for(const d of artifactDirs)await rm(d,{recursive:true,force:true}); }
    const memory = (await load([join(here,'../memory.ts')])).find(e=>e.tools.has('create_session_plan'));
    const toolOf=(name)=>{const r=memory.tools.get(name);return r.definition??r;};
    const planRegistration=memory.tools.get('create_session_plan');const planTool=planRegistration.definition??planRegistration;
    const getPlanTool=toolOf('get_current_plan');
    const sumTool=toolOf('summarize_worktree');
    await assert.rejects(planTool.execute('x',{slug:'../../escape'},undefined,undefined,ctx),/slug/);

    // ── Provider-free memory coverage: canonical plan, pointer-first resolution, ──
    // ── idempotency, fail-closed blockers, bounded snapshot/injection, and UI.   ──
    // Limitation: the loader's runtime pi.appendEntry is a throwing stub outside a
    // live session, so pointer WRITES cannot be exercised here; pointer READ
    // resolution is driven through a fake sessionManager fed to the real tools.
    const POINTER_TYPE = 'memory.active-plan'; // memory.ts PLAN_POINTER_TYPE contract
    const fullSessionId = '01a0a3bf-2233-4455-8a9b-ccddeeff0001';
    const worktree = (await realpath(dir)).replace(/[\\/]+$/,'');
    const pointerEntry = (planPath, over = {}) => ({
      type:'custom', customType:POINTER_TYPE,
      data:{v:1, planPath, sessionId:fullSessionId, worktree, slug:'pointer-plan', updatedAt:'2026-09-15T00:00:00.000Z', ...over},
    });
    const memCtx = {cwd:dir, sessionManager:{getSessionId:()=>fullSessionId, getEntries:()=>[]}};
    const ctxWithPointers = (entries) => ({...memCtx, sessionManager:{getSessionId:()=>fullSessionId, getEntries:()=>entries.map(([p, over]) => pointerEntry(p, over))}});

    // Local git identity so worktree resolution and summarize_worktree agree.
    await new Promise((res,rej)=>execFile('git',['init','-q'],{cwd:dir},e=>e?rej(e):res()));

    // Canonical template sections and identity metadata.
    const created = await planTool.execute('m',{slug:'pointer-plan'},undefined,undefined,memCtx);
    assert.equal(created.details.created,true);
    const pointerRel = created.details.path;
    assert.match(pointerRel,/^\.ai\/plan\/.+\.md$/);
    const planBody = await readFile(join(dir,pointerRel),'utf8');
    for (const section of ['# Plan: pointer-plan','- Status: pending','- Session ID: '+fullSessionId,'- Worktree: '+worktree,'## TL;DR','## Current Step','## Goal','## Spec / Contract','## Tasks','## Risks / Stop Rules','## Validation Policy','## Validation','## Unresolved']) {
      assert.ok(planBody.includes(section),section);
    }

    // Idempotent creation: the same session adopts the existing plan file.
    const again = await planTool.execute('m',{slug:'pointer-plan'},undefined,undefined,memCtx);
    assert.equal(again.details.created,false);
    assert.equal(again.details.path,pointerRel);
    assert.equal(typeof again.details.pointerPersisted,'boolean');

    // An explicitly persisted pointer is the current selection; the plan body
    // retains provenance and may have been authored in another session. Legacy
    // filename recovery still checks body identity before adopting it.
    await writeFile(join(dir,pointerRel),planBody.replace(`- Session ID: ${fullSessionId}`, '- Session ID: another-session-9999'));
    const adoptedForeign = await getPlanTool.execute('m',{},undefined,undefined,ctxWithPointers([[pointerRel]]));
    assert.equal(adoptedForeign.details.source,'active-pointer');
    await writeFile(join(dir,pointerRel),planBody.replace(`- Worktree: ${worktree}`, '- Worktree: /elsewhere/worktree'));
    const adoptedForeignWorktree = await getPlanTool.execute('m',{},undefined,undefined,ctxWithPointers([[pointerRel]]));
    assert.equal(adoptedForeignWorktree.details.source,'active-pointer');
    await assert.rejects(getPlanTool.execute('m',{},undefined,undefined,memCtx),/Plan metadata belongs to a different worktree/);
    await writeFile(join(dir,pointerRel),planBody);

    // Populate a canonical plan; later assertions check the bounded snapshot.
    await writeFile(join(dir,pointerRel),`# Plan: pointer-plan
- Status: in-progress
- Created: 2026-09-15
- Session ID: ${fullSessionId}
- Worktree: ${worktree}

## TL;DR
Finish the provider-free regression matrix.

## Current Step
T08 regression coverage in progress.

## Goal
Cover pointer resolution without touching defaults. HIDDEN_FULL_PLAN_BODY_MARKER must never be injected whole.

## Spec / Contract
Known, Evidence, Acceptance, Checks and Stop live in the file.

## Tasks
- [x] T01 done slice
- [ ] T02 active regression slice
  - [ ] subchecklist must not count
\`\`\`markdown
- [ ] T99 example in a code fence must not count
\`\`\`
- [ ] T03 pending slice

## Risks / Stop Rules
Stop on ambiguity or repeated failure.

## Validation Policy
Local-only checks; no provider calls.

## Validation
- 2026-09-15 targeted tests pass.
- [ ] validation checkbox must not count

## Notes
- [ ] outside Tasks must not count

## Unresolved
- Unresolved sentinel: confirm scoped-model behavior.
`);

    // Legacy recovery is independent of the current date and prefers the full ID.
    const currentPlanBody = await readFile(join(dir,pointerRel),'utf8');
    await rm(join(dir,pointerRel));
    const historicalRel = `.ai/plan/2024-01-02-${fullSessionId}-historical.md`;
    await writeFile(join(dir,historicalRel),currentPlanBody);
    const got = await getPlanTool.execute('m',{},undefined,undefined,memCtx);
    assert.equal(got.details.source,'current-session');
    assert.equal(got.details.planStatus,'in-progress');
    assert.deepEqual(got.details.planTasks,{total:3,open:2,done:1});
    assert.match(got.details.planCurrentStep,/T08/);
    assert.match(got.details.planActiveTask,/T02/);
    assert.match(got.details.planWarning,/Unresolved sentinel/);
    assert.equal(got.details.path,historicalRel);
    await writeFile(join(dir,pointerRel),currentPlanBody);

    // Pointer-first resolution beats a newer plan file; never resolved by mtime.
    const newerRel = '.ai/plan/2026-09-15-decoy0000-newest-by-mtime.md';
    await writeFile(join(dir,newerRel),'# Plan: decoy\n\nDECOY_NEWEST_BY_MTIME\n');
    const ptrCtx = ctxWithPointers([[pointerRel]]);
    const viaPointer = await getPlanTool.execute('m',{},undefined,undefined,ptrCtx);
    assert.equal(viaPointer.details.source,'active-pointer');
    assert.match(viaPointer.content[0].text,/pointer-plan/);
    assert.doesNotMatch(viaPointer.content[0].text,/DECOY_NEWEST_BY_MTIME/);

    // The latest pointer in the active branch is authoritative: A -> B selects B.
    const nextRel = '.ai/plan/2026-09-15-next-plan.md';
    await writeFile(join(dir,nextRel),planBody.replace('# Plan: pointer-plan','# Plan: next-plan'));
    const branchCtx = ctxWithPointers([[pointerRel],[nextRel]]);
    const viaNext = await getPlanTool.execute('m',{},undefined,undefined,branchCtx);
    assert.equal(viaNext.details.source,'active-pointer');
    assert.equal(viaNext.details.path,nextRel);
    assert.match(viaNext.content[0].text,/next-plan/);

    // Fail-closed blockers: worktree/session mismatch, traversal, and missing file.
    await assert.rejects(getPlanTool.execute('b',{},undefined,undefined,ctxWithPointers([[pointerRel,{worktree:'/elsewhere/worktree'}]])),/different worktree/);
    await assert.rejects(getPlanTool.execute('b',{},undefined,undefined,ctxWithPointers([[pointerRel,{sessionId:'other-session-9999'}]])),/different session/);
    await assert.rejects(getPlanTool.execute('b',{},undefined,undefined,ctxWithPointers([['../../escape.md']])),/escapes \.ai\/plan\//);
    await assert.rejects(getPlanTool.execute('b',{},undefined,undefined,ctxWithPointers([['.ai/plan/2026-09-15-vanished.md']])),/missing, non-file/);

    // A missing selected file remains blocked; creation never recreates it.
    await assert.rejects(planTool.execute('b',{slug:'replacement'},undefined,undefined,ctxWithPointers([['.ai/plan/2026-09-15-vanished.md']])),/will not be recreated/);
    const replacementPath = join(dir,'.ai/plan/2026-09-15-vanished.md');
    assert.equal(existsSync(replacementPath),false);

    // Explicit selection/adoption never overwrites or recreates the file.
    const selected = await toolOf('select_session_plan').execute('s',{path:nextRel},undefined,undefined,ctx);
    assert.equal(selected.details.selected,false,'fixture runtime cannot persist appendEntry outside a live session');
    assert.equal(existsSync(join(dir,nextRel)),true);

    // summarize_worktree reports bounded plan state next to Git information.
    const sum = await sumTool.execute('m',{},undefined,undefined,ptrCtx);
    assert.match(sum.content[0].text,/Branch: /);
    assert.match(sum.content[0].text,/Current plan: .*pointer-plan\.md \(active-pointer\)/);
    assert.match(sum.content[0].text,/Plan status: in-progress/);
    assert.match(sum.content[0].text,/Plan tasks: 2 open \/ 1 done \(3 total\)/);
    assert.match(sum.content[0].text,/Active task: .*T02 active regression slice/);
    assert.equal(sum.details.planSource,'active-pointer');
    assert.deepEqual(sum.details.planTasks,{total:3,open:2,done:1});

    // TUI mode refreshes the existing status/widget surfaces; other modes do not.
    const uiCalls = [];
    const ui = {setStatus:(key,value)=>uiCalls.push(['status',key,value]), setWidget:(key,lines)=>uiCalls.push(['widget',key,lines])};
    await getPlanTool.execute('u',{},undefined,undefined,{...ptrCtx,mode:'tui',ui});
    const lastStatus = uiCalls.filter(c=>c[0]==='status').pop();
    const lastWidget = uiCalls.filter(c=>c[0]==='widget').pop();
    assert.match(String(lastStatus?.[2]),/Plan in-progress · 2 open\/1 done/);
    const widgetText = (lastWidget?.[2]||[]).join('\n');
    assert.match(widgetText,/Plan: .*pointer-plan\.md \(in-progress\)/);
    assert.match(widgetText,/TL;DR: Finish the provider-free regression matrix/);
    assert.match(widgetText,/Step: T08 regression coverage in progress/);
    assert.match(widgetText,/Tasks: 2 open \/ 1 done \(3 total\)/);
    assert.match(widgetText,/Warning: .*Unresolved sentinel/);
    const offCalls = [];
    const offUi = {setStatus:()=>offCalls.push(1), setWidget:()=>offCalls.push(1)};
    await getPlanTool.execute('u',{},undefined,undefined,{...ptrCtx,mode:'json',ui:offUi});
    assert.equal(offCalls.length,0,'non-TUI mode must not touch the status/widget UI');

    // Bounded injection: path/status/counts/step/active task/warning, never the full body.
    const planInjection = await memory.handlers.get('before_agent_start')[0]({systemPrompt:'base'},ptrCtx);
    assert.match(planInjection.systemPrompt,/pointer-plan/);
    assert.match(planInjection.systemPrompt,/in-progress/);
    assert.match(planInjection.systemPrompt,/2 open \/ 1 done \(3 total\)/);
    assert.match(planInjection.systemPrompt,/Finish the provider-free regression matrix/);
    assert.match(planInjection.systemPrompt,/T08 regression coverage in progress/);
    assert.match(planInjection.systemPrompt,/T02 active regression slice/);
    assert.match(planInjection.systemPrompt,/Unresolved sentinel/);
    assert.doesNotMatch(planInjection.systemPrompt,/HIDDEN_FULL_PLAN_BODY_MARKER|## Spec \/ Contract|## Validation Policy/);
    assert.ok(planInjection.systemPrompt.length<4000);
    const contextHandler = memory.handlers.get('context')[0];
    const contextual = await contextHandler({type:'context',messages:[]},ptrCtx);
    assert.equal(contextual.messages.length,1);
    assert.match(contextual.messages[0].content,/Finish the provider-free regression matrix/);
    assert.doesNotMatch(contextual.messages[0].content,/HIDDEN_FULL_PLAN_BODY_MARKER|## Spec \/ Contract/);
    for (const eventName of ['session_compact','tool_execution_end','turn_end','agent_end','agent_settled']) {
      assert.ok(memory.handlers.get(eventName)?.length, `missing refresh hook: ${eventName}`);
    }

    // session_before_switch clears stale status/widget text in TUI mode only.
    uiCalls.length = 0;
    await memory.handlers.get('session_before_switch')[0]({}, {...ptrCtx,mode:'tui',ui});
    assert.equal(uiCalls.filter(c=>c[0]==='status').pop()?.[2],undefined);
    assert.equal(uiCalls.filter(c=>c[0]==='widget').pop()?.[2],undefined);
    const offClearCalls = [];
    const offClearUi = {setStatus:()=>offClearCalls.push(1), setWidget:()=>offClearCalls.push(1)};
    await memory.handlers.get('session_before_switch')[0]({}, {...ptrCtx,mode:'json',ui:offClearUi});
    assert.equal(offClearCalls.length,0);

    await planTool.execute('x',{slug:'test-plan'},undefined,undefined,ctx);
    await writeFile(join(dir,'.ai/TASKS.md'),'# Tasks\n## Inbox\n- [ ] inbox sentinel\n## In Progress\n- [ ] active sentinel\n## Done\n'+('- [x] done sentinel\n'.repeat(1000)));
    const injection=await memory.handlers.get('before_agent_start')[0]({systemPrompt:'base'},ctx);
    assert.match(injection.systemPrompt,/active sentinel/);
    assert.doesNotMatch(injection.systemPrompt,/done sentinel|inbox sentinel/);
    assert.ok(injection.systemPrompt.length<4000);

    // ── Prompt-contract assertions: explicit confirmation gates and resume language. ──
    const planPrompt = await readFile(join(here,'..','..','prompts','plan.md'),'utf8');
    assert.match(planPrompt,/^description: .+/m);
    assert.match(planPrompt,/ask for explicit approval using the existing question tool\/UI/);
    assert.match(planPrompt,/No planner `subagent` call may happen before an explicit approval/);
    assert.match(planPrompt,/Treat a decline as an end to the planner path/);
    assert.match(planPrompt,/Persistence and read-back are mandatory before the final response/);
    assert.match(planPrompt,/re-read the entire file from disk/);
    const runPrompt = await readFile(join(here,'..','..','prompts','run-plan.md'),'utf8');
    assert.match(runPrompt,/^description: .+/m);
    assert.match(runPrompt,/ask for explicit confirmation using the existing question tool\/UI/);
    assert.match(runPrompt,/No architect, worker, or any `subagent` call may happen before the user confirms/);
    assert.match(runPrompt,/mark it `in-progress` in the plan before dispatching/);
    assert.match(runPrompt,/Never infer or record progress from chat history or file mtime alone/);
    assert.match(runPrompt,/On resume, reread the plan's completed\/blocked task records/);
    assert.match(runPrompt,/Never restart accepted work/);
    assert.match(runPrompt,/Never select a plan by modification time/);
  } finally {
    process.env.PATH=oldPath;
    if(oldFixture===undefined)delete process.env.PI_TEST_FIXTURE;else process.env.PI_TEST_FIXTURE=oldFixture;
    await rm(dir,{recursive:true,force:true});
  }
});
