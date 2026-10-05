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

// Models the installed UI contract: stays pending until a user decision or opts.signal abort.
function pendingDialog() {
  const opened = Promise.withResolvers();
  const answer = Promise.withResolvers();
  const dialog = {
    opened: opened.promise,
    choose: answer.resolve,
    select(title, options, opts) {
      dialog.calls = (dialog.calls ?? 0) + 1;
      dialog.title = title;
      dialog.options = options;
      dialog.signal = opts?.signal;
      const cancel = () => answer.resolve(undefined);
      opts?.signal?.addEventListener('abort', cancel, {once:true});
      if (opts?.signal?.aborted) cancel();
      opened.resolve();
      return answer.promise.finally(()=>opts?.signal?.removeEventListener('abort', cancel));
    },
  };
  return dialog;
}
async function settles(promise) {
  let timer;
  try {
    return await Promise.race([promise, new Promise((_,reject)=>{
      timer = setTimeout(()=>reject(new Error('dialog did not settle after abort')),1000);
    })]);
  } finally { clearTimeout(timer); }
}

async function createMemorySessionFixture(dir, sessionId) {
  const {SessionManager} = await import(pathToFileURL(join(sdkRoot,'dist/index.js')));
  const {loadExtensions,createExtensionRuntime} = await import(pathToFileURL(join(sdkRoot,'dist/core/extensions/loader.js')));
  let sm = SessionManager.create(dir,join(dir,'sessions'),sessionId ? {id:sessionId} : undefined);
  // Real persistence starts after an assistant message; this one is entirely fictitious.
  const before = sm.appendMessage({role:'assistant',content:[],api:'fixture',provider:'fixture',model:'fixture',stopReason:'stop',timestamp:0,
    usage:{input:0,output:0,cacheRead:0,cacheWrite:0,totalTokens:0,cost:{input:0,output:0,cacheRead:0,cacheWrite:0,total:0}}});
  const runtime = createExtensionRuntime();
  runtime.appendEntry = (type,data)=>sm.appendCustomEntry(type,data);
  const loaded = await loadExtensions([join(here,'../memory.ts')],dir,undefined,runtime);
  assert.deepEqual(loaded.errors,[]);
  const ext = loaded.extensions[0];
  const ctx = {cwd:dir,hasUI:true,ui:{confirm:async()=>true},get sessionManager(){return sm;}};
  const call = (name,params={},signal,over={}) => {
    const registered = ext.tools.get(name);
    return (registered.definition??registered).execute('fixture',params,signal,undefined,{...ctx,...over});
  };
  return {dir,call,before,ctx,get sm(){return sm;},reopen(){sm=SessionManager.open(sm.getSessionFile(),join(dir,'sessions'));}};
}

async function memoryFixture(run) {
  const dir = await mkdtemp(join(tmpdir(),'pi-memory-regression-'));
  try {
    await run(await createMemorySessionFixture(dir));
  } finally {await rm(dir,{recursive:true,force:true});}
}

test('memory: persisted selection, full active branch, abandoned branch and read errors',{skip:!sdkRoot},async()=>{
  await memoryFixture(async f=>{
    const created = await f.call('create_session_plan',{slug:'a'});
    assert.equal(created.details.pointerPersisted,true);
    assert.match((await f.call('get_current_plan')).details.planActiveTask,/T1/);
    const a = created.details.path;
    const plan = join(f.dir,a);
    const editedBody = (await readFile(plan,'utf8'))
      .replace('- Status: pending','- Status: completed')
      .replace('- [ ] T1: ...','- [x] T1: Implement the requested work');
    await writeFile(plan,editedBody);
    const refreshed = await f.call('get_current_plan');
    assert.equal(refreshed.details.path,a);
    assert.equal(refreshed.details.planStatus,'completed');
    assert.deepEqual(refreshed.details.planTasks,{total:1,open:0,done:1},'a new explicit query reads edited task state');
    const appendSystem = await readFile(join(here,'../../APPEND_SYSTEM.md'),'utf8');
    assert.match(appendSystem,/reviewing its results continues the same plan even if its tasks are completed/);
    assert.match(appendSystem,/Start another plan only for an independent goal or material scope change/);
    f.reopen();
    assert.equal((await f.call('get_current_plan')).details.path,a);
    const kept = f.sm.appendMessage({role:'user',content:'retained fixture',timestamp:0});
    f.sm.appendCompaction('fixture summary',kept,100);
    assert.ok(f.sm.getBranch().some(e=>e.customType==='memory.active-plan'));
    assert.ok(!f.sm.buildContextEntries().some(e=>e.customType==='memory.active-plan'));
    assert.equal((await f.call('get_current_plan')).details.path,a);
    const compactedLeaf = f.sm.getLeafId();
    const another = await f.call('create_session_plan',{slug:'b',newPlan:true});
    assert.notEqual(another.details.path,a);
    f.sm.branch(compactedLeaf);
    assert.equal((await f.call('get_current_plan')).details.path,a,'ignore newer B outside active branch');
    f.sm.branch(f.before);
    assert.ok(f.sm.getEntries().some(e=>e.customType==='memory.active-plan'));
    assert.ok(!f.sm.getBranch().some(e=>e.customType==='memory.active-plan'));
    assert.equal(existsSync(join(f.dir,a)),true);
    await assert.rejects(f.call('get_current_plan'),/branch has no active plan selection/);
    await assert.rejects(f.call('create_session_plan',{slug:'a'}),/branch has no active plan selection/);
    for (const method of ['getBranch','getEntries']) {
      const broken = {getSessionId:()=>f.sm.getSessionId(),getBranch:()=>[],getEntries:()=>[],[method]:()=>{throw new Error('state read failed');}};
      await assert.rejects(f.call('get_current_plan',{},undefined,{sessionManager:broken}),/state read failed/);
      await assert.rejects(f.call('create_session_plan',{slug:'a'},undefined,{sessionManager:broken}),/state read failed/);
    }
  });
});

test('memory: legacy recovery and coherent real tasks / explicit IDs',{skip:!sdkRoot},async()=>{
  await memoryFixture(async f=>{
    await mkdir(join(f.dir,'.ai/plan'),{recursive:true});
    const a = `.ai/plan/2020-01-02-${f.sm.getSessionId().slice(0,8)}-legacy.md`;
    const body = (step) => `# Plan: legacy\n## Current Step\n${step}\n## Tasks\n\`\`\`markdown\n- [ ] T99 fictitious\n\`\`\`\n- [ ] T1 real first\n  - [ ] T90 subtask\n- [ ] T2 real second\n## Validation\n- [ ] T91 not a task\n`;
    for(const [step,expected] of [
      ['',/T1 real first/],
      ['- Current: T2\n- Next: T1\n- Blockers: none',/T2 real second/],
      ['- Next: T2\n- Current: T1\n- Blockers: none',/T1 real first/],
      ['- Current: none\n- Next: T2\n- Blockers: T2 awaits T1',/T1 real first/],
      ['- Current: T08\n- Next: T1\n- Blockers: none',/Inconsistent Current Step: T08.*not found/],
      ['T08 old free-form step',/Inconsistent Current Step: T08.*not found/],
    ]) {
      await writeFile(join(f.dir,a),body(step));
      const got = await f.call('get_current_plan');
      assert.equal(got.details.source,'current-session');
      assert.equal(got.details.path,a);
      assert.deepEqual(got.details.planTasks,{total:2,open:2,done:0});
      assert.match(got.details.planActiveTask,expected);
      assert.doesNotMatch(got.details.planActiveTask,/T99/);
    }

    const foreignMetadata = body('').replace('## Tasks', '- Session ID: 019eaabc-1111-7000-8000-000000000001\n## Tasks');
    await writeFile(join(f.dir,a),foreignMetadata);
    await assert.rejects(f.call('get_current_plan'),/Plan metadata belongs to a different session/,
      'a genuine abbreviated filename with incompatible identity metadata remains blocked');

    const ambiguous = `.ai/plan/2020-01-03-${f.sm.getSessionId().slice(0,8)}-legacy-b.md`;
    await writeFile(join(f.dir,ambiguous),body(''));
    await assert.rejects(f.call('get_current_plan'),/Multiple current-session plan candidates/,
      'multiple genuine legacy names remain ambiguous');
    await rm(join(f.dir,ambiguous));
  });
});

test('memory: shared 8-character prefixes do not make modern plans legacy candidates',{skip:!sdkRoot},async()=>{
  const dir = await mkdtemp(join(tmpdir(),'pi-memory-prefix-isolation-'));
  const idA = '019eaabc-1111-7000-8000-000000000001';
  const idB = '019eaabc-2222-7000-8000-000000000002';
  try {
    const a = await createMemorySessionFixture(dir,idA);
    const b = await createMemorySessionFixture(dir,idB);
    assert.equal(a.sm.getSessionId(),idA);
    assert.equal(b.sm.getSessionId(),idB);
    const worktree = (await realpath(dir)).replace(/[\\/]+$/,'');
    const planA = `.ai/plan/2026-10-05-${idA}-plan-a.md`;
    await mkdir(join(dir,'.ai/plan'),{recursive:true});
    const bodyA = `# Plan: plan-a\n- Status: in-progress\n- Session ID: ${idA}\n- Worktree: ${worktree}\n\n## Tasks\n- [ ] T1: Keep A's work\n`;
    await writeFile(join(dir,planA),bodyA);

    const selectedA = await a.call('select_session_plan',{path:planA});
    assert.equal(selectedA.details.selected,true);
    assert.equal((await a.call('get_current_plan')).details.path,planA);

    const pointerA = a.sm.getBranch().find(entry=>entry.customType==='memory.active-plan');
    assert.ok(pointerA,'A has a real persisted pointer');
    const c = await createMemorySessionFixture(dir,'019eaabd-3333-7000-8000-000000000003');
    c.sm.appendCustomEntry(pointerA.customType,pointerA.data);
    await assert.rejects(c.call('get_current_plan'),/different session/,
      'a real pointer copied from A into C remains a fail-closed session mismatch');

    const initialB = await b.call('get_current_plan');
    assert.equal(initialB.details.exists,false,'B reports no plan instead of treating A’s modern filename as legacy');
    assert.match(initialB.content[0].text,/No plan file found/);
    assert.doesNotMatch(initialB.content[0].text,/blocked|different session/i);

    const createdB = await b.call('create_session_plan',{slug:'plan-b'});
    assert.equal(createdB.details.created,true,'B creates its first plan without newPlan=true');
    assert.ok(createdB.details.path.includes(idB));
    assert.notEqual(createdB.details.path,planA);
    assert.equal((await b.call('get_current_plan')).details.path,createdB.details.path);
    assert.equal((await a.call('get_current_plan')).details.path,planA,'B’s new pointer does not alter A’s selection');
    assert.equal(await readFile(join(dir,planA),'utf8'),bodyA,'A’s plan remains unchanged');
    const pointerFor = fixture => fixture.sm.getBranch().find(entry=>entry.customType==='memory.active-plan')?.data;
    assert.equal(pointerFor(a)?.sessionId,idA);
    assert.equal(pointerFor(a)?.planPath,planA);
    assert.equal(pointerFor(b)?.sessionId,idB);
    assert.equal(pointerFor(b)?.planPath,createdB.details.path);
  } finally {await rm(dir,{recursive:true,force:true});}
});

test('memory: confirm selection/newPlan before mutation; cancel, abort and reopen',{skip:!sdkRoot},async()=>{
  await memoryFixture(async f=>{
    const untouched = f.sm.getEntries();
    for(const [name,params] of [['select_session_plan',{path:'.ai/plan/absent.md'}],['create_session_plan',{slug:'another',newPlan:true}]]) {
      assert.equal((await f.call(name,params,undefined,{ui:{confirm:async()=>false}})).details.status,'cancelled');
      assert.equal(existsSync(join(f.dir,'.ai')),false,'no documents/directories on cancelled first switch');
      assert.deepEqual(f.sm.getEntries(),untouched);
    }
    const created = await f.call('create_session_plan',{slug:'a'},undefined,{hasUI:false,ui:undefined});
    const a = created.details.path;
    const b = '.ai/plan/existing-b.md';
    await writeFile(join(f.dir,b),'# Plan: B\n');
    const original = await readFile(join(f.dir,a),'utf8');
    const originalEntries = f.sm.getEntries();
    const {readdir} = await import('node:fs/promises');
    const files = await readdir(join(f.dir,'.ai/plan'));
    for(const [name,params] of [['select_session_plan',{path:b}],['create_session_plan',{slug:'another',newPlan:true}]]) {
      const unchanged = async()=>{
        assert.deepEqual(f.sm.getEntries(),originalEntries);
        assert.deepEqual(await readdir(join(f.dir,'.ai/plan')),files);
        assert.equal(await readFile(join(f.dir,a),'utf8'),original);
        assert.equal(await readFile(join(f.dir,b),'utf8'),'# Plan: B\n');
        assert.equal((await f.call('get_current_plan')).details.path,a);
      };
      const declined = await f.call(name,params,undefined,{ui:{confirm:async()=>false}});
      assert.equal(declined.details.status,'cancelled');
      await unchanged();
      await assert.rejects(f.call(name,params,undefined,{hasUI:false,ui:undefined}),/no UI/);
      await unchanged();
      const abort = new AbortController();
      abort.abort();
      const preAborted = await f.call(name,params,abort.signal,{ui:{confirm:()=>assert.fail('pre-aborted dialog opened')}});
      assert.equal(preAborted.details.status,'cancelled');
      await unchanged();
      const pending = pendingDialog();
      const controller = new AbortController();
      const run = f.call(name,params,controller.signal,{ui:{confirm:pending.select}});
      await settles(pending.opened);
      assert.match(pending.options,name==='select_session_plan'?/existing-b.md/:/another/);
      await unchanged();
      controller.abort();
      assert.equal((await settles(run)).details.status,'cancelled');
      assert.equal(pending.signal,controller.signal);
      await unchanged();
    }
    const {symlink} = await import('node:fs/promises');
    const outside = join(f.dir,'outside-plan.md');
    await writeFile(outside,'outside sentinel');
    const link = '.ai/plan/outside-link.md';
    await symlink(outside,join(f.dir,link));
    await assert.rejects(f.call('select_session_plan',{path:link}),/existing regular file within/);
    assert.equal(await readFile(outside,'utf8'),'outside sentinel');
    assert.deepEqual(f.sm.getEntries(),originalEntries);
    const selected = await f.call('select_session_plan',{path:b});
    assert.equal(selected.details.selected,true);
    assert.equal(selected.details.pointerPersisted,true);
    f.reopen();
    assert.equal((await f.call('get_current_plan')).details.path,b);
    const fresh = await f.call('create_session_plan',{slug:'another',newPlan:true});
    assert.equal(fresh.details.created,true);
    assert.equal(fresh.details.pointerPersisted,true);
    assert.notEqual(fresh.details.path,a);
    assert.notEqual(fresh.details.path,b);
    f.reopen();
    assert.equal((await f.call('get_current_plan')).details.path,fresh.details.path);
    assert.equal(await readFile(join(f.dir,a),'utf8'),original);
    assert.equal(await readFile(join(f.dir,b),'utf8'),'# Plan: B\n');
  });
});
test('actual extension loading, allowlists, protocol, usage and failure hook', {skip: !sdkRoot}, async () => {
  const { DefaultResourceLoader, SettingsManager, SessionManager } = await import(pathToFileURL(join(sdkRoot, 'dist/index.js')));
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
    assert.equal(tool.parameters.properties.thinking, undefined, 'thinking is not a generic subagent argument');
    // Fake registry covering every configured agent/profile model. All are reasoning
    // models supporting off/minimal/low/medium/high; only Luna maps `max`.
    const thinkMap = {off:'off',minimal:'minimal',low:'low',medium:'medium',high:'high'};
    const fakeModel = (providerModel, extraMap = {}) => {
      const [provider, id] = providerModel.split('/');
      return {provider, id, reasoning:true, contextWindow:272000, thinkingLevelMap:{...thinkMap, ...extraMap}};
    };
    const MODELS = {
      deepseek: fakeModel('opencode-go/deepseek-v4.1-flash'),      // scout frontmatter
      glm: fakeModel('opencode-go/glm-5.3-flash'),                 // worker frontmatter
      luna: fakeModel('openai-codex/gpt-5.6-luna', {max:'max'}),   // scoped-model fixture
      roleLuna: fakeModel('openai-codex/gpt-6-luna', {max:'max'}), // researcher/worker
      sol: fakeModel('openai-codex/gpt-5.6-sol'),                  // other configured role
      astra: fakeModel('openai-codex/gpt-6-astra'),                // other configured role
      planner: fakeModel('openai-codex/gpt-6.1-sol'),              // planner profiles
    };
    const byModel = new Map(Object.values(MODELS).map(m => [`${m.provider}/${m.id}`, m]));
    const scopedModels = Object.values(MODELS).map(m => ({model:{provider:m.provider, id:m.id}}));
    const ctx = {
      cwd:dir,
      sessionManager:SessionManager.inMemory(dir),
      scopedModels,
      modelRegistry:{find:(p,id)=>byModel.get(`${p}/${id}`)},
      hasUI:true,
      ui:{select:async (_title, options)=>options[0], confirm:async()=>true, notify:()=>{}},
    };
    const usage = {input:10,output:2,cacheRead:5,cacheWrite:0,totalTokens:17,cost:{input:.01,output:.02,cacheRead:0,cacheWrite:0,total:.03}};
    const scoutModel = MODELS.deepseek;
    const event = (reason,text,extra={})=>({type:'message_end',message:{role:'assistant',provider:scoutModel.provider,model:scoutModel.id,stopReason:reason,content:[{type:'text',text}],usage,...extra}});
    await writeFile(process.env.PI_TEST_FIXTURE,JSON.stringify(event('stop','**Status**: complete\nVerified.'))+'\n');
    const success = await tool.execute('s',{agent:'scout',task:'Locate fixture'},undefined,undefined,ctx);
    assert.equal(success.details.status,'complete');
    assert.equal(success.usage.input,10);
    assert.equal(success.usage.cost.total,.03);
    assert.equal(success.details.results[0].thinking,'high');
    const argv = JSON.parse(await readFile(process.env.PI_TEST_FIXTURE+'.args','utf8'));
    // Scout frontmatter pins opencode-go/deepseek-v4.1-flash; no fallback to Luna.
    assert.equal(argv[argv.indexOf('--model')+1],'opencode-go/deepseek-v4.1-flash');
    assert.equal(argv[argv.indexOf('--tools')+1],'read,grep,find,ls');
    assert.ok(!argv.includes('--no-context-files'));
    assert.equal(argv[argv.indexOf('--system-prompt')+1], join(here, 'SYSTEM.md'));
    await rm(process.env.PI_TEST_FIXTURE+'.args',{force:true});
    await assert.rejects(
      tool.execute('s-override',{agent:'scout',task:'Override fixture',thinking:'low'},undefined,undefined,ctx),
      /Thinking overrides are only valid for the "planner" agent/,
    );
    assert.equal(existsSync(process.env.PI_TEST_FIXTURE+'.args'),false,'non-planner override must not spawn');
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
      ['low','low','openai-codex/gpt-6.1-sol','low'],
      ['medium','medium','openai-codex/gpt-6.1-sol','medium'],
      ['high','high','openai-codex/gpt-6.1-sol','high'],
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
    // Omitting profile still requires a real approval and records the selected
    // effective profile; headless execution and cancellation cannot spawn.
    const withoutProfile = await tool.execute('np',{agent:'planner',task:'No profile fixture'},undefined,undefined,ctx);
    assert.equal(withoutProfile.details.status,'complete');
    assert.equal(withoutProfile.details.results[0].profile,'low');
    const defaultArgs = JSON.parse(await readFile(process.env.PI_TEST_FIXTURE+'.args','utf8'));
    assert.equal(defaultArgs[defaultArgs.indexOf('--model')+1],'openai-codex/gpt-6.1-sol');
    assert.equal(defaultArgs[defaultArgs.indexOf('--thinking')+1],'low');
    // ── Planner recommendation: the coordinator's level and reason reach the dialog. ──
    let seenTitle = '';
    let seenOptions = [];
    const recordingUi = {...ctx,ui:{select:async (title, options)=>{seenTitle=title;seenOptions=options;return options[0];},notify:()=>{}}};
    const suggestedReason = 'Competing designs and an unresolved trade-off';
    const suggested = await tool.execute('pr',{agent:'planner',task:'Suggestion fixture',profile:'medium',profileReason:suggestedReason},undefined,undefined,recordingUi);
    assert.equal(suggested.details.status,'complete');
    assert.match(seenTitle,/^Planner approval — recommended medium: Competing designs and an unresolved trade-off — /);
    assert.match(seenTitle,/Suggestion fixture/);
    assert.equal(seenOptions[0],'Approve medium (recommended) — openai-codex/gpt-6.1-sol @ medium');
    assert.ok(seenOptions.includes('Choose low — openai-codex/gpt-6.1-sol @ low'),'other available levels remain selectable');
    assert.equal(seenOptions.at(-1),'Cancel planner launch');
    assert.equal(suggested.details.results[0].profileReason,suggestedReason);
    // Without a reason the dialog keeps its previous wording and records none.
    const plainUi = {...ctx,ui:{select:async (title, options)=>{seenTitle=title;return options[0];},notify:()=>{}}};
    const plain = await tool.execute('pu',{agent:'planner',task:'Plain title fixture',profile:'low'},undefined,undefined,plainUi);
    assert.equal(plain.details.status,'complete');
    assert.doesNotMatch(seenTitle,/recommended/);
    assert.equal(plain.details.results[0].profileReason,undefined);
    // A reason is planner-only, like the profile itself, and never spawns.
    await rm(process.env.PI_TEST_FIXTURE+'.args',{force:true});
    await assert.rejects(tool.execute('px',{agent:'scout',task:'Reason fixture',profileReason:'nope'},undefined,undefined,{...ctx,ui:{select:()=>assert.fail('non-planner reason opened the planner approval'),notify:()=>{}}}),/only valid for the "planner" agent/);
    assert.equal(existsSync(process.env.PI_TEST_FIXTURE+'.args'),false,'non-planner profileReason must not spawn');
    const profileArgsFile = process.env.PI_TEST_FIXTURE+'.args';
    await rm(profileArgsFile,{force:true});
    const cancelledUi = {...ctx,ui:{select:async (_title, options)=>options.at(-1), notify:()=>{}}};
    const declined = await tool.execute('pc',{agent:'planner',task:'Cancel fixture',profile:'low'},undefined,undefined,cancelledUi);
    assert.equal(declined.details.status,'cancelled');
    assert.equal(declined.terminate,true);
    const declineHooks = await Promise.all(hooks.map(h=>h({toolName:'subagent',details:declined.details},ctx)));
    assert.ok(!declineHooks.some(x=>x?.isError===true));
    assert.equal(existsSync(profileArgsFile),false,'cancelled planner must not spawn');
    await assert.rejects(tool.execute('ph',{agent:'planner',task:'Headless fixture',profile:'low'},undefined,undefined,{...ctx,hasUI:false,ui:undefined}),/no UI/);
    assert.equal(existsSync(profileArgsFile),false,'headless planner must not spawn');
    const abortedPlanner = new AbortController();
    abortedPlanner.abort();
    const abortedPlannerResult = await tool.execute('pa',{agent:'planner',task:'Abort fixture',profile:'low'},abortedPlanner.signal,undefined,{...ctx,ui:{select:()=>assert.fail('already aborted invocation opened UI')}});
    assert.equal(abortedPlannerResult.details.status,'cancelled');
    assert.equal(existsSync(profileArgsFile),false,'aborted planner must not spawn');
    // A genuinely pending selector: no child until a decision; abort dismisses it.
    const pending = pendingDialog();
    const waitingAbort = new AbortController();
    const waitingRun = tool.execute('pw',{agent:'planner',task:'Pending approval',profile:'medium'},waitingAbort.signal,undefined,{...ctx,ui:{select:pending.select}});
    await pending.opened;
    assert.equal(existsSync(profileArgsFile),false);
    waitingAbort.abort();
    const waitingResult = await settles(waitingRun);
    assert.equal(waitingResult.details.status,'cancelled');
    assert.equal(pending.calls,1);
    assert.equal(existsSync(profileArgsFile),false);
    assert.equal(pending.signal,waitingAbort.signal);

    const approval = pendingDialog();
    const approvedRun = tool.execute('pok',{agent:'planner',task:'Pending approval',profile:'medium'},undefined,undefined,{...ctx,ui:{select:approval.select}});
    await approval.opened;
    assert.equal(existsSync(profileArgsFile),false,'no child before manual decision');
    assert.match(approval.options[0],/openai-codex\/gpt-6.1-sol @ medium/);
    approval.choose(approval.options[0]);
    assert.equal((await approvedRun).details.status,'complete');
    assert.equal(approval.calls,1);
    const approvedArgs = JSON.parse(await readFile(profileArgsFile,'utf8'));
    assert.equal(approvedArgs[approvedArgs.indexOf('--model')+1],'openai-codex/gpt-6.1-sol');
    assert.equal(approvedArgs[approvedArgs.indexOf('--thinking')+1],'medium');

    await rm(profileArgsFile,{force:true});
    const lastMomentAbort = new AbortController();
    const lastMoment = await tool.execute('late',{agent:'planner',task:'Abort on approval',profile:'medium'},lastMomentAbort.signal,undefined,
      {...ctx,ui:{select:async(_title,options)=>{lastMomentAbort.abort();return options[0];}}});
    assert.equal(lastMoment.details.status,'cancelled');
    assert.equal(existsSync(profileArgsFile),false,'recheck abort after UI, before spawn');

    // Fail-fast paths below must all reject before the fake child spawns: the
    // recorded args file is removed first and must stay absent after each reject.
    await rm(profileArgsFile,{force:true});
    const noRegistry = {...ctx, modelRegistry:{find:()=>undefined}};
    const narrowScope = {...ctx, scopedModels:[{model:{provider:'openai-codex', id:'gpt-5.6-luna'}}]};
    const noThinking = {...ctx, modelRegistry:{find:(p,id)=>{
      const model=byModel.get(`${p}/${id}`);
      return model && `${p}/${id}`==='openai-codex/gpt-6.1-sol' ? {...model,thinkingLevelMap:{...model.thinkingLevelMap,high:null}} : model;
    }}};
    const noLowThinking = {...ctx, modelRegistry:{find:(p,id)=>{
      const model=byModel.get(`${p}/${id}`);
      return model && `${p}/${id}`==='openai-codex/gpt-6.1-sol' ? {...model,thinkingLevelMap:{...model.thinkingLevelMap,low:null}} : model;
    }},ui:{select:()=>assert.fail('unavailable low must not open approval for higher levels')}};
    await assert.rejects(tool.execute('no-low',{agent:'planner',task:'Unavailable low'},undefined,undefined,noLowThinking),/Unsupported thinking low/);
    assert.equal(existsSync(profileArgsFile),false,'unavailable low must not spawn');
    const failFast = [
      [{agent:'scout',task:'x',profile:'low'}, /only valid for the "planner" agent/],
      [{agent:'planner',task:'x',profile:'habitual'}, /Unknown profile/],
      [{agent:'planner',task:'x',profile:'low'}, /Configured model unavailable: openai-codex\/gpt-6.1-sol/],
      [{agent:'planner',task:'x',profile:'low'}, /not in this session's scoped models/],
      [{agent:'planner',task:'x',profile:'high'}, /Unsupported thinking high/],
      [{agent:'planner',task:'x'}, /Configured model unavailable: openai-codex\/gpt-6.1-sol/],
    ];
    for (const [index, [params, pattern]] of failFast.entries()) {
      const failCtx = index === 2 || index === 5 ? noRegistry : index === 3 ? narrowScope : index === 4 ? noThinking : ctx;
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
    // This loader retains the throwing appendEntry stub to cover persistence
    // failure. Separate regressions below bind it to a real temporary SessionManager.
    const POINTER_TYPE = 'memory.active-plan'; // memory.ts PLAN_POINTER_TYPE contract
    const fullSessionId = '01a0a3bf-2233-4455-8a9b-ccddeeff0001';
    const worktree = (await realpath(dir)).replace(/[\\/]+$/,'');
    const pointerEntry = (planPath, over = {}) => ({
      type:'custom', customType:POINTER_TYPE,
      data:{v:1, planPath, sessionId:fullSessionId, worktree, slug:'pointer-plan', updatedAt:'2026-09-15T00:00:00.000Z', ...over},
    });
    const sessionState = (entries = []) => ({
      getSessionId:()=>fullSessionId,
      getBranch:()=>entries,
      buildContextEntries:()=>entries,
      getEntries:()=>entries,
    });
    const memCtx = {cwd:dir, sessionManager:sessionState()};
    const ctxWithPointers = (entries) => ({...memCtx, sessionManager:sessionState(entries.map(([p, over]) => pointerEntry(p, over)))});

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
    assert.match(got.details.planActiveTask,/Inconsistent Current Step: T08.*not found/);
    // Restore a consistent current task for snapshot/UI assertions below.
    const consistentBody = currentPlanBody.replace('T08 regression coverage in progress.', '- Current: T02\n- Next: T03\n- Blockers: none');
    assert.match(got.details.planWarning,/Unresolved sentinel/);
    assert.equal(got.details.path,historicalRel);
    await writeFile(join(dir,pointerRel),consistentBody);

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
    // A genuine shaped pointer belonging to another session remains blocked independently of filename recovery.
    await assert.rejects(getPlanTool.execute('b',{},undefined,undefined,ctxWithPointers([[pointerRel,{sessionId:'other-session-9999'}]])),/different session/);
    await assert.rejects(getPlanTool.execute('b',{},undefined,undefined,ctxWithPointers([[pointerRel,{worktree:undefined}]])),/latest active-plan pointer is malformed/);
    assert.equal(existsSync(join(dir,pointerRel)),true,'a malformed pointer does not recreate or delete the selected Markdown file');
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
    assert.match(sum.content[0].text,/Active task: active regression slice/);
    assert.equal(sum.details.planSource,'active-pointer');
    assert.deepEqual(sum.details.planTasks,{total:3,open:2,done:1});

    // TUI mode refreshes the existing status surface; other modes do not.
    const uiCalls = [];
    const ui = {setStatus:(key,value)=>uiCalls.push(['status',key,value]), setWidget:(key,lines)=>uiCalls.push(['widget',key,lines])};
    await getPlanTool.execute('u',{},undefined,undefined,{...ptrCtx,mode:'tui',ui});
    const lastStatus = uiCalls.filter(c=>c[0]==='status').pop();
    assert.match(String(lastStatus?.[2]),/Plan in-progress · 2 open\/1 done/);
    assert.equal(uiCalls.filter(c=>c[0]==='widget').length,0,'plan must not render an above-editor widget');
    const offCalls = [];
    const offUi = {setStatus:()=>offCalls.push(1), setWidget:()=>offCalls.push(1)};
    await getPlanTool.execute('u',{},undefined,undefined,{...ptrCtx,mode:'json',ui:offUi});
    assert.equal(offCalls.length,0,'non-TUI mode must not touch the status/widget UI');

    // Lifecycle events may refresh the existing status line, but they do not publish plan state.
    const endCtx = {cwd:dir,sessionManager:ptrCtx.sessionManager,mode:'tui',ui};
    const branchBeforeRefresh = structuredClone(ptrCtx.sessionManager.getBranch());
    for (const eventName of ['before_agent_start','session_start','session_tree','session_compact','tool_execution_end','agent_end','agent_settled']) {
      for (const handler of memory.handlers.get(eventName) ?? []) await handler({},endCtx);
    }
    assert.deepEqual(ptrCtx.sessionManager.getBranch(),branchBeforeRefresh,
      'status refresh events do not append conversation or selection entries');
    assert.ok(uiCalls.filter(c=>c[0]==='status').length>0,'the existing status line is refreshed');
    assert.equal(uiCalls.filter(c=>c[0]==='widget').length,0,'plan must not render an above-editor widget');

    // session_before_switch clears stale status text in TUI mode only.
    uiCalls.length = 0;
    await memory.handlers.get('session_before_switch')[0]({}, {...ptrCtx,mode:'tui',ui});
    assert.equal(uiCalls.filter(c=>c[0]==='status').pop()?.[2],undefined);
    assert.equal(uiCalls.filter(c=>c[0]==='widget').length,0,'clearing must not touch a widget surface');
    const offClearCalls = [];
    const offClearUi = {setStatus:()=>offClearCalls.push(1), setWidget:()=>offClearCalls.push(1)};
    await memory.handlers.get('session_before_switch')[0]({}, {...ptrCtx,mode:'json',ui:offClearUi});
    assert.equal(offClearCalls.length,0);

    await planTool.execute('x',{slug:'test-plan'},undefined,undefined,ctx);
    await writeFile(join(dir,'.ai/TASKS.md'),'# Tasks\n## Inbox\n- [ ] inbox sentinel\n## In Progress\n- [ ] active sentinel\n## Done\n'+('- [x] done sentinel\n'.repeat(1000)));
    const entriesBeforeStart = structuredClone(ptrCtx.sessionManager.getBranch());
    await memory.handlers.get('before_agent_start')[0]({systemPrompt:'base'},ctx);
    assert.deepEqual(ptrCtx.sessionManager.getBranch(),entriesBeforeStart,
      'starting the agent does not publish TASKS.md or plan status');

  } finally {
    process.env.PATH=oldPath;
    if(oldFixture===undefined)delete process.env.PI_TEST_FIXTURE;else process.env.PI_TEST_FIXTURE=oldFixture;
    await rm(dir,{recursive:true,force:true});
  }
});


// --- Shared fixtures ---------------------------------------------------------
// memory is loaded through Pi's real loader and driven through the installed
// ExtensionRunner, against a real SessionManager and the real convertToLlm. No
// provider request, no credentials, no private sessions.
const JOURNEY_USAGE = {input:10,output:5,cacheRead:0,cacheWrite:0,totalTokens:15,cost:{input:0,output:0,cacheRead:0,cacheWrite:0,total:0}};

function bindRunner(runner, sm) {
  const noop = () => {};
  runner.bindCore(
    {appendEntry:(type,data)=>sm.appendCustomEntry(type,data)},
    {getModel:()=>undefined, isIdle:()=>true, isProjectTrusted:()=>true,
     getSignal:()=>undefined, abort:noop, hasPendingMessages:()=>false,
     getSystemPrompt:()=>'base', executeTool:noop, getCallableTools:()=>[], compact:noop},
  );
  return runner;
}

const sdkIndex = () => import(pathToFileURL(join(sdkRoot,'dist/index.js')));
const sdkLoader = () => import(pathToFileURL(join(sdkRoot,'dist/core/extensions/loader.js')));
const createAssistantMessageEventStream = sdkRoot
  ? (await import(pathToFileURL(join(sdkRoot,'../pi-ai/dist/utils/event-stream.js')))).createAssistantMessageEventStream
  : () => assert.fail('pi-ai is unavailable without PI_SDK_ROOT');

/**
 * Keeps the runner, the boundary context and the request history on one live
 * SessionManager. Reassigning the manager without rebuilding the runner would
 * leave the runner resolving plan state against a session the session file no
 * longer represents, so `reopen` rebuilds both together.
 */
function liveRunner({extensions, runtime, dir, sm}, ExtensionRunner, SessionManager) {
  let manager = sm;
  let runner = bindRunner(new ExtensionRunner(extensions, runtime, dir, manager, {find:()=>undefined}), manager);
  return {
    get sm(){return manager;},
    get runner(){return runner;},
    // The manager the runner hands to extension handlers must be the live one.
    get aligned(){return runner.createContext().sessionManager === manager;},
    reopen(){manager = SessionManager.open(manager.getSessionFile(), join(dir,'sessions'));
             runner = bindRunner(new ExtensionRunner(extensions, runtime, dir, manager, {find:()=>undefined}), manager);
             return this;},
  };
}

// Mirrors what AgentSession supplies to emitBoundary, built from public SDK calls.
async function boundaryContext(sm) {
  const {convertToLlm} = await sdkIndex();
  const projection = sm.buildSessionProjection();
  const llmMessages = convertToLlm(projection.messages);
  const finalRole = llmMessages[llmMessages.length - 1]?.role;
  return {contextEntries:projection.entries, contextMessages:projection.messages, llmMessages,
    pendingMessages:[], canContinue: llmMessages.some(m=>m.role!=='system') && finalRole!=='assistant'};
}

function applyDrafts(sm, drafts) {
  const ids = [];
  for (const draft of drafts) {
    if (draft.type === 'custom') ids.push(sm.appendCustomEntry(draft.customType, draft.data));
    else if (draft.type === 'custom_message') ids.push(sm.appendCustomMessageEntry(draft.customType, draft.content, draft.display, draft.details));
    else assert.fail(`unexpected draft type: ${draft.type}`);
  }
  return ids;
}

async function journeyTurn({runner, sm, text, index=0}) {
  sm.appendMessage({role:'user',content:[{type:'text',text}],timestamp:100+index});
  const {convertToLlm} = await sdkIndex();
  const requestMessages = await runner.emitContext(sm.buildSessionProjection().messages);
  const llm = convertToLlm(requestMessages);
  const assistant = {role:'assistant',content:[{type:'text',text:'ack'}],
    api:'fixture',provider:'fixture',model:'fixture',stopReason:'stop',timestamp:200+index,usage:JOURNEY_USAGE};
  const messageEntryId = sm.appendMessage(assistant);
  const boundary = await runner.emitBoundary(
    {type:'turn_end',turnIndex:index,message:assistant,toolResults:[],messageEntryId,toolResultEntryIds:[]},
    ()=>boundaryContext(sm));
  applyDrafts(sm, boundary.entries);
  return {requestMessages, llm, drafts:boundary.entries};
}

const instructionsOf = llm => llm.filter(m=>m.role==='system').map(m=>JSON.stringify(m)).join('\n');

// A stand-in for another extension that proposes a boundary entry; memory must leave it untouched.
const SENTINEL_EXT = `import type {ExtensionAPI} from "@earendil-works/pi-coding-agent";
export default function (pi: ExtensionAPI) {
  pi.on("turn_end", async (event) => ({entries:[{type:"custom",customType:"test.sentinel",data:"sentinel"}]}));
}`;

async function loadMemory(dir, extra = []) {
  const {createExtensionRuntime} = await sdkIndex();
  const runtime = createExtensionRuntime();
  const {loadExtensions} = await sdkLoader();
  const loaded = await loadExtensions([...extra, join(here,'../memory.ts')], dir, undefined, runtime);
  assert.deepEqual(loaded.errors, []);
  return {runtime, extensions: loaded.extensions, memory: loaded.extensions.at(-1)};
}

test('memory: explicit reads follow Markdown edits, branch selection and compaction', {skip: !sdkRoot}, async () => {
  const {SessionManager, ExtensionRunner} = await sdkIndex();
  const dir = await mkdtemp(join(tmpdir(),'pi-memory-explicit-read-'));
  try {
    const initialManager = SessionManager.create(dir, join(dir,'sessions'));
    initialManager.appendMessage({role:'assistant',content:[],api:'fixture',provider:'fixture',model:'fixture',stopReason:'stop',timestamp:0,usage:JOURNEY_USAGE});
    const {runtime, extensions, memory} = await loadMemory(dir);
    const live = liveRunner({extensions, runtime, dir, sm:initialManager}, ExtensionRunner, SessionManager);
    let sm = live.sm;
    const call = (name, params={}, manager=sm) => {
      const registered = memory.tools.get(name);
      return (registered.definition??registered).execute('fixture',params,undefined,undefined,
        {cwd:dir, sessionManager:manager, hasUI:true, ui:{confirm:async()=>true}});
    };

    const created = await call('create_session_plan',{slug:'journey'});
    const planRel = created.details.path;
    const planAbs = join(dir,planRel);
    const initialBody = await readFile(planAbs,'utf8');
    const editedBody = initialBody
      .replace('- [ ] T1: ...','- [x] T1: Read the canonical Markdown plan')
      .replace('## TL;DR\n','## TL;DR\nExplicit Markdown status.\n');
    assert.notEqual(editedBody,initialBody,'the fixture edits the document itself');
    await writeFile(planAbs,editedBody);

    const firstRead = await call('get_current_plan');
    assert.equal(firstRead.details.path,planRel);
    assert.match(firstRead.content[0].text,/Explicit Markdown status/);
    assert.deepEqual(firstRead.details.planTasks,{total:1,open:0,done:1});

    const priorEntries = structuredClone(sm.getEntries());
    const startResult = await live.runner.emitBeforeAgentStart('go',undefined,{});
    assert.ok(!JSON.stringify(startResult.messages).includes('Explicit Markdown status'),
      'starting an agent does not publish the plan document');
    assert.deepEqual(sm.getEntries(),priorEntries,'the start event does not append a plan message');

    const turn = await journeyTurn({runner:live.runner,sm,text:'continue',index:1});
    assert.deepEqual(turn.drafts,[],'turn_end adds no automatic plan status');
    assert.ok(!JSON.stringify(turn.requestMessages).includes('Explicit Markdown status'));
    const stableInstructions = instructionsOf(turn.llm);

    live.reopen();
    sm = live.sm;
    assert.equal(live.aligned,true);
    assert.notEqual(sm,initialManager);
    assert.equal((await call('get_current_plan')).details.path,planRel,
      'the selection remains available after reopening');

    const secondPlan = '.ai/plan/other-existing-plan.md';
    await writeFile(join(dir,secondPlan),editedBody.replace('# Plan: journey','# Plan: other'));
    const firstPlanLeaf = sm.getLeafId();
    const selected = await call('select_session_plan',{path:secondPlan});
    assert.equal(selected.details.selected,true);
    assert.equal((await call('get_current_plan')).details.path,secondPlan);
    sm.branch(firstPlanLeaf);
    assert.equal((await call('get_current_plan')).details.path,planRel,
      'returning to the earlier branch restores its own selection');

    const kept = sm.appendMessage({role:'user',content:[{type:'text',text:'kept after compaction'}],timestamp:400});
    sm.appendCompaction('fixture summary',kept,100);
    assert.ok(sm.getBranch().some(entry=>entry.customType==='memory.active-plan'));
    assert.ok(!sm.buildContextEntries().some(entry=>entry.customType==='memory.active-plan'),
      'the pointer survives in branch metadata even when old context entries are compacted');
    const afterCompaction = await call('get_current_plan');
    assert.equal(afterCompaction.details.path,planRel);
    assert.deepEqual(afterCompaction.details.planTasks,{total:1,open:0,done:1});

    live.reopen();
    sm = live.sm;
    assert.equal((await call('get_current_plan')).details.path,planRel,
      'the explicit read still resolves the selected document after compaction and reopening');

    const uiStatus = [];
    const uiContext = {cwd:dir,sessionManager:sm,mode:'tui',
      ui:{setStatus:(key,value)=>uiStatus.push([key,value]),setWidget:()=>assert.fail('no widget surface')}};
    const beforeMessages = structuredClone(sm.buildSessionProjection().messages);
    const beforeEntries = structuredClone(sm.getEntries());
    const hooks = ['before_agent_start','session_start','session_tree','session_compact','tool_execution_end','agent_end','agent_settled'];
    for (const eventName of hooks) {
      for (const handler of memory.handlers.get(eventName) ?? []) {
        await handler({},uiContext);
      }
    }
    assert.deepEqual(sm.buildSessionProjection().messages,beforeMessages,
      'UI refresh events do not change conversation messages');
    assert.deepEqual(sm.getEntries(),beforeEntries,
      'UI refresh events do not append session entries');
    assert.ok(uiStatus.some(([,value])=>String(value).includes('Plan pending')),
      'the existing status line still reflects the Markdown document');
    assert.equal(instructionsOf((await boundaryContext(sm)).llmMessages),stableInstructions,
      'UI refresh does not replace system instructions');

  } finally {
    await rm(dir,{recursive:true,force:true});
  }
});
test('memory: lifecycle hooks leave other turn-end entries untouched and publish no plan state', {skip: !sdkRoot}, async () => {
  const {SessionManager, ExtensionRunner, createExtensionRuntime} = await sdkIndex();
  const dir = await mkdtemp(join(tmpdir(),'pi-memory-sentinel-'));
  try {
    const sm = SessionManager.create(dir, join(dir,'sessions'));
    sm.appendMessage({role:'assistant',content:[],api:'fixture',provider:'fixture',model:'fixture',stopReason:'stop',timestamp:0,usage:JOURNEY_USAGE});
    const sentinelPath = join(dir,'sentinel.ts');
    await writeFile(sentinelPath, SENTINEL_EXT);
    const {runtime, extensions} = await loadMemory(dir, [sentinelPath]);
    const live = liveRunner({extensions, runtime, dir, sm}, ExtensionRunner, SessionManager);
    const call = (name, params={}) => {
      const registered = extensions.at(-1).tools.get(name);
      return (registered.definition??registered).execute('fixture',params,undefined,undefined,{cwd:dir,sessionManager:sm});
    };
    await call('create_session_plan',{slug:'sentinel'});

    const talking = await journeyTurn({runner:live.runner,sm,text:'first',index:1});
    assert.deepEqual(talking.drafts.map(d=>d.customType), ['test.sentinel'],
      'the extension does not alter the entry proposed by another turn_end handler');
    assert.equal(sm.getBranch().filter(e=>e.customType==='test.sentinel').length,1,'the sentinel is stored exactly once');
    assert.equal(sm.getBranch().filter(e=>e.customType==='memory.plan-state').length,0,
      'no lifecycle hook appends an automatic plan status message');

    const quiet = await journeyTurn({runner:live.runner,sm,text:'second',index:2});
    assert.deepEqual(quiet.drafts.map(d=>d.customType), ['test.sentinel'],
      'later turns continue to preserve the other handler entry');
  } finally {
    await rm(dir,{recursive:true,force:true});
  }
});

// --- Real AgentSession cycle -------------------------------------------------
// Drives the installed AgentSession with a fake provider and fake local tools.
// Observed boundary: the transcript handed to the provider layer
// (`Models.streamSimple`, already converted by the agent) plus the real
// `convertToLlm` applied to the session projection. The provider-specific
// converter and the transport payload are NOT exercised here.
const FAKE_USAGE = {input:1,output:1,cacheRead:0,cacheWrite:0,totalTokens:2,cost:{input:0,output:0,cacheRead:0,cacheWrite:0,total:0}};

/** Fake provider queue: each entry is the reply for one request, in order. */
function fakeProviderRuntime(replies, {contextWindow = 200000} = {}) {
  const requests = [];
  const model = {id:'fake-1', name:'Fake', provider:'fake', api:'openai-completions', baseUrl:'',
    reasoning:false, input:['text'], cost:{input:0,output:0,cacheRead:0,cacheWrite:0},
    contextWindow, maxTokens:4096};
  // The agent's streamFn calls `modelRuntime.streamSimple`, so this is where the
  // real request transcript is observed. Recorded before the fake reply is built.
  const stream = (m, ctx) => {
    requests.push(structuredClone(ctx.messages));
    const reply = replies.shift() ?? {text:'(sin respuesta preparada)', tool:null};
    const s = createAssistantMessageEventStream();
    const toolCall = reply.tool
      ? {type:'toolCall', id:`tc${requests.length}`, name:reply.tool.name, arguments:reply.tool.arguments}
      : null;
    const message = {role:'assistant',
      content: toolCall ? [{type:'text',text:reply.text}, toolCall] : [{type:'text',text:reply.text}],
      api:m.api, provider:m.provider, model:m.id, stopReason: toolCall?'toolUse':'stop',
      timestamp:Date.now(), usage:FAKE_USAGE};
    s.push({type:'start', message});
    s.push({type:'text_start', contentIndex:0});
    s.push({type:'text_delta', contentIndex:0, delta:reply.text});
    s.push({type:'text_end', contentIndex:0});
    if (toolCall) { s.push({type:'toolcall_start', contentIndex:1, toolCall}); s.push({type:'toolcall_end', contentIndex:1, toolCall}); }
    s.push({type:'done', reason: toolCall?'toolUse':'stop', message});
    s.resolveFinalResult(message);
    s.end();
    return s;
  };
  const provider = {id:'fake', name:'Fake', baseUrl:'', auth:{type:'none'}, getModels:()=>[model], stream, streamSimple:stream};
  return {model, requests, runtime: {
    getProviders:()=>[provider], getProvider:(id)=>id==='fake'?provider:undefined,
    getModels:(p)=>!p||p==='fake'?[model]:[], getModel:(p,id)=>p==='fake'&&id===model.id?model:undefined,
    getAvailable:()=>[model], getModelOfType:()=>undefined, getModelsOfType:()=>[],
    getAllModels:()=>[], getAllAvailable:()=>[], getAuth:()=>({type:'none'}),
    getAuthStatus:()=>({authenticated:true}), hasConfiguredAuth:()=>true,
    refresh:async()=>({}), listCredentials:()=>[], setApiKey:async()=>{},
    stream, streamSimple:stream,
  }};
}

async function openSession({dir, agentDir, replies, extensions = [], contextWindow, toolResult = 'nota registrada'}) {
  const sdk = await sdkIndex();
  const resourceLoader = new sdk.DefaultResourceLoader({
    cwd:dir, agentDir,
    additionalExtensionPaths:[join(here,'../memory.ts')],
    // Inline factories load beside memory.ts in the same runner, so the probe observes
    // the same live runner and session manager the extension under test uses.
    extensionFactories:extensions,
    appendSystemPrompt:['STATIC POLICY LINE'],
  });
  await resourceLoader.reload();
  const {model, requests, runtime} = fakeProviderRuntime(replies, {contextWindow});
  const tools = [{name:'nota', description:'registra una nota local',
    parameters:{type:'object', properties:{text:{type:'string'}}, required:['text']},
    execute:async ()=>({content:[{type:'text', text:toolResult}]})}];
  const {session} = await sdk.createAgentSession({
    cwd:dir, agentDir, resourceLoader, modelRuntime:runtime, model, thinkingLevel:'off', customTools:tools,
  });
  return {session, requests};
}

const containsText = (messages, needle) => messages.filter(m=>JSON.stringify(m.content).includes(needle)).length;

test('memory: a real AgentSession exposes plan state only through explicit tool results', {skip: !sdkRoot}, async () => {
  const dir = await mkdtemp(join(tmpdir(),'pi-memory-explicit-tool-'));
  const agentDir = await mkdtemp(join(tmpdir(),'pi-memory-agentdir-'));
  const replies = [
    {text:'creo el plan',tool:{name:'create_session_plan',arguments:{slug:'via-ciclo'}}},
    {text:'consulto el documento',tool:{name:'get_current_plan',arguments:{}}},
    {text:'plan consultado',tool:null},
    {text:'retomado',tool:null},
  ];
  try {
    const {session,requests} = await openSession({dir,agentDir,replies});
    await session.prompt('crea y consulta el plan');
    assert.equal(session.isIdle,true,'the turn settled');
    assert.equal(requests.length,3,'create, explicit read, and final response use only their normal tool requests');

    const [first,afterCreate,afterRead] = requests;
    assert.deepEqual(first.map(message=>message.role),['system','user']);
    assert.equal(containsText(first,'**Plan**:'),0,'the plan did not exist in the first request');
    const createResult = afterCreate.findLast(message=>message.role==='toolResult');
    assert.ok(createResult);
    assert.match(JSON.stringify(createResult.content),/Created session plan at:/);
    assert.ok(JSON.stringify(createResult.content).includes('.ai/plan/'));
    assert.equal(containsText(afterCreate,'**Plan**:'),0,
      'creating a plan does not trigger a second automatic state message');

    const readResult = afterRead.findLast(message=>message.role==='toolResult');
    assert.ok(readResult);
    assert.match(JSON.stringify(readResult.content),/Plan source: active-pointer/);
    assert.match(JSON.stringify(readResult.content),/Path: \.ai\/plan\//);
    assert.equal(containsText(afterRead,'**Plan**:'),0,
      'the only plan content is the explicit get_current_plan tool result');
    assert.equal(containsText(afterRead,'Plan source: active-pointer'),1);
    assert.equal(instructionsOf(first),instructionsOf(afterCreate));
    assert.equal(instructionsOf(afterCreate),instructionsOf(afterRead),
      'plan reads do not replace system instructions');

    await session.prompt('retoma');
    assert.equal(requests.length,4,'resuming needs no automatic extra request');
    assert.equal(containsText(requests[3],'**Plan**:'),0);
    assert.equal(containsText(requests[3],'Plan source: active-pointer'),1,
      'the ordinary explicit tool result remains in conversation history');
  } finally {
    await rm(dir,{recursive:true,force:true});
    await rm(agentDir,{recursive:true,force:true});
  }
});
