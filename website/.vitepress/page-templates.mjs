export const templates = {
  context: {
    lead: true,
    h2: [
      { text: 'Roles', id: 'roles' },
      { text: 'Add-ons', id: 'add-ons' },
      { text: 'Register', id: 'register' },
      { text: 'Good to Know', id: 'good-to-know' }
    ],
    h3ByContext: {},
    h3ByInterface: {}
  },
  role: {
    lead: true,
    h2: [
      { text: 'Interface', id: 'interface' },
      { text: 'Example', id: 'example' },
      { text: 'Good to Know', id: 'good-to-know' },
      { text: 'Test', id: 'test' }
    ],
    h3ByContext: {},
    h3ByInterface: {}
  },
  'add-ons': {
    lead: true,
    h2: [{ text: 'Available', id: 'available' }],
    h3ByContext: {},
    h3ByInterface: {}
  },
  'add-on': {
    lead: true,
    h2: [
      { text: 'Interface', id: 'interface' },
      { text: 'Example', id: 'example' },
      { text: 'Good to Know', id: 'good-to-know' }
    ],
    h3ByContext: {},
    h3ByInterface: {
      RelatedQuery: [
        { text: 'RecordsProvider', id: 'records-provider', under: 'interface' }
      ]
    }
  },
  'record-api': {
    lead: false,
    h2: [
      { text: 'Record', id: 'record' },
      { text: 'Records', id: 'records' },
      { text: 'Good to Know', id: 'good-to-know' }
    ],
    h3ByContext: {},
    h3ByInterface: {}
  }
};

export const GOOD_TO_KNOW_MAX_BULLETS = 5;
export const TEST_MAX_LINES = 15;

export function headingText(entry, contextName) {
  return entry.text.replace('<Ctx>', contextName ?? '<Ctx>');
}
