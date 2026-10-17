// Local configuration check; never launches a child or calls a provider.
import assert from 'node:assert/strict';
import {test} from 'node:test';
import {mkdtemp, readFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';

const sdkRoot = process.env.PI_SDK_ROOT;
const here = fileURLToPath(new URL('../.pi/agent/extensions/pi-subagents/', import.meta.url));

// Configuration/discovery only: no tool.execute(), subprocess, provider or model call.
test('code-reviewer: real frontmatter, native read-only tools and discovery without launch', {skip: !sdkRoot}, async () => {
  const {DefaultResourceLoader, SettingsManager, parseFrontmatter,
    createReadTool, createGrepTool, createFindTool, createLsTool} =
    await import(pathToFileURL(join(sdkRoot, 'dist/index.js')));
  const dir = await mkdtemp(join(tmpdir(), 'pi-code-reviewer-config-'));
  try {
    const source = await readFile(join(here, 'agents/code-reviewer.md'), 'utf8');
    const {frontmatter, body} = parseFrontmatter(source);
    assert.equal(frontmatter.name, 'code-reviewer');
    assert.ok(frontmatter.description);
    assert.equal(frontmatter.model, 'openai-codex/gpt-6.1-sol');
    assert.equal(frontmatter.thinking, 'medium');
    const tools = frontmatter.tools.split(',').map(t => t.trim());
    assert.deepEqual(tools, ['read', 'grep', 'find', 'ls']);
    assert.deepEqual([createReadTool, createGrepTool, createFindTool, createLsTool]
      .map(create => create(dir).name), tools, 'all declared tools exist in the installed SDK');
    assert.ok(body.trim());
    const loader = new DefaultResourceLoader({cwd:dir, agentDir:join(dir, 'agent'),
      settingsManager:SettingsManager.inMemory({packages:[]}), noExtensions:true,
      noSkills:true, noPromptTemplates:true, noThemes:true,
      additionalExtensionPaths:[join(here, 'index.ts')]});
    await loader.reload();
    assert.deepEqual(loader.getExtensions().errors, []);
    const extension = loader.getExtensions().extensions.find(e => e.tools.has('subagent'));
    assert.ok(extension);
    const registration = extension.tools.get('subagent');
    const tool = registration.definition ?? registration;
    assert.ok(tool.description.includes(`code-reviewer (${frontmatter.description})`),
      'existing agents/*.md discovery exposes the new definition');
    assert.ok(tool.description.includes('plan-reviewer (Manual-only'),
      'saved-plan reviewer retains its manual-only discovery description');
  } finally {
    await rm(dir, {recursive:true, force:true});
  }
});
