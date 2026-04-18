#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const TEMPLATES_DIR = path.join(__dirname, "templates");

function printHelp() {
  console.log(`
harnessprompt - install slash command templates

Usage:
  harnessprompt templates
  harnessprompt install [projectPath]
  harnessprompt show <template>
  harnessprompt new-template <name>
`);
}

function getTemplates() {
  if (!fs.existsSync(TEMPLATES_DIR)) return [];
  return fs
    .readdirSync(TEMPLATES_DIR)
    .filter((file) => file.endsWith(".md"))
    .map((file) => file.replace(".md", ""));
}

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function installTemplates(projectPath = ".") {
  const templates = getTemplates();
  if (templates.length === 0) {
    console.error("No templates found in templates/.");
    process.exit(1);
  }

  const resolvedPath = path.resolve(projectPath);
  const commandsDir = path.join(resolvedPath, ".claude", "commands");
  ensureDir(commandsDir);

  for (const name of templates) {
    const src = path.join(TEMPLATES_DIR, `${name}.md`);
    const dest = path.join(commandsDir, `${name}.md`);
    fs.copyFileSync(src, dest);
  }

  console.log(`Installed ${templates.length} commands to ${commandsDir}`);
  console.log("Available slash commands:");
  for (const name of templates) {
    console.log(`  /${name}`);
  }
}

function showTemplate(name) {
  if (!name) {
    console.error("Missing template name.");
    process.exit(1);
  }
  const file = path.join(TEMPLATES_DIR, `${name}.md`);
  if (!fs.existsSync(file)) {
    console.error(`Template not found: ${name}`);
    process.exit(1);
  }
  process.stdout.write(fs.readFileSync(file, "utf8"));
}

function listTemplates() {
  const templates = getTemplates();
  if (templates.length === 0) {
    console.log("No templates found.");
    return;
  }
  console.log(`Templates (${templates.length}):`);
  for (const t of templates) {
    console.log(`- ${t}`);
  }
}

function newTemplate(name) {
  if (!name) {
    console.error("Missing template name.");
    process.exit(1);
  }
  if (/[/\\:*?"<>|]/.test(name) || name.includes("..") || name.startsWith(".")) {
    console.error(`Invalid template name: ${name}`);
    process.exit(1);
  }
  const file = path.join(TEMPLATES_DIR, `${name}.md`);
  if (fs.existsSync(file)) {
    console.error(`Template already exists: ${name}`);
    process.exit(1);
  }
  ensureDir(TEMPLATES_DIR);
  const title = name.replace(/-/g, " ").replace(/\b\w/g, (m) => m.toUpperCase());
  const content = `---
description: "Describe when to use /${name}."
---

# ${title}

**When to use:** Fill this in.

**Role:** Fill this in.

---

**Task:** $ARGUMENTS

## Don't

- Don't skip context collection.
- Don't return vague conclusions.

## Steps

1. Collect required context.
2. Execute deterministic checks.
3. Report findings and next action.

## Output Format

\`\`\`
## Summary
[key result]

## Findings
- [finding]

## Next Step
[actionable next step]
\`\`\`

## Success Criteria

- Clear, verifiable output.
- Risks and unknowns explicitly called out.
`;
  fs.writeFileSync(file, content, "utf8");
  console.log(`Created template: templates/${name}.md`);
}

const [, , command, arg] = process.argv;

switch (command) {
  case "templates":
    listTemplates();
    break;
  case "install":
    installTemplates(arg || ".");
    break;
  case "show":
    showTemplate(arg);
    break;
  case "new-template":
    newTemplate(arg);
    break;
  case "-h":
  case "--help":
  case undefined:
    printHelp();
    break;
  default:
    console.error(`Unknown command: ${command}`);
    printHelp();
    process.exit(1);
}
