import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';
import { WEBSITE_DIR, expectedPages } from '../apex-api.mjs';
import {
  GOOD_TO_KNOW_MAX_BULLETS,
  TEST_MAX_LINES
} from '../page-templates.mjs';
import {
  SCAFFOLD_MARKER,
  expectedH1,
  requiredIncludes,
  templateHeadings
} from './check-docs.mjs';

const GOOD_TO_KNOW = `at most ${GOOD_TO_KNOW_MAX_BULLETS} bullets: the facts a developer must not miss here`;

const HAND_WRITTEN = {
  context: {
    lead: 'one or two sentences: when <Ctx> runs and what you do here',
    roles: 'one bullet per role: a link to the role page and one line',
    'good-to-know': GOOD_TO_KNOW
  },
  role: {
    lead: 'one or two sentences: what this role does in <Ctx>',
    example:
      'add at most two <<< imports of existing example classes inside the code-group above, or delete this marker',
    'good-to-know': GOOD_TO_KNOW,
    test: `one test in a code block of ${TEST_MAX_LINES} lines or fewer: API-shaped name, // Setup // Test // Verify, one assertion, zero DML`
  },
  'add-ons': {
    lead: 'one sentence: implement as many add-ons as you need next to your role interface'
  },
  'add-on': {
    lead: 'one or two sentences: what this add-on does in <Ctx>',
    example:
      'add at most two <<< imports of existing example classes inside the code-group above, or delete this marker',
    'good-to-know': GOOD_TO_KNOW
  },
  'record-api': {
    'good-to-know': GOOD_TO_KNOW
  }
};

function placeholder(text) {
  return `${SCAFFOLD_MARKER} ${text.replace(/-->/g, '→')} -->`;
}

function includeLine(requirement) {
  return `<!--@include: ${requirement.include}-->`;
}

function sectionBody(page, sectionId, required) {
  const blocks = [];
  for (const requirement of required.filter(
    item => item.section === sectionId
  )) {
    if (requirement.firstInCodeGroup) {
      blocks.push('::: code-group', includeLine(requirement), ':::');
    } else {
      blocks.push(includeLine(requirement));
    }
  }
  const hand = HAND_WRITTEN[page.template]?.[sectionId];
  if (hand) {
    blocks.push(placeholder(hand.replace(/<Ctx>/g, page.context)));
  }
  return blocks;
}

export function stubFor(page) {
  const headings = templateHeadings(
    page.template,
    page.context,
    page.interface
  );
  const required = requiredIncludes(
    page.template,
    page.context,
    page.interface
  );
  const blocks = [
    [
      '---',
      `template: ${page.template}`,
      `context: ${page.context}`,
      ...(page.interface ? [`interface: ${page.interface}`] : []),
      "description: ''",
      '---'
    ].join('\n'),
    `# ${expectedH1(page.template, page.context, page.interface)[0]}`,
    ...sectionBody(page, 'lead', required)
  ];

  for (const h2 of headings.h2) {
    blocks.push(`## ${h2.text} {#${h2.id}}`);
    blocks.push(...sectionBody(page, h2.id, required));
    for (const h3 of headings.h3.filter(entry => entry.under === h2.id)) {
      blocks.push(`### ${h3.text} {#${h3.id}}`);
      blocks.push(...sectionBody(page, h3.id, required));
    }
  }

  return `${blocks.join('\n\n')}\n`;
}

function toPosix(path) {
  return path.split(sep).join('/');
}

export function scaffold({
  websiteDir = WEBSITE_DIR,
  only = [],
  dryRun = false
} = {}) {
  const root = resolve(websiteDir);
  const result = { created: [], existing: [], manual: [] };

  for (const page of expectedPages()) {
    const target = join(root, ...page.path.split('/'));
    const shown = toPosix(relative(process.cwd(), target));
    if (
      only.length > 0 &&
      !only.some(
        prefix =>
          page.path.startsWith(prefix) ||
          `website/${page.path}`.startsWith(prefix)
      )
    ) {
      continue;
    }
    if (!page.template) {
      if (!existsSync(target)) result.manual.push(shown);
      continue;
    }
    if (existsSync(target)) {
      result.existing.push(shown);
      continue;
    }
    if (!dryRun) {
      mkdirSync(dirname(target), { recursive: true });
      writeFileSync(target, stubFor(page), { flag: 'wx' });
    }
    result.created.push(shown);
  }

  return result;
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  const options = { only: [], dryRun: false };
  const argv = process.argv.slice(2);
  for (let index = 0; index < argv.length; index++) {
    if (argv[index] === '--dry-run') options.dryRun = true;
    else if (argv[index] === '--only') options.only.push(argv[++index]);
    else if (argv[index] === '--website') options.websiteDir = argv[++index];
    else {
      console.log(
        'Usage: node website/.vitepress/scripts/scaffold.mjs [--dry-run] [--only <path-prefix>]... [--website <dir>]\nCreates missing context pages from the page templates; never overwrites a file.'
      );
      process.exit(argv[index] === '--help' ? 0 : 1);
    }
  }
  const result = scaffold(options);
  for (const path of result.created)
    console.log(`${options.dryRun ? 'would create' : 'created'} ${path}`);
  for (const path of result.manual)
    console.log(`write by hand (no template): ${path}`);
  console.log(
    `scaffold: ${result.created.length} ${options.dryRun ? 'to create' : 'created'}, ${result.existing.length} already present (left untouched), ${result.manual.length} to write by hand`
  );
}
