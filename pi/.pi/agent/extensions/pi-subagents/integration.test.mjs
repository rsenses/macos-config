// Runs real Pi extension loading and subprocess protocol with a fake provider-free pi binary.
// PI_SDK_ROOT=/path/to/pi-coding-agent node --test integration.test.mjs
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdir, mkdtemp, writeFile, rm, readFile } from 'node:fs/promises';
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
    const model = {provider:'openai-codex',id:'gpt-5.6-luna',reasoning:true,contextWindow:272000,thinkingLevelMap:{low:'low',medium:'medium',high:'high',max:'max'}};
    const ctx = {cwd:dir,modelRegistry:{find:(p,id)=>p===model.provider&&id===model.id?model:undefined}};
    const usage = {input:10,output:2,cacheRead:5,cacheWrite:0,totalTokens:17,cost:{input:.01,output:.02,cacheRead:0,cacheWrite:0,total:.03}};
    const event = (reason,text,extra={})=>({type:'message_end',message:{role:'assistant',provider:model.provider,model:model.id,stopReason:reason,content:[{type:'text',text}],usage,...extra}});
    await writeFile(process.env.PI_TEST_FIXTURE,JSON.stringify(event('stop','**Status**: complete\nVerified.'))+'\n');
    const success = await tool.execute('s',{agent:'scout',task:'Locate fixture',thinking:'low'},undefined,undefined,ctx);
    assert.equal(success.details.status,'complete');
    assert.equal(success.usage.input,10);
    assert.equal(success.usage.cost.total,.03);
    assert.equal(success.details.results[0].thinking,'low');
    const argv = JSON.parse(await readFile(process.env.PI_TEST_FIXTURE+'.args','utf8'));
    assert.equal(argv[argv.indexOf('--model')+1],'openai-codex/gpt-5.6-luna');
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
    const planRegistration=memory.tools.get('create_session_plan');const planTool=planRegistration.definition??planRegistration;
    await assert.rejects(planTool.execute('x',{slug:'../../escape'},undefined,undefined,ctx),/slug/);
    await planTool.execute('x',{slug:'test-plan'},undefined,undefined,ctx);
    await writeFile(join(dir,'.ai/TASKS.md'),'# Tasks\n## Inbox\n- [ ] inbox sentinel\n## In Progress\n- [ ] active sentinel\n## Done\n'+('- [x] done sentinel\n'.repeat(1000)));
    const injection=await memory.handlers.get('before_agent_start')[0]({systemPrompt:'base'},ctx);
    assert.match(injection.systemPrompt,/active sentinel/);
    assert.doesNotMatch(injection.systemPrompt,/done sentinel|inbox sentinel/);
    assert.ok(injection.systemPrompt.length<4000);
  } finally {
    process.env.PATH=oldPath;
    if(oldFixture===undefined)delete process.env.PI_TEST_FIXTURE;else process.env.PI_TEST_FIXTURE=oldFixture;
    await rm(dir,{recursive:true,force:true});
  }
});
