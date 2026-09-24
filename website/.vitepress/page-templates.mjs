export const templates = {
  context: {
    lead: true,
    h2: [
      { text: 'Roles', id: 'roles' },
      { text: 'Register', id: 'register' },
      { text: 'Rules', id: 'rules' }
    ],
    h2ByInterface: {},
    h3ByContext: {},
    h3ByInterface: {},
    maxAdmonitions: 1
  },
  role: {
    lead: true,
    h2: [
      { text: 'Rules', id: 'rules' },
      { text: 'Test', id: 'test' }
    ],
    h2ByInterface: {},
    h3ByContext: {},
    h3ByInterface: {},
    maxAdmonitions: 1
  },
  'add-ons': {
    lead: true,
    h2: [{ text: 'Available', id: 'available' }],
    h2ByInterface: {},
    h3ByContext: {},
    h3ByInterface: {},
    maxAdmonitions: 0
  },
  'add-on': {
    lead: true,
    h2: [{ text: 'Rules', id: 'rules' }],
    h2ByInterface: {
      RelatedQuery: [{ text: 'RecordsProvider', id: 'records-provider' }]
    },
    h3ByContext: {},
    h3ByInterface: {},
    maxAdmonitions: 1
  },
  'record-api': {
    lead: false,
    h2: [
      { text: 'Record', id: 'record' },
      { text: 'Records', id: 'records' },
      { text: 'Rules', id: 'rules' }
    ],
    h2ByInterface: {},
    h3ByContext: {},
    h3ByInterface: {},
    maxAdmonitions: 0
  }
};

export const retiredHeadings = {
  h2: {
    interface:
      'replace it with the label **Signature** (no heading) right above the signature include',
    example:
      'replace it with the label **Example** (no heading) right above "::: code-group"',
    'good-to-know': 'rename it to "## Rules {#rules}"'
  },
  h3: {
    'records-provider':
      'make it "## RecordsProvider {#records-provider}" with the label **Signature** above its include, and move it below the Example code-group'
  }
};

export const leadPatterns = {
  Populator: 'Set fields on {…} before they are saved.',
  Validator:
    'Reject {…} before {…} saved, like a validation rule written in Apex.',
  Writer:
    'Change other records or publish platform events after the {…}, through a unit of work.',
  Dispatcher:
    'Make one bulk call per chunk with the records that qualify, such as enqueueing a Queueable or publishing events.',
  Handler:
    'Check each record before it is deleted, then block the delete or clean up the records that point at it.',
  ParentQuery:
    'Read fields of the record a lookup points to, such as {…}, without SOQL in your handler.',
  PriorParentQuery:
    'Read fields of the parent the old row pointed to, such as {…}, without SOQL in your handler.',
  RelatedQuery:
    'Query children, siblings or other records once per chunk, and read them per record with `record.getRelated(name)`.',
  OwnUnitOfWork:
    'Give a Writer its own DML Lib unit of work, for user mode, sharing, partial success or your own statement order.',
  Bypassable:
    'Skip a handler for the whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.',
  RecursionGuard:
    'Cap how many times a {…} acts on the same record in one transaction (default 3).',
  Finalizer:
    'Run code once per chunk with the records that qualified, such as {…}.',
  ContinueOnError:
    "Log and swallow the handler's exceptions, so later handlers still run and the {…} goes on."
};

export const ADMONITION_TYPES = ['tip', 'warning', 'info'];
export const ADMONITION_MAX_SENTENCES = 3;
export const LABELS = { signature: 'Signature', example: 'Example' };
export const RULES_MAX_BULLETS = 5;
export const TEST_MAX_LINES = 15;

export function headingText(entry, contextName) {
  return entry.text.replace('<Ctx>', contextName ?? '<Ctx>');
}

export function leadRegExp(pattern) {
  const source = pattern
    .split('{…}')
    .map(part => part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
    .join('(?:(?![.!?](?:\\s|$)).)+?');
  return new RegExp(`^${source}$`);
}
