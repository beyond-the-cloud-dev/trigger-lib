import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import {
  dirname,
  isAbsolute,
  join,
  posix,
  relative,
  resolve,
  sep
} from 'node:path';
import { pathToFileURL } from 'node:url';
import {
  WEBSITE_DIR,
  expectedPages,
  getContext,
  getInterface,
  model,
  nav as defaultNav,
  parseAdapterHonours,
  sidebar as defaultSidebar
} from '../apex-api.mjs';
import { honourTable as defaultHonourTable } from '../context-facts.mjs';
import { headingText, templates } from '../page-templates.mjs';

export const RULES = {
  1: 'pages and interfaces',
  2: 'template lint',
  3: 'includes',
  4: 'partials',
  5: 'method tokens',
  6: 'stale API',
  7: 'links and anchors',
  8: 'sidebar, nav and redirects',
  9: 'router pages',
  10: 'honour table'
};

export const ALLOW_MARKER = '<!-- check-docs: allow -->';
export const SCAFFOLD_MARKER = '<!-- scaffold:';

const ALLOW_PATTERN = /^<!--\s*check-docs:\s*allow\s*-->$/;
const SCAFFOLD_PATTERN = /<!--\s*scaffold:/;
const METHOD_TOKEN_PATTERN =
  /\b(?:[a-z]\w*(?:Before|After)|before|after)(?:Insert|Update|Delete|Undelete)\w*\b/g;
const INCLUDE_PATTERN = /<!--\s*@include:\s*(.*?)\s*-->/g;
const SNIPPET_LINE_PATTERN = /^\s*<<<(.*)$/;
const SNIPPET_PATH_PATTERN =
  /^(.+?(?:(?:\.([a-z0-9]+))?))(?:(#[\w-]+))?(?: ?(?:{(\d+(?:[,-]\d+)*)? ?(\S+)? ?(\S+)?}))? ?(?:\[(.+)\])?$/;
const REGION_MARKER_STRICT = /^<!-- #?((?:end)?region) ([\w*-]+) -->$/;
const REGION_MARKER_LOOSE = /^<!--\s*#?(?:end)?region\b.*-->$/i;
const FENCE_OPEN_PATTERN = /^ {0,3}(`{3,}|~{3,})(.*)$/;
const FENCE_CLOSE_PATTERN = /^ {0,3}(`{3,}|~{3,})[ \t]*$/;
const ATX_PATTERN = /^ {0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t]*$/;
const SETEXT_PATTERN = /^ {0,3}(=+|-+)[ \t]*$/;
const EXPLICIT_ID_PATTERN = /[ \t]*\{#([^\s{}]+)\}[ \t]*$/;
const EXTERNAL_PATTERN = /^(?:[a-z][a-z0-9+.-]*:|\/\/)/i;
const SKIPPED_DIRECTORIES = new Set([
  '.vitepress',
  '_parts',
  'node_modules',
  'public',
  'dist'
]);

const STALE_API_PARTIAL = 'notes/stale-api.md';
const TESTING_PAGE = 'guide/testing.md';
const HOW_DO_I_PAGE = 'how-do-i.md';
const CONTEXTS_PAGE = 'contexts.md';
const ROUTER_PAGES = [HOW_DO_I_PAGE, CONTEXTS_PAGE];
const MAX_ANSWER_WORDS = 12;

export const STALE_FENCE_PATTERNS = [
  {
    pattern:
      /\bimplements\b[^{;]*?\b(?:BeforeInsert|BeforeUpdate|AfterInsert|AfterUpdate|AfterDelete|AfterUndelete)\.Handler\b/g,
    message:
      'implements a context Handler marker: only BeforeDelete.Handler is a role; the class compiles and never runs. Implement a role (Populator, Validator, Writer, Dispatcher) instead'
  },
  {
    pattern: /qualifiesForAfter/g,
    message:
      'qualifiesForAfter… belongs to no interface; after contexts use writeOnAfter<Op>When or dispatchOnAfter<Op>When'
  },
  {
    pattern: /\bonAfter(?:Insert|Update|Delete|Undelete)\(/g,
    message:
      'onAfter…() belongs to no interface; after contexts use writeOnAfter<Op> or dispatchOnAfter<Op>'
  },
  {
    pattern: /TriggerOrchestrator\.RecursionGuard/g,
    message:
      'TriggerOrchestrator.RecursionGuard does not exist; use BeforeUpdate.RecursionGuard or AfterUpdate.RecursionGuard'
  },
  {
    pattern: /getNewRelated/g,
    message: 'getNewRelated does not exist; use getNewParent'
  },
  {
    pattern: /\bfinalize(?:Before|After)\w+\(\s*\)/g,
    message:
      'a Finalizer method takes the qualified records: finalize<Ctx>(TriggerHandler.<X>Records records)'
  },
  {
    pattern: /ValidationMessage/g,
    message:
      'the Validator message method was removed; implement void addErrorOn<Ctx>(TriggerHandler.Rejectable<X>Record record)'
  },
  {
    pattern: /\bIdGenerator\.get/g,
    testingOnly: true,
    message:
      'TriggerHandler.IdGenerator is a @TestVisible seam, documented on /guide/testing only; use new TriggerHandler.RandomIdGenerator().get(…)'
  },
  {
    pattern: /\bnew\s+TriggerOrchestrator\s*\(/g,
    testingOnly: true,
    message:
      'the TriggerOrchestrator(Object) constructor is a @TestVisible seam, documented on /guide/testing only; triggers call TriggerOrchestrator.run(…)'
  },
  {
    pattern: /\btriggerLogger\b/g,
    testingOnly: true,
    message:
      'triggerLogger is a @TestVisible seam, documented on /guide/testing only'
  }
];

const GUARD_SENTENCE_PATTERN = /\bguard\b/i;
const FINALLY_PATTERN = /\b(?:runs|is|executes)\s+in\s+a\s+`?finally\b/i;
const RECORD_IDS_NULL_PATTERN = /getRecordIds\(\)`?\s+(?:is|returns)\s+null\b/g;

function contextsWhere(predicate) {
  return model.contexts.filter(predicate).map(context => context.name);
}

const BEFORE_INSERT_UPDATE = contextsWhere(
  context =>
    context.phase === 'Before' &&
    (context.operation === 'Insert' || context.operation === 'Update')
);
const AFTER_CONTEXTS = contextsWhere(context => context.phase === 'After');
const AFTER_WITH_NEW_ROW = contextsWhere(
  context => context.phase === 'After' && context.operation !== 'Delete'
);

function onePerContext() {
  return Object.fromEntries(
    model.contexts.map(context => [context.slug, [context.name]])
  );
}

export const REGION_MAP = {
  'roles/one-role.md': {
    before: BEFORE_INSERT_UPDATE,
    after: AFTER_CONTEXTS
  },
  'add-ons/parent-query.md': {
    core: null,
    before: BEFORE_INSERT_UPDATE,
    after: AFTER_WITH_NEW_ROW,
    gotchas: null
  },
  'add-ons/related-query.md': {
    core: null,
    'ids-before-insert': ['BeforeInsert'],
    'ids-before-update': ['BeforeUpdate'],
    'ids-after': AFTER_WITH_NEW_ROW,
    'ids-before-delete': ['BeforeDelete'],
    'ids-after-delete': ['AfterDelete'],
    gotchas: null
  },
  'add-ons/finalizer.md': {
    before: BEFORE_INSERT_UPDATE,
    'before-delete': ['BeforeDelete'],
    after: AFTER_CONTEXTS
  },
  'add-ons/continue-on-error.md': {
    common: null,
    writer: AFTER_CONTEXTS
  },
  'add-ons/test-techniques.md': {
    parent: null,
    related: null,
    bypass: null,
    uow: null,
    finalizer: null
  },
  'records/predicates.md': onePerContext(),
  'records/gotchas.md': onePerContext()
};

export const TEST_TECHNIQUE_REGIONS = {
  ParentQuery: 'parent',
  PriorParentQuery: 'parent',
  RelatedQuery: 'related',
  Bypassable: 'bypass',
  OwnUnitOfWork: 'uow',
  Finalizer: 'finalizer'
};

export const HOW_DO_I_MAP = [
  {
    group: 'Wire & register',
    question: 'What do I deploy (dependencies, SOQL Lib, DML Lib)?',
    targets: ['/installation']
  },
  {
    group: 'Wire & register',
    question: 'What goes in the trigger body?',
    targets: ['/guide/orchestrator#trigger']
  },
  {
    group: 'Wire & register',
    question:
      'Register handlers for a context (orchestrator, handler list, order)',
    targets: ['chips:overview#register']
  },
  {
    group: 'Wire & register',
    question: 'A context my orchestrator does not implement, or an empty list',
    targets: ['/guide/orchestrator#unimplemented']
  },
  {
    group: 'Wire & register',
    question: 'Call `run()` outside a trigger (anonymous Apex, service class)',
    targets: ['/guide/orchestrator#outside-a-trigger']
  },
  {
    group: 'Wire & register',
    question:
      'One class in several contexts (insert and update, insert and undelete)',
    targets: [
      '/guide/orchestrator#one-class-several-contexts',
      '/after-undelete/#pick-a-role'
    ]
  },
  {
    group: 'Wire & register',
    question:
      'Are handler instances reused across chunks (instance fields, statics)?',
    targets: ['/guide/orchestrator#instances-per-chunk']
  },
  {
    group: 'Wire & register',
    question: 'Pass constructor arguments to a handler',
    targets: ['/guide/orchestrator#constructor-args']
  },
  {
    group: 'Wire & register',
    question: 'Check that a handler is registered (registration test)',
    targets: ['/guide/testing#registration']
  },
  {
    group: 'Choose where code goes',
    question: 'Which context and role do I need?',
    targets: ['/contexts#method-names']
  },
  {
    group: 'Choose where code goes',
    question: 'Writer or Dispatcher (DML or async)?',
    targets: ['chips:writer#when-to-use']
  },
  {
    group: 'Choose where code goes',
    question:
      'A class with two roles, or only the marker (Populator and Validator, Writer and Dispatcher)',
    targets: ['chips:overview#pick-a-role']
  },
  {
    group: 'Choose where code goes',
    question: 'Before delete or after delete?',
    targets: ['/before-delete/#pick-a-role', '/after-delete/#pick-a-role']
  },
  {
    group: 'Choose where code goes',
    question:
      'Decide before update, act after update (stamp a marker, handoff)',
    targets: ['/guide/orchestrator#before-after-handoff']
  },
  {
    group: 'Set fields',
    question: 'Set, default or derive a field before save (populate, stamp)',
    targets: ['chips:populator#interface']
  },
  {
    group: 'Set fields',
    question: 'Which record type do I get, and how do I read or write a field?',
    targets: ['chips:record-api#accessors']
  },
  {
    group: 'Set fields',
    question: 'Call `put()` after insert or after update',
    targets: ['chips:record-api#accessors']
  },
  {
    group: 'Set fields',
    question: 'Update the record I just inserted (self-update)',
    targets: ['/after-insert/#gotchas']
  },
  {
    group: 'Set fields',
    question: 'Did a field change (old value, `isChanged`, cleared)?',
    targets: ['chips:record-api#change-detection']
  },
  {
    group: 'Set fields',
    question:
      'Value predicates, null and case sensitivity (`equals`, `contains`)',
    targets: ['chips:record-api#comparisons']
  },
  {
    group: 'Set fields',
    question: 'Check the record type',
    targets: ['chips:record-api#record-type']
  },
  {
    group: 'Set fields',
    question:
      '`Trigger.new`, `newMap` and `oldMap` equivalents (bulk, pairing)',
    targets: ['chips:record-api#trigger-variables']
  },
  {
    group: 'Validate & block',
    question: 'Block a save with an error message (validation, reject)',
    targets: ['chips:validator#interface']
  },
  {
    group: 'Validate & block',
    question: 'Attach the error to a field (field-level error)',
    targets: ['chips:validator#gotchas']
  },
  {
    group: 'Validate & block',
    question: 'Translated error message (custom label)',
    targets: ['chips:validator#gotchas']
  },
  {
    group: 'Validate & block',
    question:
      'Several validators fail on one record; use parent or related data',
    targets: ['chips:validator#how-it-runs']
  },
  {
    group: 'Validate & block',
    question: 'Validate after save (needs the Id or saved state)',
    targets: ['/after-insert/#not-available', '/after-update/#not-available']
  },
  {
    group: 'Validate & block',
    question: 'Prevent a delete (veto, block)',
    targets: ['/before-delete/handler']
  },
  {
    group: 'Validate & block',
    question: 'Block an undelete (restore, before undelete)',
    targets: ['/after-undelete/#no-before-undelete', '/before-undelete']
  },
  {
    group: 'Read parents',
    question: 'Read parent (lookup) fields',
    targets: [
      'chips:parent-query#how-it-runs',
      '/before-delete/add-ons/prior-parent-query#how-it-runs',
      '/after-delete/add-ons/prior-parent-query#how-it-runs'
    ]
  },
  {
    group: 'Read parents',
    question: 'Read the previous parent (old lookup, prior owner)',
    targets: ['chips:prior-parent-query#how-it-runs']
  },
  {
    group: 'Read parents',
    question: 'Read grandparent fields (`Account.Owner.IsActive`)',
    targets: ['chips:parent-query#choosing-fields']
  },
  {
    group: 'Read parents',
    question:
      'A populator re-points a lookup: which parent do later handlers see?',
    targets: ['/before-update/add-ons/parent-query#how-it-runs']
  },
  {
    group: 'Read parents',
    question: 'Parent sharing, FLS and polymorphic lookups',
    targets: ['chips:parent-query#gotchas']
  },
  {
    group: 'Read other records',
    question: 'Query children, siblings or unrelated records (related records)',
    targets: ['chips:related-query#key-patterns']
  },
  {
    group: 'Read other records',
    question: 'Match on a text key or a composite key; load config',
    targets: ['chips:related-query#key-patterns']
  },
  {
    group: 'Read other records',
    question:
      'Read formula or system fields of the records being saved (re-query)',
    targets: ['chips:related-query#key-patterns']
  },
  {
    group: 'Read other records',
    question: 'Query related records in after delete',
    targets: ['/after-delete/add-ons/related-query#how-it-runs']
  },
  {
    group: 'Read other records',
    question:
      'Does a provider see all records, share results, respect sharing?',
    targets: ['chips:related-query#how-it-runs']
  },
  {
    group: 'Write other records',
    question: 'Insert, update, upsert, delete or publish (unit of work)',
    targets: ['chips:writer#unit-of-work-methods']
  },
  {
    group: 'Write other records',
    question:
      'When does the unit commit, and in what order (duplicates, statement order)?',
    targets: ['chips:writer#when-it-commits']
  },
  {
    group: 'Write other records',
    question:
      'User mode, sharing, partial success, DML results (own unit of work)',
    targets: ['chips:own-unit-of-work#configuring']
  },
  {
    group: 'Write other records',
    question: 'Write from a Finalizer (register in bulk)',
    targets: ['chips:finalizer#how-it-runs']
  },
  {
    group: 'Write other records',
    question: 'DML in a before context (before insert, update, delete)',
    targets: ['/before-insert/#gotchas', '/before-delete/add-ons/finalizer']
  },
  {
    group: 'Write other records',
    question: 'Run something once after the last chunk (end of DML)',
    targets: ['chips:overview#not-available']
  },
  {
    group: 'Async, callouts, events',
    question: 'Enqueue a job, call out or send email (Queueable, async)',
    targets: ['chips:dispatcher#how-it-runs']
  },
  {
    group: 'Async, callouts, events',
    question: 'Publish a platform event (after commit, immediately)',
    targets: ['chips:writer#platform-events']
  },
  {
    group: 'Async, callouts, events',
    question:
      'Trigger on a platform event or Change Data Capture object (subscribe, `__e`, `ChangeEvent`)',
    targets: ['/after-insert/#gotchas']
  },
  {
    group: 'Switch off',
    question:
      'Skip a handler on a condition (bypass, disable, skip records, in a batch)',
    targets: ['chips:bypassable#how-it-runs']
  },
  {
    group: 'Switch off',
    question: 'Turn everything off for a data load (migration, Data Loader)',
    targets: [
      'chips:bypassable#data-migration',
      '/guide/bypasses#data-migration'
    ]
  },
  {
    group: 'Switch off',
    question: 'Switch off one handler in production (metadata, no deploy)',
    targets: ['/api/custom-metadata#trigger-handler']
  },
  {
    group: 'Switch off',
    question: 'Bypass from Apex (object, orchestrator, one handler, one DML)',
    targets: ['chips:bypassable#other-ways']
  },
  {
    group: 'Switch off',
    question: 'Bypass for one user, profile or permission set',
    targets: ['chips:bypassable#other-ways', '/guide/bypasses#per-user']
  },
  {
    group: 'Switch off',
    question: 'Bypass only one context (only after update)',
    targets: ['chips:overview#switching-off']
  },
  {
    group: 'Switch off',
    question: 'Do bypasses affect Flows or validation rules?',
    targets: ['chips:bypassable#other-ways']
  },
  {
    group: 'Recursion',
    question: 'Stop recursion (run once per record, re-fire, loop)',
    targets: ['chips:recursion-guard#edge-values']
  },
  {
    group: 'Recursion',
    question: 'Are validators counted; can the orchestrator set a depth?',
    targets: ['chips:recursion-guard#works-with']
  },
  {
    group: 'Recursion',
    question: 'A recursion guard in insert, delete or undelete',
    targets: ['chips:overview#add-ons']
  },
  {
    group: 'Errors & logging',
    question: 'Let a handler fail without failing the save (ContinueOnError)',
    targets: ['chips:continue-on-error#still-throws']
  },
  {
    group: 'Errors & logging',
    question: 'Log errors (Logger, Error payload)',
    targets: ['/guide/error-handling#logger']
  },
  {
    group: 'Errors & logging',
    question: 'Which library exceptions can I catch?',
    targets: [
      '/api/trigger-orchestrator#triggerorchestratorexception',
      '/api/record#triggerhandlerexception'
    ]
  },
  {
    group: 'Errors & logging',
    question: 'Fail one record, not the whole save (uncaught exception)',
    targets: ['/guide/error-handling#one-record']
  },
  {
    group: 'Errors & logging',
    question: 'Partial success (`Database.insert(list, false)`, retries)',
    targets: ['chips:overview#gotchas']
  },
  {
    group: 'Delete & undelete',
    question: 'What does before delete give me?',
    targets: ['/before-delete/#gotchas']
  },
  {
    group: 'Delete & undelete',
    question: 'Update or re-delete the deleted record; merges',
    targets: ['/after-delete/#gotchas']
  },
  {
    group: 'Delete & undelete',
    question: 'What about after undelete (restored lookups)?',
    targets: ['/after-undelete/#gotchas']
  },
  {
    group: 'Testing',
    question:
      'Unit-test a handler without DML (fake Ids, parents, providers, unit of work)',
    targets: [
      'chips:populator#test',
      'chips:validator#test',
      'chips:handler#test',
      'chips:writer#test',
      'chips:dispatcher#test',
      '/guide/testing#handler',
      '/api/record#test-api'
    ]
  },
  {
    group: 'Testing',
    question:
      'Run the whole orchestrator in a test (mock queries, metadata, logger)',
    targets: ['/guide/testing#orchestrator', '/guide/testing#mock-metadata']
  },
  {
    group: 'Testing',
    question: 'Test 201-record chunking',
    targets: ['/guide/testing#integration']
  },
  {
    group: 'Limits & cost',
    question:
      'How much SOQL does one invocation cost (Logger discovery included)?',
    targets: ['/guide/execution-order#query-cost']
  },
  {
    group: 'Limits & cost',
    question: 'Can I query or do DML inside a predicate or action?',
    targets: ['chips:populator#how-it-runs', 'chips:writer#how-it-runs']
  },
  {
    group: 'Limits & cost',
    question: 'What does chunking multiply; how many DML statements?',
    targets: ['/guide/execution-order#chunking', '/guide/execution-order#dml-cost']
  },
  {
    group: 'Limits & cost',
    question: 'Are parents cached across chunks or nested runs?',
    targets: ['/guide/execution-order#parent-cache']
  },
  {
    group: 'Limits & cost',
    question:
      'What is missing in before insert, before update and after insert or update?',
    targets: ['chips:overview#gotchas']
  }
];

export const CONTEXTS_PAGE_SECTIONS = [
  {
    id: 'method-names',
    include: '@/_parts/generated/matrix-methods.md'
  },
  { id: 'facts', include: '@/_parts/generated/matrix-facts.md' },
  { id: 'url-rules', include: null }
];

export function expectedH1(template, contextName, interfaceName) {
  if (template === 'context') return [contextName];
  if (template === 'role' || template === 'add-on')
    return [`${contextName}.${interfaceName}`];
  if (template === 'add-ons')
    return [`${contextName} Add-ons`, `Add-ons in ${contextName}`];
  if (template === 'record-api') return [`Record API in ${contextName}`];
  return null;
}

export function requiredIncludes(template, contextName, interfaceName) {
  const context = getContext(contextName);
  if (!context) return [];
  const generated = `@/_parts/generated/${context.slug}`;
  const item = interfaceName ? getInterface(contextName, interfaceName) : null;
  const own = item ? `${generated}/${item.slug}` : null;

  if (template === 'context') {
    return [
      {
        section: 'at-a-glance',
        snippet: `@/../force-app/main/default/classes/${context.name}.cls`
      },
      { section: 'at-a-glance', include: `${generated}/facts.md` },
      { section: 'add-ons', include: `${generated}/add-ons-table.md` },
      { section: 'records', include: `${generated}/records.md` },
      { section: 'register', include: `${generated}/register.md` },
      { section: 'not-available', include: `${generated}/not-available.md` }
    ];
  }

  if (template === 'role' && own) {
    return [
      { section: 'lead', include: `${own}/available-in.md` },
      { section: 'interface', include: `${own}/signature.md` },
      { section: 'interface', include: `${own}/method-table.md` },
      {
        section: 'example',
        include: `${own}/skeleton.md`,
        firstInCodeGroup: true
      },
      { section: 'register', include: `${generated}/register.md` },
      { section: 'records', include: `${generated}/accessors.md` },
      { section: 'works-with', include: `${own}/works-with.md` },
      { section: 'other-contexts', include: `${own}/other-contexts.md` }
    ];
  }

  if (template === 'add-on' && own) {
    const required = [
      { section: 'lead', include: `${own}/available-in.md` },
      { section: 'interface', include: `${own}/signature.md` }
    ];
    if (item.supports.length > 0) {
      for (const support of item.supports) {
        required.push({
          section: getInterface(contextName, support).slug,
          include: `${own}/${getInterface(contextName, support).slug}.md`
        });
      }
    }
    required.push(
      {
        section: 'example',
        include: `${own}/skeleton.md`,
        firstInCodeGroup: true
      },
      { section: 'works-with', include: `${own}/works-with.md` }
    );
    if (TEST_TECHNIQUE_REGIONS[interfaceName]) {
      required.push({
        section: 'test',
        include: '@/_parts/add-ons/test-techniques.md',
        region: TEST_TECHNIQUE_REGIONS[interfaceName]
      });
    }
    required.push({
      section: 'other-contexts',
      include: `${own}/other-contexts.md`
    });
    return required;
  }

  if (template === 'add-ons') {
    return [
      { section: 'available', include: `${generated}/add-ons-available.md` },
      {
        section: 'not-available',
        include: `${generated}/add-ons-not-available.md`
      },
      { section: 'works-with', include: `${generated}/add-ons-works-with.md` }
    ];
  }

  if (template === 'record-api') {
    const required = [
      { section: 'accessors', include: `${generated}/accessors.md` }
    ];
    if (context.operation === 'Update') {
      required.push({
        section: 'change-detection',
        include: '@/_parts/records/change-detection.md'
      });
    }
    required.push(
      {
        section: 'predicates',
        include: '@/_parts/records/predicates.md',
        region: context.slug
      },
      { section: 'comparisons', include: '@/_parts/records/comparisons.md' },
      { section: 'record-type', include: '@/_parts/records/record-type.md' },
      { section: 'collections', include: `${generated}/collections.md` },
      {
        section: 'trigger-variables',
        include: `${generated}/trigger-variables.md`
      },
      {
        section: 'gotchas',
        include: '@/_parts/records/gotchas.md',
        region: context.slug
      }
    );
    return required;
  }

  return [];
}

export function templateHeadings(template, contextName, interfaceName) {
  const definition = templates[template];
  if (!definition) return null;
  return {
    h2: definition.h2.map(entry => ({
      id: entry.id,
      text: headingText(entry, contextName)
    })),
    h3: [
      ...(definition.h3ByContext[contextName] ?? []),
      ...(definition.h3ByInterface[interfaceName] ?? [])
    ].map(entry => ({
      id: entry.id,
      under: entry.under,
      text: headingText(entry, contextName)
    }))
  };
}

const slugSpecial = /[\s~`!@#$%^&*()\-_+=[\]{}|\\;:"'“”‘’<>,.?/]+/g;

export function slugify(text) {
  return text
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[\u0000-\u001f]/g, '')
    .replace(slugSpecial, '-')
    .replace(/-{2,}/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/^(\d)/, '_$1')
    .toLowerCase();
}

export function plainHeadingText(text) {
  return text
    .replace(/!\[[^\]]*\]\([^)]*\)/g, '')
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/<[^>]+>/g, '')
    .replace(/(`+)([\s\S]*?)\1/g, '$2')
    .replace(/(\*\*|__)(.+?)\1/g, '$2')
    .replace(/(^|[^\w*])\*(?=\S)(.+?)(?<=\S)\*(?![\w*])/g, '$1$2')
    .replace(/(^|\W)_(?=\S)(.+?)(?<=\S)_(?!\w)/g, '$1$2')
    .replace(/\\([\\`*_{}[\]()#+\-.!|<>])/g, '$1')
    .trim();
}

function unquote(value) {
  if (/^'.*'$/.test(value)) return value.slice(1, -1).replace(/''/g, "'");
  if (/^".*"$/.test(value)) return value.slice(1, -1).replace(/\\"/g, '"');
  return value.replace(/\s+#.*$/, '');
}

export function parseFrontmatter(lines) {
  const data = {};
  const keyLines = {};
  const links = [];

  lines.forEach((line, index) => {
    const link = line.match(/^\s*(?:-\s+)?link:\s*['"]?([^'"\s]+)['"]?\s*$/);
    if (link) links.push({ url: link[1], line: index + 2 });
  });

  for (let index = 0; index < lines.length; index++) {
    const match = lines[index].match(/^([A-Za-z_][\w-]*):(?:[ \t]+(.*))?$/);
    if (!match) continue;
    const [, key, rawValue = ''] = match;
    keyLines[key] = index + 2;
    let value = rawValue.trim();

    if (/^[>|][+-]?$/.test(value)) {
      const block = [];
      while (
        index + 1 < lines.length &&
        (/^\s+\S/.test(lines[index + 1]) || lines[index + 1].trim() === '')
      ) {
        block.push(lines[++index].trim());
      }
      value = block.filter(Boolean).join(value.startsWith('>') ? ' ' : '\n');
    } else if (value === '') {
      const nested = [];
      while (
        index + 1 < lines.length &&
        (/^\s/.test(lines[index + 1]) || lines[index + 1].trim() === '')
      ) {
        nested.push(lines[++index]);
      }
      value = nested.some(line => line.trim()) ? { nested } : '';
    } else {
      value = unquote(value);
    }

    data[key] = value;
  }

  return { data, keyLines, links };
}

function blankCode(line) {
  return line.replace(/(`+)(?!`)([\s\S]*?[^`])\1(?!`)/g, match =>
    ' '.repeat(match.length)
  );
}

function extractInline(doc, line, index) {
  for (const match of line.matchAll(/(`+)(?!`)([\s\S]*?[^`])\1(?!`)/g)) {
    doc.inlineCode.push({
      line: index + 1,
      index,
      code: match[2].trim()
    });
  }

  const withoutCode = blankCode(line);
  for (const match of withoutCode.matchAll(
    /(!?)\[(?:[^[\]]|\[[^\]]*\])*\]\(\s*<?([^)\s>]+)>?(?:\s+(?:"[^"]*"|'[^']*'))?\s*\)/g
  )) {
    if (match[1] === '!') continue;
    doc.links.push({ line: index + 1, index, url: match[2] });
  }
  const definition = withoutCode.match(
    /^ {0,3}\[[^\]]+\]:\s*<?(\S+?)>?(?:\s|$)/
  );
  if (definition)
    doc.links.push({ line: index + 1, index, url: definition[1] });
  for (const match of withoutCode.matchAll(/\bhref\s*=\s*["']([^"']+)["']/g)) {
    doc.links.push({ line: index + 1, index, url: match[1] });
  }
  for (const match of withoutCode.matchAll(/\sid\s*=\s*["']([^"']+)["']/g)) {
    doc.htmlIds.push(match[1]);
  }
}

function headingFrom(raw, level, index) {
  let text = raw.replace(/(?:^|[ \t]+)#+[ \t]*$/, '').trim();
  let explicitId = null;
  const idMatch = text.match(EXPLICIT_ID_PATTERN);
  if (idMatch) {
    explicitId = idMatch[1];
    text = text.slice(0, idMatch.index).trim();
  }
  const plain = plainHeadingText(text);
  return {
    level,
    text,
    plain,
    explicitId,
    id: explicitId ?? slugify(plain),
    index,
    line: index + 1
  };
}

export function parseMarkdown(source) {
  const lines = source.replace(/\r\n?/g, '\n').split('\n');
  const doc = {
    lines,
    frontmatter: {},
    frontmatterKeyLines: {},
    frontmatterLinks: [],
    bodyStart: 0,
    kinds: new Array(lines.length).fill('text'),
    fences: [],
    headings: [],
    includes: [],
    snippets: [],
    links: [],
    inlineCode: [],
    htmlIds: [],
    paragraphs: [],
    allowed: new Set(),
    allowMarkers: [],
    problems: []
  };

  if (lines[0] === '---') {
    const end = lines.indexOf('---', 1);
    if (end === -1) {
      doc.problems.push({ line: 1, message: 'frontmatter is never closed' });
    } else {
      const parsed = parseFrontmatter(lines.slice(1, end));
      doc.frontmatter = parsed.data;
      doc.frontmatterKeyLines = parsed.keyLines;
      doc.frontmatterLinks = parsed.links;
      for (let index = 0; index <= end; index++)
        doc.kinds[index] = 'frontmatter';
      doc.bodyStart = end + 1;
    }
  }

  let fence = null;
  let comment = false;

  for (let index = doc.bodyStart; index < lines.length; index++) {
    const line = lines[index];

    for (const match of line.matchAll(INCLUDE_PATTERN)) {
      doc.includes.push({
        line: index + 1,
        index,
        spec: match[1],
        raw: match[0],
        alone: line.trim() === match[0],
        inFence: Boolean(fence)
      });
    }

    if (fence) {
      const close = line.match(FENCE_CLOSE_PATTERN);
      if (
        close &&
        close[1][0] === fence.char &&
        close[1].length >= fence.length
      ) {
        fence.end = index;
        fence.endLine = index + 1;
        doc.kinds[index] = 'fence-close';
        doc.fences.push(fence);
        fence = null;
      } else {
        doc.kinds[index] = 'fence';
        fence.content.push(line);
      }
      continue;
    }

    const trimmed = line.trim();

    if (comment) {
      doc.kinds[index] = 'comment';
      if (trimmed.includes('-->')) comment = false;
      continue;
    }

    const open = line.match(FENCE_OPEN_PATTERN);
    if (open && !(open[1][0] === '`' && open[2].includes('`'))) {
      fence = {
        char: open[1][0],
        length: open[1].length,
        start: index,
        startLine: index + 1,
        info: open[2].trim(),
        content: []
      };
      doc.kinds[index] = 'fence-open';
      continue;
    }

    if (trimmed === '') {
      doc.kinds[index] = 'blank';
      continue;
    }

    if (trimmed.startsWith('<!--')) {
      if (!trimmed.includes('-->')) {
        comment = true;
        doc.kinds[index] = 'comment';
        continue;
      }
      if (
        trimmed.endsWith('-->') &&
        trimmed.indexOf('-->') === trimmed.length - 3
      ) {
        doc.kinds[index] = INCLUDE_PATTERN.test(trimmed)
          ? 'include'
          : 'comment';
        INCLUDE_PATTERN.lastIndex = 0;
        if (ALLOW_PATTERN.test(trimmed)) doc.allowMarkers.push(index);
        continue;
      }
    }

    const snippet = line.match(SNIPPET_LINE_PATTERN);
    if (snippet) {
      doc.kinds[index] = 'snippet';
      doc.snippets.push({ line: index + 1, index, raw: snippet[1].trim() });
      continue;
    }

    if (/^ {0,3}:::/.test(line)) {
      doc.kinds[index] = 'container';
      continue;
    }

    const atx = line.match(ATX_PATTERN);
    if (atx) {
      doc.kinds[index] = 'heading';
      doc.headings.push(headingFrom(atx[2] ?? '', atx[1].length, index));
      extractInline(doc, line, index);
      continue;
    }

    const setext = line.match(SETEXT_PATTERN);
    const previous = index - 1;
    if (
      setext &&
      previous >= doc.bodyStart &&
      doc.kinds[previous] === 'text' &&
      !/^\s*(?:[-*+>|]|\d+[.)])/.test(lines[previous])
    ) {
      doc.kinds[previous] = 'heading';
      doc.kinds[index] = 'setext';
      const heading = headingFrom(
        lines[previous].trim(),
        setext[1][0] === '=' ? 1 : 2,
        previous
      );
      heading.setext = true;
      doc.headings.push(heading);
      continue;
    }

    doc.kinds[index] = trimmed.startsWith('|') ? 'table' : 'text';
    extractInline(doc, line, index);
  }

  if (fence) {
    doc.problems.push({
      line: fence.startLine,
      message: 'code fence is never closed'
    });
    fence.end = lines.length - 1;
    fence.endLine = lines.length;
    fence.unclosed = true;
    doc.fences.push(fence);
  }

  doc.headings.sort((left, right) => left.index - right.index);

  let paragraph = null;
  for (let index = doc.bodyStart; index < lines.length; index++) {
    const kind = doc.kinds[index];
    if (kind === 'text' || kind === 'table') {
      if (!paragraph) {
        paragraph = { start: index, lines: [] };
        doc.paragraphs.push(paragraph);
      }
      paragraph.lines.push(lines[index]);
      paragraph.end = index;
    } else {
      paragraph = null;
    }
  }

  for (const marker of doc.allowMarkers) {
    let next = marker + 1;
    while (next < lines.length && doc.kinds[next] === 'blank') next++;
    if (next >= lines.length) continue;
    if (doc.kinds[next] === 'fence-open') {
      const block = doc.fences.find(candidate => candidate.start === next);
      for (let index = next; index <= (block?.end ?? next); index++)
        doc.allowed.add(index);
    } else {
      for (
        let index = next;
        index < lines.length && doc.kinds[index] !== 'blank';
        index++
      ) {
        doc.allowed.add(index);
      }
    }
  }

  return doc;
}

export function findRegion(lines, name) {
  let start = -1;
  for (const [index, line] of lines.entries()) {
    const match = REGION_MARKER_STRICT.exec(line.trim());
    if (!match || match[2] !== name) continue;
    if (start === -1) {
      if (match[1] === 'region') start = index + 1;
    } else if (match[1] === 'endregion') {
      return { start, end: index };
    }
  }
  return null;
}

export function scanRegions(lines) {
  const open = new Map();
  const regions = new Map();
  const problems = [];

  lines.forEach((line, index) => {
    const trimmed = line.trim();
    if (!REGION_MARKER_LOOSE.test(trimmed)) return;
    const match = REGION_MARKER_STRICT.exec(trimmed);
    if (!match) {
      problems.push({
        line: index + 1,
        message: `malformed region marker "${trimmed}": write <!-- #region name --> and <!-- #endregion name -->, and repeat the name on the end marker`
      });
      return;
    }
    const [, tag, name] = match;
    if (tag === 'region') {
      if (open.has(name) || regions.has(name)) {
        problems.push({
          line: index + 1,
          message: `region "${name}" starts twice; VitePress uses only the first`
        });
      } else {
        open.set(name, index);
      }
    } else if (!open.has(name)) {
      problems.push({
        line: index + 1,
        message: `<!-- #endregion ${name} --> has no <!-- #region ${name} --> above it`
      });
    } else {
      regions.set(name, {
        start: open.get(name) + 1,
        end: index,
        startLine: open.get(name) + 1,
        endLine: index + 1
      });
      open.delete(name);
    }
  });

  for (const [name, index] of open) {
    problems.push({
      line: index + 1,
      message: `region "${name}" is never closed with <!-- #endregion ${name} -->`
    });
  }

  return { regions, problems };
}

export function parseIncludeSpec(spec) {
  const range = spec.match(/\{(\d*),(\d*)\}$/);
  const region = spec.match(/(#[\w-]+)/);
  let path = spec;
  if (region || range) {
    path = spec.slice(
      0,
      -((region?.[0].length ?? 0) + (range?.[0].length ?? 0))
    );
  }
  return {
    path,
    region: region ? region[1].slice(1) : null,
    range: range ? range[0] : null
  };
}

function resolveIncludePath(path, fromAbs, websiteDir) {
  if (path.startsWith('@'))
    return join(websiteDir, path.slice(path[1] === '/' ? 2 : 1));
  return join(dirname(fromAbs), path);
}

export function parseSnippet(raw, pageAbs, websiteDir) {
  const rawPath = raw.trim().replace(/^@/, websiteDir).trim();
  const [, filepath = '', , region = '', lines = '', lang = '', attrs = ''] =
    SNIPPET_PATH_PATTERN.exec(rawPath) ?? [];
  const withoutTitle = raw.trim().replace(/\s*\[[^\]]*\]$/, '');
  return {
    file: resolve(dirname(pageAbs), filepath),
    region: region ? region.slice(1) : null,
    lines,
    lang,
    attrs,
    hasBraces: /\}$/.test(withoutTitle) || /\{[^}]*\}/.test(withoutTitle),
    usesAt: raw.trim().startsWith('@')
  };
}

function stripFrontmatter(content) {
  const lines = content.split(/\r?\n/);
  if (lines[0] !== '---') return content;
  const end = lines.indexOf('---', 1);
  if (end === -1) return content;
  return lines.slice(end + 1).join('\n');
}

export function expandIncludes(source, fileAbs, websiteDir, depth = 0) {
  if (depth > 10) return source;
  return source.replace(INCLUDE_PATTERN, (match, spec) => {
    if (!spec.length) return match;
    const parsed = parseIncludeSpec(spec);
    const target = resolveIncludePath(parsed.path, fileAbs, websiteDir);
    if (!existsSync(target) || !statSync(target).isFile()) return match;
    let content = readFileSync(target, 'utf8');
    if (parsed.region) {
      const lines = content.split(/\r?\n/);
      const found = findRegion(lines, parsed.region);
      content = lines.slice(found?.start, found?.end).join('\n');
    }
    if (parsed.range) {
      const [, first, last] = parsed.range.match(/\{(\d*),(\d*)\}/);
      const lines = content.split(/\r?\n/);
      content = lines
        .slice(
          first ? parseInt(first, 10) - 1 : undefined,
          last ? parseInt(last, 10) : undefined
        )
        .join('\n');
    }
    if (!parsed.region && !parsed.range && target.endsWith('.md'))
      content = stripFrontmatter(content);
    return expandIncludes(content, target, websiteDir, depth + 1);
  });
}

export function collectIds(doc) {
  const ids = new Set();
  const used = new Set();
  for (const heading of doc.headings) {
    let id = heading.explicitId ?? heading.id;
    if (!heading.explicitId) {
      const base = id;
      let suffix = 1;
      while (used.has(id)) id = `${base}-${suffix++}`;
    }
    used.add(id);
    ids.add(id);
  }
  for (const id of doc.htmlIds) ids.add(id);
  return ids;
}

function methodPrefixes(methodNames) {
  return [...methodNames].filter(name => {
    METHOD_TOKEN_PATTERN.lastIndex = 0;
    const match = METHOD_TOKEN_PATTERN.exec(name);
    METHOD_TOKEN_PATTERN.lastIndex = 0;
    return match && match[0] === name;
  });
}

function distance(left, right) {
  const previous = Array.from({ length: right.length + 1 }, (_, i) => i);
  for (let i = 1; i <= left.length; i++) {
    let diagonal = previous[0];
    previous[0] = i;
    for (let j = 1; j <= right.length; j++) {
      const saved = previous[j];
      previous[j] = Math.min(
        previous[j] + 1,
        previous[j - 1] + 1,
        diagonal + (left[i - 1] === right[j - 1] ? 0 : 1)
      );
      diagonal = saved;
    }
  }
  return previous[right.length];
}

function contextOf(name) {
  const match = name.match(
    /(Before|After|before|after)(Insert|Update|Delete|Undelete)/
  );
  return match
    ? `${match[1][0].toUpperCase()}${match[1].slice(1)}${match[2]}`
    : null;
}

function closestName(token, names) {
  const context = contextOf(token);
  const sameContext = names.filter(name => contextOf(name) === context);
  let best = null;
  let bestDistance = Infinity;
  for (const name of sameContext.length > 0 ? sameContext : names) {
    const current = distance(token, name);
    if (current < bestDistance) {
      best = name;
      bestDistance = current;
    }
  }
  return bestDistance <= Math.max(6, Math.floor(token.length / 3))
    ? best
    : null;
}

export function methodTokenProblems(text, methodNames = model.methodNames) {
  const prefixes = methodPrefixes(methodNames);
  const problems = [];
  for (const match of text.matchAll(METHOD_TOKEN_PATTERN)) {
    const token = match[0];
    if (methodNames.has(token)) continue;
    if (prefixes.some(name => token.startsWith(name))) continue;
    problems.push({
      token,
      index: match.index,
      suggestion: closestName(token, prefixes)
    });
  }
  return problems;
}

export function staleFenceProblems(content, { testingPage = false } = {}) {
  const problems = [];
  for (const entry of STALE_FENCE_PATTERNS) {
    if (entry.testingOnly && testingPage) continue;
    entry.pattern.lastIndex = 0;
    for (const match of content.matchAll(entry.pattern)) {
      const offset = content.slice(0, match.index).split('\n').length - 1;
      const lastLine = match[0].split('\n').length - 1;
      problems.push({
        offset: offset + lastLine,
        text: match[0].replace(/\s+/g, ' '),
        message: entry.message
      });
    }
  }
  return problems;
}

export function staleProseProblems(text) {
  const problems = [];
  const sentences = text.split(/(?<=[.!?][*_)"'”’]*)\s+/);
  for (const sentence of sentences) {
    if (
      GUARD_SENTENCE_PATTERN.test(sentence) &&
      FINALLY_PATTERN.test(sentence)
    ) {
      problems.push({
        text: sentence.trim(),
        message:
          'the DML guard runs after the try block, not in a finally; without ContinueOnError the handler’s own exception wins'
      });
    }
  }
  for (const match of text.matchAll(RECORD_IDS_NULL_PATTERN)) {
    problems.push({
      text: match[0],
      message:
        'getRecordIds() is never null: in before insert it is an empty Set<Id>'
    });
  }
  return problems;
}

function toPosix(path) {
  return path.split(sep).join('/');
}

function walk(directory, skip = () => false) {
  if (!existsSync(directory)) return [];
  const found = [];
  for (const name of readdirSync(directory).sort()) {
    const full = join(directory, name);
    if (statSync(full).isDirectory()) {
      if (!skip(name)) found.push(...walk(full, skip));
    } else if (name.endsWith('.md')) {
      found.push(full);
    }
  }
  return found;
}

function pageUrl(rel) {
  if (rel === 'index.md') return '/';
  if (rel.endsWith('/index.md')) return `/${rel.slice(0, -'index.md'.length)}`;
  return `/${rel.slice(0, -'.md'.length)}`;
}

function createState(options) {
  const websiteDir = resolve(options.websiteDir ?? WEBSITE_DIR);
  const repoRoot = resolve(options.repoRoot ?? join(websiteDir, '..'));
  const expected = expectedPages();
  return {
    websiteDir,
    repoRoot,
    partsDir: join(websiteDir, '_parts'),
    generatedDir: join(websiteDir, '_parts', 'generated'),
    factsFile: join(WEBSITE_DIR, '.vitepress', 'context-facts.mjs'),
    sidebarFile: join(WEBSITE_DIR, '.vitepress', 'apex-api.mjs'),
    checkerFile: join(WEBSITE_DIR, '.vitepress', 'scripts', 'check-docs.mjs'),
    vercelPath: options.vercelPath ?? join(repoRoot, 'vercel.json'),
    sidebar: options.sidebar ?? defaultSidebar,
    nav: options.nav ?? defaultNav,
    honourTable: options.honourTable ?? defaultHonourTable,
    methodNames: options.methodNames ?? model.methodNames,
    expected,
    expectedByPath: new Map(expected.map(page => [page.path, page])),
    pages: new Map(),
    handPartials: new Map(),
    generatedPartials: new Map(),
    ids: new Map(),
    errors: [],
    aggregated: new Map(),
    suppressed: 0,
    counts: { links: 0, includes: 0, snippets: 0 }
  };
}

function display(state, abs) {
  const fromRoot = relative(state.repoRoot, abs);
  return toPosix(
    fromRoot.startsWith('..') || isAbsolute(fromRoot) ? abs : fromRoot
  );
}

function report(state, rule, target, line, message) {
  const file = typeof target === 'string' ? target : display(state, target.abs);
  state.errors.push({ rule, file, line: line ?? null, message });
}

function aggregate(state, rule, record, line, key, message) {
  const existing = state.aggregated.get(key);
  if (existing) {
    existing.count++;
    return;
  }
  state.aggregated.set(key, {
    rule,
    file: display(state, record.abs),
    line,
    message,
    count: 1
  });
}

function loadRecord(abs, kind, state) {
  const source = readFileSync(abs, 'utf8');
  return {
    abs,
    kind,
    source,
    doc: parseMarkdown(source),
    rel: toPosix(relative(state.websiteDir, abs)),
    partRel: kind === 'page' ? null : toPosix(relative(state.partsDir, abs))
  };
}

function loadFiles(state) {
  for (const abs of walk(state.websiteDir, name =>
    SKIPPED_DIRECTORIES.has(name)
  )) {
    const record = loadRecord(abs, 'page', state);
    const fm = record.doc.frontmatter;
    record.url = pageUrl(record.rel);
    record.template = typeof fm.template === 'string' ? fm.template : null;
    record.contextName = typeof fm.context === 'string' ? fm.context : null;
    record.interfaceName =
      typeof fm.interface === 'string' ? fm.interface : null;
    record.context = record.contextName ? getContext(record.contextName) : null;
    state.pages.set(record.rel, record);
  }

  for (const abs of walk(state.partsDir)) {
    const generated = toPosix(relative(state.generatedDir, abs));
    const isGenerated = !generated.startsWith('..');
    const record = loadRecord(abs, isGenerated ? 'generated' : 'hand', state);
    (isGenerated ? state.generatedPartials : state.handPartials).set(
      record.partRel,
      record
    );
  }
}

function allRecords(state) {
  return [
    ...state.pages.values(),
    ...state.handPartials.values(),
    ...state.generatedPartials.values()
  ];
}

function isTemplatePage(record) {
  return Boolean(
    record.template && templates[record.template] && record.context
  );
}

function contextSlugOfPath(rel) {
  const first = rel.split('/')[0];
  return model.contexts.find(context => context.slug === first) ?? null;
}

function describeExpected(page) {
  if (page.template === 'role' || page.template === 'add-on')
    return `${page.context}.${page.interface}`;
  if (page.template === 'context') return `${page.context} overview`;
  if (page.template === 'add-ons') return `${page.context} add-ons overview`;
  if (page.template === 'record-api') return `${page.context} Record API`;
  return page.path;
}

function interfaceHint(contextName, interfaceName) {
  if (!interfaceName || !getContext(contextName)) return '';
  const item = getInterface(contextName, interfaceName);
  if (!item) return `, which ${contextName}.cls does not declare`;
  if (!item.pagePath)
    return `, a ${item.kind} interface documented on another page`;
  return `, whose page is website/${item.pagePath}.md`;
}

function checkPages(state) {
  for (const page of state.expected) {
    if (!page.template) continue;
    if (!state.pages.has(page.path)) {
      report(
        state,
        1,
        `${display(state, join(state.websiteDir, page.path))}`,
        null,
        `missing page for ${describeExpected(page)} (template: ${page.template}); create a stub with node website/.vitepress/scripts/scaffold.mjs`
      );
    }
  }

  for (const record of state.pages.values()) {
    const fm = record.doc.frontmatter;
    const lineOf = key => record.doc.frontmatterKeyLines[key] ?? 1;
    const expected = state.expectedByPath.get(record.rel);

    if (fm.template === undefined) {
      if (expected?.template) {
        report(
          state,
          1,
          record,
          1,
          `frontmatter needs template: ${expected.template}, context: ${expected.context}${expected.interface ? `, interface: ${expected.interface}` : ''}`
        );
      } else if (contextSlugOfPath(record.rel) && !expected) {
        const context = contextSlugOfPath(record.rel);
        report(
          state,
          1,
          record,
          1,
          `page under /${context.slug}/ is not one of the pages ${context.name}.cls calls for; move or delete it`
        );
      }
      continue;
    }

    if (!templates[fm.template]) {
      report(
        state,
        1,
        record,
        lineOf('template'),
        `unknown template "${fm.template}"; use one of ${Object.keys(templates).join(', ')}`
      );
      continue;
    }

    if (!expected || expected.template !== fm.template) {
      const context = getContext(fm.context);
      let message;
      if (!context) {
        message = `context: ${fm.context ?? '(missing)'} is not a trigger context; use one of ${model.contexts.map(entry => entry.name).join(', ')}`;
      } else if (fm.template === 'role' || fm.template === 'add-on') {
        const item = getInterface(fm.context, fm.interface);
        const kind = fm.template === 'role' ? 'role' : 'addOn';
        if (!item) {
          message = `interface: ${fm.interface ?? '(missing)'} is not declared in ${fm.context}.cls`;
        } else if (item.kind !== kind) {
          message = `${fm.context}.${fm.interface} is ${item.kind === 'role' ? 'a role' : item.kind === 'addOn' ? 'an add-on' : `a ${item.kind} interface without a page`}, not ${kind === 'role' ? 'a role' : 'an add-on'}`;
        } else {
          message = `this ${fm.context}.${fm.interface} page belongs at website/${item.pagePath}.md`;
        }
      } else {
        const home = state.expected.find(
          page => page.template === fm.template && page.context === fm.context
        );
        message = home
          ? `template: ${fm.template} for ${fm.context} belongs at website/${home.path}`
          : `template: ${fm.template} has no page in ${fm.context}`;
      }
      report(state, 1, record, lineOf('template'), message);
      continue;
    }

    if (fm.context !== expected.context) {
      report(
        state,
        1,
        record,
        lineOf('context'),
        `context: must be ${expected.context} (found ${fm.context ?? 'nothing'})`
      );
    }
    if (expected.interface) {
      if (fm.interface !== expected.interface) {
        report(
          state,
          1,
          record,
          lineOf('interface'),
          `interface: must be ${expected.interface} (found ${fm.interface ?? 'nothing'}${interfaceHint(fm.context, fm.interface)})`
        );
      }
    } else if (fm.interface !== undefined) {
      report(
        state,
        1,
        record,
        lineOf('interface'),
        `only role and add-on pages declare interface; remove it from this ${fm.template} page`
      );
    }
    if (typeof fm.description !== 'string' || fm.description.trim() === '') {
      report(
        state,
        1,
        record,
        lineOf('description'),
        'frontmatter needs a non-empty description (task words: bypass, skip, lookup, parent fields, callout…)'
      );
    }
  }
}

function sectionRanges(doc) {
  const ranges = new Map();
  const headings = doc.headings;
  const h1 = headings.find(heading => heading.level === 1);
  const firstH2 = headings.find(heading => heading.level === 2);
  ranges.set('lead', {
    start: h1 ? h1.index : doc.bodyStart,
    end: firstH2 ? firstH2.index : doc.lines.length,
    heading: h1 ?? null
  });

  headings.forEach((heading, position) => {
    if ((heading.level !== 2 && heading.level !== 3) || !heading.explicitId)
      return;
    let end = doc.lines.length;
    for (const next of headings.slice(position + 1)) {
      if (next.level <= heading.level) {
        end = next.index;
        break;
      }
    }
    if (!ranges.has(heading.explicitId))
      ranges.set(heading.explicitId, { start: heading.index, end, heading });
  });

  return ranges;
}

function includeTarget(state, record, include) {
  const parsed = parseIncludeSpec(include.spec);
  return {
    ...parsed,
    abs: resolveIncludePath(parsed.path, record.abs, state.websiteDir)
  };
}

function snippetTarget(state, record, snippet) {
  return parseSnippet(snippet.raw, record.abs, state.websiteDir);
}

function checkHeadingIds(state, record) {
  const used = new Set();
  for (const heading of record.doc.headings) {
    if (heading.setext) {
      report(
        state,
        2,
        record,
        heading.line,
        `setext heading "${heading.text}"; write it as an ATX heading (${'#'.repeat(heading.level)} …)${heading.level > 1 ? ' with an explicit {#id}' : ''}`
      );
    }
    if ((heading.level === 2 || heading.level === 3) && !heading.explicitId) {
      report(
        state,
        2,
        record,
        heading.line,
        `${'#'.repeat(heading.level)} ${heading.text} has no explicit {#id}; add one, for example {#${heading.id || 'section'}}`
      );
    }
    if (heading.explicitId) {
      if (used.has(heading.explicitId)) {
        report(
          state,
          2,
          record,
          heading.line,
          `duplicate id #${heading.explicitId} (VitePress stops the build on a repeated explicit id)`
        );
      }
      used.add(heading.explicitId);
    } else {
      let id = heading.id;
      const base = id;
      let suffix = 1;
      while (used.has(id)) id = `${base}-${suffix++}`;
      if (id !== base && heading.level <= 3) {
        report(
          state,
          2,
          record,
          heading.line,
          `heading "${heading.text}" repeats the id #${base}; give it an explicit, unique {#id}`
        );
      }
      used.add(id);
    }
  }

  for (const problem of record.doc.problems) {
    report(state, 2, record, problem.line, problem.message);
  }
}

function checkTemplatePage(state, record) {
  const doc = record.doc;
  const template = record.template;
  const contextName = record.contextName;
  const interfaceName = record.interfaceName;
  const expectedHeadings = templateHeadings(
    template,
    contextName,
    interfaceName
  );

  const h1s = doc.headings.filter(heading => heading.level === 1);
  const allowedH1 = expectedH1(template, contextName, interfaceName);
  if (h1s.length === 0) {
    report(
      state,
      2,
      record,
      doc.bodyStart + 1,
      `missing H1: # ${allowedH1[0]}`
    );
  } else {
    if (doc.headings[0] !== h1s[0]) {
      report(
        state,
        2,
        record,
        doc.headings[0].line,
        'the H1 must be the first heading'
      );
    }
    if (!allowedH1.includes(h1s[0].text)) {
      report(
        state,
        2,
        record,
        h1s[0].line,
        `H1 must read "# ${allowedH1.join('" or "# ')}"`
      );
    }
    for (const extra of h1s.slice(1)) {
      report(state, 2, record, extra.line, 'only one H1 per page');
    }
    const lead = sectionRanges(doc).get('lead');
    const hasLead = doc.paragraphs.some(
      paragraph =>
        paragraph.start > h1s[0].index &&
        paragraph.start < lead.end &&
        doc.kinds[paragraph.start] === 'text'
    );
    if (!hasLead) {
      report(
        state,
        2,
        record,
        h1s[0].line,
        'missing lead sentence under the H1 (spell out the context in words, with task synonyms)'
      );
    }
  }

  const h2s = doc.headings.filter(heading => heading.level === 2);
  const templateIds = expectedHeadings.h2.map(entry => entry.id);
  const seen = new Map();
  let lastPosition = -1;
  let lastHeading = null;

  for (const heading of h2s) {
    const entry = expectedHeadings.h2.find(
      candidate => candidate.id === heading.explicitId
    );
    if (!heading.explicitId) {
      const byText = expectedHeadings.h2.find(
        candidate => candidate.text === heading.text
      );
      if (byText) {
        report(
          state,
          2,
          record,
          heading.line,
          `write it as "## ${byText.text} {#${byText.id}}"`
        );
        seen.set(byText.id, heading);
      } else {
        report(
          state,
          2,
          record,
          heading.line,
          `unexpected H2 "## ${heading.text}"; ${template} pages have exactly: ${expectedHeadings.h2.map(item => `## ${item.text} {#${item.id}}`).join(', ')}`
        );
      }
      continue;
    }
    if (!entry) {
      report(
        state,
        2,
        record,
        heading.line,
        `unexpected H2 "## ${heading.text} {#${heading.explicitId}}"; ${template} pages have exactly: ${expectedHeadings.h2.map(item => `## ${item.text} {#${item.id}}`).join(', ')}`
      );
      continue;
    }
    if (seen.has(entry.id)) {
      report(
        state,
        2,
        record,
        heading.line,
        `"## ${entry.text} {#${entry.id}}" appears twice`
      );
      continue;
    }
    seen.set(entry.id, heading);
    if (heading.text !== entry.text) {
      report(
        state,
        2,
        record,
        heading.line,
        `H2 {#${entry.id}} must read "## ${entry.text} {#${entry.id}}"`
      );
    }
    const position = templateIds.indexOf(entry.id);
    if (position < lastPosition) {
      report(
        state,
        2,
        record,
        heading.line,
        `"## ${entry.text}" must come before "## ${lastHeading.text}" (template order: ${expectedHeadings.h2.map(item => item.text).join(' → ')})`
      );
    } else {
      lastPosition = position;
      lastHeading = entry;
    }
  }

  for (const [position, entry] of expectedHeadings.h2.entries()) {
    if (seen.has(entry.id)) continue;
    const following = expectedHeadings.h2
      .slice(position + 1)
      .map(item => seen.get(item.id))
      .find(Boolean);
    report(
      state,
      2,
      record,
      following ? following.line : doc.lines.length,
      `missing "## ${entry.text} {#${entry.id}}"${following ? ' before this heading' : ''}`
    );
  }

  const h3s = doc.headings.filter(heading => heading.level === 3);
  const seenH3 = new Map();
  for (const heading of h3s) {
    const parent = [...h2s]
      .reverse()
      .find(candidate => candidate.index < heading.index);
    const entry = expectedHeadings.h3.find(
      candidate => candidate.id === heading.explicitId
    );
    if (!entry) {
      const allowed = expectedHeadings.h3.length
        ? `allowed here: ${expectedHeadings.h3.map(item => `### ${item.text} {#${item.id}}`).join(', ')}`
        : `${template} pages${interfaceName ? ` for ${interfaceName}` : ''} have no H3s`;
      report(
        state,
        2,
        record,
        heading.line,
        `H3 "### ${heading.text}${heading.explicitId ? ` {#${heading.explicitId}}` : ''}" is not in the template; ${allowed}`
      );
      continue;
    }
    if (seenH3.has(entry.id)) {
      report(
        state,
        2,
        record,
        heading.line,
        `"### ${entry.text} {#${entry.id}}" appears twice`
      );
      continue;
    }
    seenH3.set(entry.id, heading);
    if (heading.text !== entry.text) {
      report(
        state,
        2,
        record,
        heading.line,
        `H3 {#${entry.id}} must read "### ${entry.text} {#${entry.id}}"`
      );
    }
    if (parent?.explicitId !== entry.under) {
      const underText = expectedHeadings.h2.find(
        item => item.id === entry.under
      )?.text;
      report(
        state,
        2,
        record,
        heading.line,
        `"### ${entry.text}" belongs under "## ${underText} {#${entry.under}}"`
      );
    }
  }

  let previousH3 = null;
  for (const entry of expectedHeadings.h3) {
    const heading = seenH3.get(entry.id);
    if (!heading) {
      const parent = seen.get(entry.under);
      report(
        state,
        2,
        record,
        parent ? parent.line : doc.lines.length,
        `missing "### ${entry.text} {#${entry.id}}" under "## ${expectedHeadings.h2.find(item => item.id === entry.under)?.text}"`
      );
      continue;
    }
    if (
      previousH3 &&
      previousH3.entry.under === entry.under &&
      heading.index < previousH3.heading.index
    ) {
      report(
        state,
        2,
        record,
        heading.line,
        `"### ${entry.text}" must come after "### ${previousH3.entry.text}"`
      );
    }
    previousH3 = { entry, heading };
  }

  const ranges = sectionRanges(doc);
  for (const requirement of requiredIncludes(
    template,
    contextName,
    interfaceName
  )) {
    const range = ranges.get(requirement.section);
    if (!range) continue;
    const wanted = resolveIncludePath(
      requirement.include ?? requirement.snippet,
      record.abs,
      state.websiteDir
    );
    const sectionName =
      requirement.section === 'lead'
        ? 'the lead (between the H1 and the first H2)'
        : `"${'#'.repeat(range.heading.level)} ${range.heading.text}"`;
    const inRange = item => item.index > range.start && item.index < range.end;

    if (requirement.snippet) {
      const found = doc.snippets.some(
        snippet =>
          inRange(snippet) &&
          resolve(snippetTarget(state, record, snippet).file) ===
            resolve(wanted)
      );
      if (!found) {
        report(
          state,
          2,
          record,
          range.heading?.line ?? doc.bodyStart + 1,
          `${sectionName} must import the whole context class: <<< ${requirement.snippet}`
        );
      }
      continue;
    }

    const match = doc.includes.find(include => {
      if (!inRange(include)) return false;
      const target = includeTarget(state, record, include);
      return (
        resolve(target.abs) === resolve(wanted) &&
        (target.region ?? null) === (requirement.region ?? null)
      );
    });
    const spec = `${requirement.include}${requirement.region ? `#${requirement.region}` : ''}`;
    if (!match) {
      report(
        state,
        2,
        record,
        range.heading?.line ?? doc.bodyStart + 1,
        `${sectionName} must include <!--@include: ${spec}-->`
      );
      continue;
    }
    if (requirement.firstInCodeGroup) {
      let previous = match.index - 1;
      while (previous >= 0 && doc.kinds[previous] === 'blank') previous--;
      if (!/^\s*:::\s*code-group\b/.test(doc.lines[previous] ?? '')) {
        report(
          state,
          2,
          record,
          match.line,
          'the generated Skeleton must be the first tab: put it right after "::: code-group"'
        );
      }
    }
  }

  doc.lines.forEach((line, index) => {
    if (SCAFFOLD_PATTERN.test(line)) {
      report(
        state,
        2,
        record,
        index + 1,
        'unfilled scaffold placeholder; write the section and remove the marker'
      );
    }
  });
}

function checkTemplates(state) {
  for (const record of state.pages.values()) {
    checkHeadingIds(state, record);
    if (isTemplatePage(record)) {
      const expected = state.expectedByPath.get(record.rel);
      if (
        expected &&
        expected.template === record.template &&
        expected.context === record.contextName &&
        (expected.interface ?? null) === (record.interfaceName ?? null)
      ) {
        checkTemplatePage(state, record);
      }
    }
  }
}

function regionContextFit(state, record, target) {
  if (!isTemplatePage(record)) return;
  const partRel = toPosix(relative(state.partsDir, target.abs));

  const generatedRel = toPosix(relative(state.generatedDir, target.abs));
  if (!generatedRel.startsWith('..')) {
    const folder = generatedRel.split('/')[0];
    const owner = model.contexts.find(context => context.slug === folder);
    if (owner && owner.name !== record.contextName) {
      return `includes ${owner.name}'s generated partial on a ${record.contextName} page; use @/_parts/generated/${record.context.slug}/…`;
    }
  }

  if (target.region && REGION_MAP[partRel]) {
    const contexts = REGION_MAP[partRel][target.region];
    if (contexts && !contexts.includes(record.contextName)) {
      return `region #${target.region} of ${partRel} is written for ${contexts.join(', ')}, not ${record.contextName}`;
    }
  }
  return null;
}

function blankAround(doc, index) {
  const before = index - 1;
  const after = index + 1;
  const okBefore =
    before < doc.bodyStart ||
    doc.kinds[before] === 'blank' ||
    doc.kinds[before] === 'frontmatter';
  const okAfter = after >= doc.lines.length || doc.kinds[after] === 'blank';
  return okBefore && okAfter;
}

function checkRegionsOfPartials(state) {
  for (const record of state.handPartials.values()) {
    const scanned = scanRegions(record.doc.lines);
    for (const problem of scanned.problems) {
      report(state, 3, record, problem.line, problem.message);
    }
    const declared = [...scanned.regions.keys()];
    const mapped = REGION_MAP[record.partRel];
    if (!mapped) {
      if (declared.length > 0) {
        report(
          state,
          3,
          record,
          scanned.regions.get(declared[0]).startLine,
          `${record.partRel} declares regions (${declared.join(', ')}) but is not in the region map; add it to REGION_MAP in check-docs.mjs or drop the regions`
        );
      }
      continue;
    }
    const expectedNames = Object.keys(mapped);
    for (const name of expectedNames) {
      if (!scanned.regions.has(name)) {
        report(
          state,
          3,
          record,
          1,
          `region "${name}" from the region map is missing (write <!-- #region ${name} --> … <!-- #endregion ${name} -->)`
        );
      }
    }
    for (const name of declared) {
      if (!expectedNames.includes(name)) {
        report(
          state,
          3,
          record,
          scanned.regions.get(name).startLine,
          `region "${name}" is not in the region map for ${record.partRel} (${expectedNames.join(', ')})`
        );
      }
    }
  }
}

function checkIncludes(state) {
  if (!existsSync(state.generatedDir)) {
    report(
      state,
      3,
      display(state, state.generatedDir),
      null,
      'generated partials are missing: run node website/.vitepress/scripts/generate.mjs (docs:dev and docs:build run it when the config loads)'
    );
  }

  checkRegionsOfPartials(state);
  const regionCache = new Map();
  const regionsOf = abs => {
    if (!regionCache.has(abs)) {
      regionCache.set(
        abs,
        scanRegions(readFileSync(abs, 'utf8').split(/\r?\n/)).regions
      );
    }
    return regionCache.get(abs);
  };

  for (const record of allRecords(state)) {
    const doc = record.doc;

    for (const include of doc.includes) {
      state.counts.includes++;
      const target = includeTarget(state, record, include);
      const shown = `<!--@include: ${include.spec}-->`;

      if (!include.alone) {
        report(
          state,
          3,
          record,
          include.line,
          `${shown} must sit alone on its line (never in a table cell or a sentence); the llms plugin expands only whole-line includes`
        );
      } else if (!blankAround(doc, include.index)) {
        report(
          state,
          3,
          record,
          include.line,
          `${shown} needs a blank line above and below it`
        );
      }

      if (!existsSync(target.abs) || !statSync(target.abs).isFile()) {
        report(
          state,
          3,
          record,
          include.line,
          `include target not found: ${target.path} (VitePress would print the raw comment)`
        );
        continue;
      }

      if (target.range) {
        report(
          state,
          3,
          record,
          include.line,
          `line range ${target.range} drifts silently after an edit; include a named region instead`
        );
      }

      const partRel = toPosix(relative(state.partsDir, target.abs));
      const regions = regionsOf(target.abs);

      if (target.region) {
        const mapped = REGION_MAP[partRel];
        if (!mapped) {
          report(
            state,
            3,
            record,
            include.line,
            `${target.path} has no regions in the region map; include it whole`
          );
        } else if (!(target.region in mapped)) {
          report(
            state,
            3,
            record,
            include.line,
            `#${target.region} is not a region of ${partRel}; use one of ${Object.keys(mapped).join(', ')}`
          );
        } else if (!regions.has(target.region)) {
          report(
            state,
            3,
            record,
            include.line,
            `region #${target.region} is not in ${partRel} (VitePress would include the whole file)`
          );
        }
      } else if (regions.size > 0 && !target.range) {
        report(
          state,
          3,
          record,
          include.line,
          `${target.path} has regions (${[...regions.keys()].join(', ')}); include one region, never the whole file`
        );
      }

      const misfit = regionContextFit(state, record, target);
      if (misfit) report(state, 3, record, include.line, misfit);
    }

    for (const snippet of doc.snippets) {
      state.counts.snippets++;
      const target = snippetTarget(state, record, snippet);
      if (!blankAround(doc, snippet.index)) {
        report(
          state,
          3,
          record,
          snippet.line,
          `<<< ${snippet.raw} needs a blank line above and below it`
        );
      }
      if (target.region) {
        report(
          state,
          3,
          record,
          snippet.line,
          `<<< imports whole files only: remove #${target.region}`
        );
      }
      if (target.hasBraces) {
        report(
          state,
          3,
          record,
          snippet.line,
          '<<< takes no {…} braces: highlights drift after an edit, and .cls/.trigger already map to Apex'
        );
      }
      if (!existsSync(target.file) || !statSync(target.file).isFile()) {
        report(
          state,
          3,
          record,
          snippet.line,
          `<<< file not found: ${display(state, target.file)} (the build fails); import only classes that exist`
        );
      }
    }
  }
}

function checkPartials(state) {
  const partials = [
    ...state.handPartials.values(),
    ...state.generatedPartials.values()
  ];
  for (const record of partials) {
    const doc = record.doc;
    const exempt =
      record.kind === 'hand' && record.partRel === STALE_API_PARTIAL;

    for (const problem of doc.problems) {
      report(state, 4, record, problem.line, problem.message);
    }

    for (const heading of doc.headings) {
      report(
        state,
        4,
        record,
        heading.line,
        `partials contain no headings ("${'#'.repeat(heading.level)} ${heading.text}"); the page owns every H2 and H3`
      );
    }

    for (const link of doc.links) {
      if (EXTERNAL_PATTERN.test(link.url) || link.url.startsWith('/')) continue;
      report(
        state,
        4,
        record,
        link.line,
        `relative link "${link.url}" in a partial resolves against each including page; use an absolute path such as /${record.partRel.startsWith('generated/') ? '…' : 'guide/…'}`
      );
    }

    for (const include of doc.includes) {
      if (!include.spec.startsWith('@/')) {
        report(
          state,
          4,
          record,
          include.line,
          `include paths in partials start with @/ (found ${include.spec})`
        );
      }
    }

    for (const snippet of doc.snippets) {
      if (!snippet.raw.startsWith('@/')) {
        report(
          state,
          4,
          record,
          snippet.line,
          `<<< paths in partials start with @/ (found ${snippet.raw})`
        );
      }
    }

    if (record.kind !== 'hand' || exempt) continue;

    doc.lines.forEach((line, index) => {
      if (index < doc.bodyStart || doc.allowed.has(index)) return;
      const kind = doc.kinds[index];
      if (kind === 'include' || kind === 'comment') return;
      const scanned = line.replace(/\]\([^)]*\)/g, ']()');
      for (const match of scanned.matchAll(METHOD_TOKEN_PATTERN)) {
        report(
          state,
          4,
          record,
          index + 1,
          `context-specific method name "${match[0]}" in a shared partial; use a placeholder (bypassOn<Ctx>When(), <ctx>Handlers()) or move the sentence to the page`
        );
      }
    });
  }
}

function checkMethodTokens(state) {
  for (const record of state.pages.values()) {
    const doc = record.doc;
    const flag = (text, line) => {
      for (const problem of methodTokenProblems(text, state.methodNames)) {
        report(
          state,
          5,
          record,
          line,
          `"${problem.token}" is not a method in the Apex classes${problem.suggestion ? `; did you mean "${problem.suggestion}"?` : ''}`
        );
      }
    };

    for (const fence of doc.fences) {
      fence.content.forEach((line, offset) => {
        const index = fence.start + 1 + offset;
        if (!doc.allowed.has(index)) flag(line, index + 1);
      });
    }
    for (const code of doc.inlineCode) {
      if (!doc.allowed.has(code.index)) flag(code.code, code.line);
    }
  }
}

function checkStaleApi(state) {
  const records = [
    ...state.pages.values(),
    ...[...state.handPartials.values()].filter(
      record => record.partRel !== STALE_API_PARTIAL
    )
  ];

  for (const record of records) {
    const doc = record.doc;
    const testingPage = record.kind === 'page' && record.rel === TESTING_PAGE;

    for (const fence of doc.fences) {
      if (doc.allowed.has(fence.start)) continue;
      for (const problem of staleFenceProblems(fence.content.join('\n'), {
        testingPage
      })) {
        const index = fence.start + 1 + problem.offset;
        if (doc.allowed.has(index)) continue;
        report(
          state,
          6,
          record,
          index + 1,
          `stale API "${problem.text}": ${problem.message}`
        );
      }
    }

    for (const paragraph of doc.paragraphs) {
      if (doc.allowed.has(paragraph.start)) continue;
      const text = paragraph.lines.join(' ');
      for (const problem of staleProseProblems(text)) {
        const offset = paragraph.lines.findIndex(line =>
          line.includes(problem.text.split(/\s+/)[0])
        );
        report(
          state,
          6,
          record,
          paragraph.start + 1 + Math.max(0, offset),
          `stale claim "${problem.text.length > 90 ? `${problem.text.slice(0, 87)}…` : problem.text}": ${problem.message} (quote it on purpose with ${ALLOW_MARKER} on the line above)`
        );
      }
    }
  }
}

function isAssetPath(path) {
  const last = path.split('/').pop();
  const extension = last.includes('.') ? last.split('.').pop() : '';
  return extension !== '' && extension !== 'md' && extension !== 'html';
}

export function resolveUrl(state, url, fromRel) {
  const hashIndex = url.indexOf('#');
  const hash =
    hashIndex >= 0 ? decodeURIComponent(url.slice(hashIndex + 1)) : null;
  let path = (hashIndex >= 0 ? url.slice(0, hashIndex) : url).replace(
    /\?.*$/,
    ''
  );

  if (path === '') {
    return fromRel
      ? { file: fromRel, exists: state.pages.has(fromRel), hash, path: '' }
      : { relative: true };
  }
  if (!path.startsWith('/')) {
    if (!fromRel) return { relative: true };
    path = posix.join('/', posix.dirname(fromRel), path);
  }
  if (isAssetPath(path)) return { asset: true };

  path = path.replace(/\.(md|html)$/, '');
  const key = decodeURIComponent(
    (path.endsWith('/') ? `${path}index` : path).slice(1)
  );
  const file = `${key}.md`;
  return {
    file,
    exists: state.pages.has(file),
    hash,
    path,
    folderIndex:
      !path.endsWith('/') && state.pages.has(`${key}/index.md`)
        ? `${path}/`
        : null
  };
}

function idsOf(state, rel) {
  if (!state.ids.has(rel)) {
    const record = state.pages.get(rel);
    const expanded = expandIncludes(
      record.source,
      record.abs,
      state.websiteDir
    );
    state.ids.set(rel, collectIds(parseMarkdown(expanded)));
  }
  return state.ids.get(rel);
}

function missingHint(state, resolved) {
  if (resolved.folderIndex)
    return `; a folder index needs the trailing slash: ${resolved.folderIndex}`;
  const parts = resolved.path.split('/').filter(Boolean);
  if (parts.length === 2) {
    const context = model.contexts.find(entry => entry.slug === parts[0]);
    const addOn = context?.interfaces.find(
      item => item.kind === 'addOn' && item.slug === parts[1]
    );
    if (addOn)
      return `; add-ons live under /${parts[0]}/add-ons/: ${addOn.link}`;
  }
  return '';
}

function linkProblem(state, url, fromRel) {
  const resolved = resolveUrl(state, url, fromRel);
  if (resolved.relative || resolved.asset) return null;
  if (!resolved.exists) {
    if (state.expectedByPath.get(resolved.file)?.template) {
      state.suppressed++;
      return null;
    }
    return {
      rule: 8,
      text: `link target not found: ${url}${missingHint(state, resolved)}`
    };
  }
  if (resolved.hash === null) return null;
  const ids = idsOf(state, resolved.file);
  if (ids.has(resolved.hash)) return null;
  const target = state.pages.get(resolved.file);
  if (isTemplatePage(target)) {
    const covered = templateHeadings(
      target.template,
      target.contextName,
      target.interfaceName
    );
    if (
      [...covered.h2, ...covered.h3].some(entry => entry.id === resolved.hash)
    ) {
      state.suppressed++;
      return null;
    }
  }
  const known = [...ids].slice(0, 12).join(', ');
  return {
    rule: 7,
    text: `anchor #${resolved.hash} not found on ${pageUrl(resolved.file)}${known ? ` (ids there: ${known}${ids.size > 12 ? ', …' : ''})` : ''}`
  };
}

function checkLinks(state) {
  for (const record of allRecords(state)) {
    for (const link of record.doc.links) {
      if (EXTERNAL_PATTERN.test(link.url)) continue;
      state.counts.links++;
      const fromRel = record.kind === 'page' ? record.rel : null;
      if (!fromRel && !link.url.startsWith('/')) continue;
      const problem = linkProblem(state, link.url, fromRel);
      if (!problem) continue;
      const rule = problem.rule === 8 ? 7 : problem.rule;
      if (record.kind === 'generated') {
        aggregate(
          state,
          rule,
          record,
          link.line,
          `${rule}|${problem.text}`,
          problem.text
        );
      } else {
        report(state, rule, record, link.line, problem.text);
      }
    }
  }

  checkHowDoIMap(state);
}

export function normalizeQuestion(text) {
  return text.replace(/`/g, '').replace(/\s+/g, ' ').trim().toLowerCase();
}

function headingRange(doc, heading) {
  const position = doc.headings.indexOf(heading);
  const next = doc.headings
    .slice(position + 1)
    .find(candidate => candidate.level <= heading.level);
  return { start: heading.index, end: next ? next.index : doc.lines.length };
}

function navigableFiles(state) {
  if (!state.navigable) {
    state.navigable = new Set();
    for (const entry of [
      ...sidebarLinks(state.sidebar),
      ...sidebarLinks(state.nav)
    ]) {
      if (EXTERNAL_PATTERN.test(entry.link)) continue;
      const resolved = resolveUrl(state, entry.link, null);
      if (resolved.file) state.navigable.add(resolved.file);
    }
  }
  return state.navigable;
}

function checkHowDoITargets(state) {
  const mapFile = display(state, state.checkerFile);
  const seen = new Set();

  for (const row of HOW_DO_I_MAP) {
    for (const target of row.targets) {
      if (seen.has(target)) continue;
      seen.add(target);

      if (target.startsWith('chips:')) {
        const [kind, anchor] = target.slice('chips:'.length).split('#');
        if (
          !existsSync(join(state.generatedDir, 'chips', kind, `${anchor}.md`))
        ) {
          report(
            state,
            7,
            mapFile,
            null,
            `HOW_DO_I_MAP row "${row.question}" names chips ${kind}#${anchor}, which generate.mjs does not produce`
          );
        }
        continue;
      }

      const resolved = resolveUrl(state, target, null);
      if (!resolved.exists) {
        if (
          state.expectedByPath.get(resolved.file)?.template ||
          navigableFiles(state).has(resolved.file)
        ) {
          state.suppressed++;
          continue;
        }
        report(
          state,
          7,
          display(state, join(state.websiteDir, resolved.file)),
          null,
          `missing page: the /how-do-i question "${row.question}" links to ${target}${missingHint(state, resolved)}`
        );
        continue;
      }
      if (resolved.hash === null) continue;
      const problem = linkProblem(state, target, null);
      if (problem) {
        report(
          state,
          7,
          state.pages.get(resolved.file),
          null,
          `the /how-do-i question "${row.question}" links to #${resolved.hash}; add a heading with {#${resolved.hash}} (${problem.text})`
        );
      }
    }
  }
}

function checkHowDoIMap(state) {
  checkHowDoITargets(state);
  const record = state.pages.get(HOW_DO_I_PAGE);
  if (!record) return;
  const doc = record.doc;
  const h2s = doc.headings.filter(heading => heading.level === 2);
  const h3s = doc.headings.filter(heading => heading.level === 3);
  const byQuestion = new Map(
    h3s.map(heading => [normalizeQuestion(heading.text), heading])
  );
  const mapped = new Set();

  for (const row of HOW_DO_I_MAP) {
    const heading = byQuestion.get(normalizeQuestion(row.question));
    const group = h2s.find(
      candidate =>
        normalizeQuestion(candidate.text) === normalizeQuestion(row.group)
    );
    if (!heading) {
      report(
        state,
        7,
        record,
        group ? group.line : null,
        `missing H3 "### ${row.question}" under "## ${row.group}" (question map row)`
      );
      continue;
    }
    mapped.add(heading);
    const parent = [...h2s]
      .reverse()
      .find(candidate => candidate.index < heading.index);
    if (
      !parent ||
      normalizeQuestion(parent.text) !== normalizeQuestion(row.group)
    ) {
      report(
        state,
        7,
        record,
        heading.line,
        `"### ${heading.text}" belongs under "## ${row.group}"`
      );
    }

    const range = headingRange(doc, heading);
    const inRange = item => item.index > range.start && item.index < range.end;

    for (const target of row.targets) {
      if (target.startsWith('chips:')) {
        const [kind, anchor] = target.slice('chips:'.length).split('#');
        const chip = join(state.generatedDir, 'chips', kind, `${anchor}.md`);
        const found = doc.includes.some(include => {
          if (!inRange(include)) return false;
          const resolved = includeTarget(state, record, include);
          return resolve(resolved.abs) === resolve(chip) && !resolved.region;
        });
        if (!found) {
          report(
            state,
            7,
            record,
            heading.line,
            `"### ${heading.text}" must include <!--@include: @/_parts/generated/chips/${kind}/${anchor}.md-->`
          );
        }
        continue;
      }

      const wanted = resolveUrl(state, target, null);
      const found = doc.links.some(link => {
        if (!inRange(link)) return false;
        const resolved = resolveUrl(state, link.url, record.rel);
        return (
          resolved.file === wanted.file &&
          (resolved.hash ?? null) === (wanted.hash ?? null)
        );
      });
      if (!found) {
        report(
          state,
          7,
          record,
          heading.line,
          `"### ${heading.text}" must link to ${target}`
        );
      }
    }
  }

  for (const heading of h3s) {
    if (!mapped.has(heading)) {
      report(
        state,
        7,
        record,
        heading.line,
        `"### ${heading.text}" is not in the question map; add the row to HOW_DO_I_MAP in check-docs.mjs or remove the H3`
      );
    }
  }
}

function sidebarLinks(items, trail = [], found = []) {
  if (!items) return found;
  if (!Array.isArray(items)) {
    for (const [base, value] of Object.entries(items)) {
      sidebarLinks(
        Array.isArray(value) ? value : value.items,
        [...trail, base],
        found
      );
    }
    return found;
  }
  for (const item of items) {
    const here = [...trail, item.text ?? '(untitled)'];
    if (item.link) found.push({ link: item.link, trail: here });
    if (item.items) sidebarLinks(item.items, here, found);
  }
  return found;
}

function vercelLine(text, value) {
  const index = text.indexOf(JSON.stringify(value));
  return index === -1 ? null : text.slice(0, index).split('\n').length;
}

function checkNavigation(state) {
  const reachable = new Set();
  const sidebarFile = display(state, state.sidebarFile);
  const sources = [
    ...sidebarLinks(state.sidebar).map(entry => ({
      ...entry,
      where: 'Sidebar'
    })),
    ...sidebarLinks(state.nav).map(entry => ({ ...entry, where: 'Nav' }))
  ];

  for (const entry of sources) {
    if (EXTERNAL_PATTERN.test(entry.link)) continue;
    const resolved = resolveUrl(state, entry.link, null);
    if (resolved.asset || resolved.relative) continue;
    if (resolved.exists) reachable.add(resolved.file);
    const problem = linkProblem(state, entry.link, null);
    if (problem) {
      report(
        state,
        problem.rule,
        sidebarFile,
        null,
        `${entry.where} › ${entry.trail.join(' › ')}: ${problem.text}`
      );
    }
  }

  for (const record of state.pages.values()) {
    for (const link of record.doc.frontmatterLinks) {
      if (EXTERNAL_PATTERN.test(link.url)) continue;
      const problem = linkProblem(state, link.url, record.rel);
      if (problem) {
        report(
          state,
          problem.rule,
          record,
          link.line,
          `frontmatter link: ${problem.text}`
        );
      }
    }
  }

  for (const record of state.pages.values()) {
    if (record.rel === 'index.md' || reachable.has(record.rel)) continue;
    report(
      state,
      8,
      record,
      1,
      `${record.url} is not in the sidebar or nav; add it to the sidebar in apex-api.mjs, or delete it and add a 301 in vercel.json`
    );
  }

  if (!existsSync(state.vercelPath)) return;
  const vercelFile = display(state, state.vercelPath);
  const text = readFileSync(state.vercelPath, 'utf8');
  let config;
  try {
    config = JSON.parse(text);
  } catch (error) {
    report(state, 8, vercelFile, null, `invalid JSON: ${error.message}`);
    return;
  }
  const sourcesSeen = new Map();
  for (const redirect of config.redirects ?? []) {
    const line = vercelLine(text, redirect.source) ?? null;
    if (
      typeof redirect.source !== 'string' ||
      typeof redirect.destination !== 'string'
    ) {
      report(
        state,
        8,
        vercelFile,
        line,
        'a redirect needs a source and a destination'
      );
      continue;
    }
    if (sourcesSeen.has(redirect.source)) {
      report(
        state,
        8,
        vercelFile,
        line,
        `redirect source ${redirect.source} is listed twice`
      );
    }
    sourcesSeen.set(redirect.source, true);
    if ('permanent' in redirect) {
      report(
        state,
        8,
        vercelFile,
        line,
        `${redirect.source}: drop "permanent" (Vercel answers 308) and set "statusCode": 301`
      );
    }
    if (redirect.statusCode !== 301) {
      report(
        state,
        8,
        vercelFile,
        line,
        `${redirect.source}: set "statusCode": 301`
      );
    }
    if (!/[:(*]/.test(redirect.source)) {
      const source = resolveUrl(state, redirect.source, null);
      if (source.exists) {
        report(
          state,
          8,
          vercelFile,
          line,
          `redirect source ${redirect.source} is an existing page (${display(state, join(state.websiteDir, source.file))}); Vercel would hide it`
        );
      }
    }
    if (
      EXTERNAL_PATTERN.test(redirect.destination) ||
      /[:(*]/.test(redirect.destination)
    )
      continue;
    const problem = linkProblem(state, redirect.destination, null);
    if (problem) {
      report(
        state,
        problem.rule,
        vercelFile,
        vercelLine(text, redirect.destination) ?? line,
        `redirect ${redirect.source} → ${problem.text}`
      );
    }
  }
}

function wordsOf(text) {
  return text
    .replace(/<!--[\s\S]*?-->/g, ' ')
    .replace(/!?\[([^\]]*)\]\([^)]*\)/g, '$1')
    .split(/\s+/)
    .filter(word => /[A-Za-z0-9]/.test(word));
}

function isLinkOnly(line) {
  return (
    line
      .replace(/!?\[[^\]]*\]\([^)]*\)/g, '')
      .replace(/[·|,;:.\-–—\s]/g, '') === ''
  );
}

function checkRouters(state) {
  for (const rel of ROUTER_PAGES) {
    const record = state.pages.get(rel);
    if (!record) continue;
    const expanded = parseMarkdown(
      expandIncludes(record.source, record.abs, state.websiteDir)
    );
    if (record.doc.fences.length > 0) {
      for (const fence of record.doc.fences) {
        report(
          state,
          9,
          record,
          fence.startLine,
          `${record.url} is a router page: no code fences; put the code on the target page`
        );
      }
    } else if (expanded.fences.length > 0) {
      report(
        state,
        9,
        record,
        1,
        `${record.url} is a router page, but an included partial adds a code fence`
      );
    }
    for (const snippet of record.doc.snippets) {
      report(
        state,
        9,
        record,
        snippet.line,
        `${record.url} is a router page: no <<< imports`
      );
    }
  }

  const contexts = state.pages.get(CONTEXTS_PAGE);
  if (contexts) {
    const ranges = sectionRanges(contexts.doc);
    for (const section of CONTEXTS_PAGE_SECTIONS) {
      const range = ranges.get(section.id);
      const heading = range?.heading;
      if (!heading || heading.level !== 2) {
        report(
          state,
          9,
          contexts,
          null,
          `/contexts needs an H2 with {#${section.id}} (redirects and cross-links point at it)`
        );
        continue;
      }
      if (!section.include) continue;
      const wanted = resolveIncludePath(
        section.include,
        contexts.abs,
        state.websiteDir
      );
      const found = contexts.doc.includes.some(
        include =>
          include.index > range.start &&
          include.index < range.end &&
          resolve(includeTarget(state, contexts, include).abs) ===
            resolve(wanted)
      );
      if (!found) {
        report(
          state,
          9,
          contexts,
          heading.line,
          `"## ${heading.text}" must include <!--@include: ${section.include}-->`
        );
      }
    }
  }

  const howDoI = state.pages.get(HOW_DO_I_PAGE);
  if (!howDoI) return;
  const doc = howDoI.doc;
  for (const heading of doc.headings.filter(item => item.level === 3)) {
    const range = headingRange(doc, heading);
    const answer = [];
    for (let index = range.start + 1; index < range.end; index++) {
      const kind = doc.kinds[index];
      if (kind !== 'text' && kind !== 'table') continue;
      if (isLinkOnly(doc.lines[index])) continue;
      answer.push(doc.lines[index]);
    }
    const words = wordsOf(answer.join(' '));
    if (words.length === 0) {
      report(
        state,
        9,
        howDoI,
        heading.line,
        `"### ${heading.text}" needs a one-line answer (${MAX_ANSWER_WORDS} words or fewer)`
      );
    } else if (words.length > MAX_ANSWER_WORDS) {
      report(
        state,
        9,
        howDoI,
        heading.line,
        `the answer to "### ${heading.text}" has ${words.length} words; keep it to ${MAX_ANSWER_WORDS} and move the detail to the target page`
      );
    }
  }
}

function lineInFacts(state, contextName, role) {
  if (!existsSync(state.factsFile)) return null;
  const lines = readFileSync(state.factsFile, 'utf8').split('\n');
  const tableStart = lines.findIndex(line =>
    line.startsWith('export const honourTable')
  );
  if (tableStart === -1) return null;
  const contextLine = lines.findIndex(
    (line, index) =>
      index > tableStart && line.trim().startsWith(`${contextName}: {`)
  );
  if (contextLine === -1) return tableStart + 1;
  const roleLine = lines.findIndex(
    (line, index) => index > contextLine && line.trim().startsWith(`${role}: {`)
  );
  return (roleLine === -1 ? contextLine : roleLine) + 1;
}

function checkHonours(state) {
  const actual = parseAdapterHonours();
  const factsFile = display(state, state.factsFile);

  for (const context of model.contexts) {
    for (const role of context.roles) {
      const found = actual[context.name]?.[role] ?? [];
      const listed = state.honourTable[context.name]?.[role]?.honours;
      const line = lineInFacts(state, context.name, role);
      if (!listed) {
        report(
          state,
          10,
          factsFile,
          line,
          `honourTable.${context.name}.${role} is missing; the ${context.name}${role}Adapter honours ${found.join(', ') || 'nothing'}`
        );
        continue;
      }
      for (const addOn of found.filter(name => !listed.includes(name))) {
        report(
          state,
          10,
          factsFile,
          line,
          `honourTable.${context.name}.${role} leaves out ${addOn}, but ${context.name}${role}Adapter (or a helper it builds) checks instanceof ${context.name}.${addOn}`
        );
      }
      for (const addOn of listed.filter(name => !found.includes(name))) {
        report(
          state,
          10,
          factsFile,
          line,
          `honourTable.${context.name}.${role} lists ${addOn}, but ${context.name}${role}Adapter never checks instanceof ${context.name}.${addOn}; Works With would claim an add-on the adapter ignores`
        );
      }
    }
  }
}

function flushAggregated(state) {
  for (const entry of state.aggregated.values()) {
    state.errors.push({
      rule: entry.rule,
      file: entry.file,
      line: entry.line,
      message:
        entry.count > 1
          ? `${entry.message} (and ${entry.count - 1} more in generated partials)`
          : entry.message
    });
  }
}

export function check(options = {}) {
  const state = createState(options);
  const rules = new Set(
    (options.rules ?? Object.keys(RULES)).map(rule => Number(rule))
  );

  loadFiles(state);

  const runners = {
    1: checkPages,
    2: checkTemplates,
    3: checkIncludes,
    4: checkPartials,
    5: checkMethodTokens,
    6: checkStaleApi,
    7: checkLinks,
    8: checkNavigation,
    9: checkRouters,
    10: checkHonours
  };
  for (const [rule, runner] of Object.entries(runners)) {
    if (rules.has(Number(rule)) || (Number(rule) === 8 && rules.has(7)))
      runner(state);
  }
  flushAggregated(state);

  let errors = state.errors.filter(error => rules.has(error.rule));
  const only = (options.only ?? []).map(prefix => prefix.replace(/^\.\//, ''));
  if (only.length > 0) {
    errors = errors.filter(error =>
      only.some(
        prefix =>
          error.file.startsWith(prefix) ||
          error.file.startsWith(`website/${prefix}`)
      )
    );
  }
  errors.sort(
    (left, right) =>
      left.file.localeCompare(right.file) ||
      (left.line ?? 0) - (right.line ?? 0) ||
      left.rule - right.rule
  );

  return {
    errors,
    stats: {
      pages: state.pages.size,
      handPartials: state.handPartials.size,
      generatedPartials: state.generatedPartials.size,
      links: state.counts.links,
      includes: state.counts.includes,
      snippets: state.counts.snippets,
      coveredElsewhere: state.suppressed,
      rules: [...rules].sort((left, right) => left - right)
    }
  };
}

export function formatReport(result, { summaryOnly = false } = {}) {
  const lines = [];
  if (!summaryOnly) {
    for (const error of result.errors) {
      lines.push(
        `${error.file}${error.line ? `:${error.line}` : ''}: [rule ${error.rule} ${RULES[error.rule]}] ${error.message}`
      );
    }
    if (result.errors.length > 0) lines.push('');
  }

  const byRule = new Map();
  for (const error of result.errors)
    byRule.set(error.rule, (byRule.get(error.rule) ?? 0) + 1);
  const files = new Set(result.errors.map(error => error.file)).size;
  const { stats } = result;

  lines.push(
    `check-docs: ${stats.pages} pages, ${stats.handPartials} hand partials, ${stats.generatedPartials} generated partials, ${stats.links} links, ${stats.includes} includes, ${stats.snippets} <<< imports`
  );
  for (const rule of stats.rules) {
    const count = byRule.get(rule) ?? 0;
    lines.push(
      `  rule ${String(rule).padEnd(2)} ${RULES[rule].padEnd(28)} ${count === 0 ? 'ok' : `${count} problem${count === 1 ? '' : 's'}`}`
    );
  }
  lines.push(
    result.errors.length === 0
      ? 'check-docs: passed'
      : `check-docs: ${result.errors.length} problem${result.errors.length === 1 ? '' : 's'} in ${files} file${files === 1 ? '' : 's'}`
  );
  return lines.join('\n');
}

function parseArguments(argv) {
  const options = { only: [], rules: null, summaryOnly: false, json: false };
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index];
    if (argument === '--only') options.only.push(argv[++index]);
    else if (argument.startsWith('--only='))
      options.only.push(argument.slice('--only='.length));
    else if (argument === '--rules') options.rules = argv[++index].split(',');
    else if (argument.startsWith('--rules='))
      options.rules = argument.slice('--rules='.length).split(',');
    else if (argument === '--summary') options.summaryOnly = true;
    else if (argument === '--json') options.json = true;
    else if (argument === '--help' || argument === '-h') options.help = true;
    else throw new Error(`check-docs: unknown argument ${argument}`);
  }
  return options;
}

const USAGE = `Usage: node website/.vitepress/scripts/check-docs.mjs [--only <path-prefix>]... [--rules 1,2,…] [--summary] [--json]

  --only     report only files under this prefix (for example website/before-insert/)
  --rules    run only these rules (${Object.entries(RULES)
    .map(([rule, name]) => `${rule} ${name}`)
    .join('; ')})
  --summary  print the per-rule counts only
  --json     print the problems as JSON

Put ${ALLOW_MARKER} on the line above a paragraph or code block to exempt it from rules 4 to 6.
Exits with 1 when any problem is found.`;

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  const options = parseArguments(process.argv.slice(2));
  if (options.help) {
    console.log(USAGE);
  } else {
    const result = check(options);
    if (options.json) console.log(JSON.stringify(result, null, 2));
    else console.log(formatReport(result, options));
    process.exitCode = result.errors.length > 0 ? 1 : 0;
  }
}
