import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';
import { WEBSITE_DIR, expectedPages, getContext } from '../apex-api.mjs';
import {
  SCAFFOLD_MARKER,
  expectedH1,
  requiredIncludes,
  templateHeadings
} from './check-docs.mjs';

const HAND_WRITTEN = {
  context: {
    'pick-a-role':
      'an "I want to… → role" table (with rows that point to other contexts), then the roles/one-role.md region for this phase, then one line naming the <Ctx>.Handler marker',
    records: 'three hand-written facts, and a link to ./record-api',
    register:
      'a <<< import of an existing trigger, the notes/name-collisions.md partial, and a "::: details Full orchestrator" block with a <<< import',
    'how-it-runs':
      'the run-order partial for this phase, then page lines for the parent query path, units, recursion and method names',
    'switching-off':
      'the add-ons/switch-off.md partial and a link to this context’s Bypassable page',
    gotchas: 'context-specific gotchas (platform and library)',
    'not-available':
      'hand-written rows for missing capabilities (put, change detection, DML)',
    'see-also': 'the paired context, /contexts and the guides',
    'no-before-undelete':
      'there is no before undelete trigger event; veto a restore from an AfterUndelete Writer or Dispatcher'
  },
  role: {
    'when-to-use': '2 to 4 bullets, plus "use X instead when…"',
    example:
      'add <<< imports of existing example classes inside the code-group above, minimal case first, or delete this marker',
    'how-it-runs': 'the role partials',
    records: 'hand-written warnings for this context',
    gotchas: 'context-specific items first, then shared partials',
    test: 'an inline test snippet (15 lines or fewer, zero DML) and a link to /guide/testing',
    'see-also': 'related pages',
    'unit-of-work-methods': 'the uow/methods.md partial',
    'which-unit': 'the uow/which-unit.md partial',
    'when-it-commits': 'the uow/commit-timing.md partial',
    'platform-events': 'the uow/platform-events.md partial'
  },
  'add-ons': {
    'see-also': 'related pages'
  },
  'add-on': {
    'when-to-use': '2 to 4 bullets, plus "use X instead when…"',
    example:
      'add <<< imports of existing example classes inside the code-group above, or delete this marker',
    'how-it-runs': 'the region partials for this add-on and context',
    records:
      'what the method receives here: no parameter, all records, or only the qualified records',
    gotchas: 'context-specific gotchas',
    test: 'one prose line at most naming this page’s example',
    'see-also': 'guide and reference anchors',
    'choosing-fields': 'the add-ons/field-selection.md partial',
    'parent-vs-prior': 'the add-ons/parent-vs-prior.md partial',
    'key-patterns':
      'a "::: details" block with the add-ons/related-query-patterns.md partial',
    configuring: 'the add-ons/configuring-unit.md partial',
    'other-ways': 'the other ways to switch handlers off',
    'data-migration': 'the add-ons/data-migration.md partial',
    'edge-values': 'the add-ons/recursion-edge-values.md partial',
    'still-throws':
      'the notes/never-logged.md partial, then the list of what still throws in this context',
    logging: 'how the Logger receives the swallowed exception'
  },
  'record-api': {
    receive: 'the record and collection types this context hands out',
    'change-detection':
      'one line: this context has no change detection (or the change-detection partial in update contexts)',
    parents: 'getNewParent, getOldParent and getRelated in this context',
    'see-also': 'related pages'
  }
};

const FIXED_LINES = {
  'record-api': {
    collections:
      'Every collection method, and why `getRecords()` returns the internal list rather than a copy: [Record Collections](/api/record-collections).',
    gotchas:
      'Rules that hold in every context: [Comparisons](#comparisons) and [Record Type](#record-type).'
  }
};

function placeholder(text) {
  return `${SCAFFOLD_MARKER} ${text.replace(/-->/g, '→')} -->`;
}

function includeLine(requirement) {
  if (requirement.snippet) return `<<< ${requirement.snippet}`;
  return `<!--@include: ${requirement.include}${requirement.region ? `#${requirement.region}` : ''}-->`;
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
  const fixed = FIXED_LINES[page.template]?.[sectionId];
  if (fixed) blocks.push(fixed);
  const hand = HAND_WRITTEN[page.template]?.[sectionId];
  if (hand) {
    blocks.push(placeholder(hand.replace(/<Ctx>/g, page.context)));
  }
  return blocks;
}

export function stubFor(page) {
  const context = getContext(page.context);
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
    placeholder(
      `lead sentence: spell out ${context.triggerEvent} in words, with task synonyms (bypass, skip, lookup, parent fields, callout)`
    ),
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
