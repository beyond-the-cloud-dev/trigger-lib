export const templates = {
  context: {
    h2: [
      { text: 'At a Glance', id: 'at-a-glance' },
      { text: 'Pick a Role', id: 'pick-a-role' },
      { text: 'Add-ons', id: 'add-ons' },
      { text: 'Records', id: 'records' },
      { text: 'Register', id: 'register' },
      { text: 'How <Ctx> Runs', id: 'how-it-runs' },
      { text: 'Switching Handlers Off', id: 'switching-off' },
      { text: 'Gotchas', id: 'gotchas' },
      { text: 'Not Available Here', id: 'not-available' },
      { text: 'See Also', id: 'see-also' }
    ],
    h3ByContext: {
      AfterUndelete: [
        {
          text: 'There Is No BeforeUndelete',
          id: 'no-before-undelete',
          under: 'at-a-glance'
        }
      ]
    },
    h3ByInterface: {}
  },
  role: {
    h2: [
      { text: 'When to Use', id: 'when-to-use' },
      { text: 'Interface', id: 'interface' },
      { text: 'Example', id: 'example' },
      { text: 'How It Runs', id: 'how-it-runs' },
      { text: 'Register', id: 'register' },
      { text: 'Records Here', id: 'records' },
      { text: 'Works With', id: 'works-with' },
      { text: 'Gotchas', id: 'gotchas' },
      { text: 'Test It', id: 'test' },
      { text: 'In Other Contexts', id: 'other-contexts' },
      { text: 'See Also', id: 'see-also' }
    ],
    h3ByContext: {},
    h3ByInterface: {
      Writer: [
        {
          text: 'Unit of Work Methods',
          id: 'unit-of-work-methods',
          under: 'how-it-runs'
        },
        { text: 'Which Unit You Get', id: 'which-unit', under: 'how-it-runs' },
        {
          text: 'When It Commits',
          id: 'when-it-commits',
          under: 'how-it-runs'
        },
        { text: 'Platform Events', id: 'platform-events', under: 'how-it-runs' }
      ],
      Dispatcher: [
        { text: 'Platform Events', id: 'platform-events', under: 'how-it-runs' }
      ]
    }
  },
  'add-ons': {
    h2: [
      { text: 'Add-ons in <Ctx>', id: 'available' },
      { text: 'Not Available Here', id: 'not-available' },
      { text: 'Which Roles Honour Them', id: 'works-with' },
      { text: 'See Also', id: 'see-also' }
    ],
    h3ByContext: {},
    h3ByInterface: {}
  },
  'add-on': {
    h2: [
      { text: 'When to Use', id: 'when-to-use' },
      { text: 'Interface', id: 'interface' },
      { text: 'Example', id: 'example' },
      { text: 'How It Runs', id: 'how-it-runs' },
      { text: 'Records Here', id: 'records' },
      { text: 'Works With', id: 'works-with' },
      { text: 'Gotchas', id: 'gotchas' },
      { text: 'Test It', id: 'test' },
      { text: 'In Other Contexts', id: 'other-contexts' },
      { text: 'See Also', id: 'see-also' }
    ],
    h3ByContext: {},
    h3ByInterface: {
      ParentQuery: [
        {
          text: 'Choosing Fields',
          id: 'choosing-fields',
          under: 'how-it-runs'
        },
        {
          text: 'ParentQuery vs PriorParentQuery',
          id: 'parent-vs-prior',
          under: 'how-it-runs'
        }
      ],
      PriorParentQuery: [
        {
          text: 'Choosing Fields',
          id: 'choosing-fields',
          under: 'how-it-runs'
        },
        {
          text: 'ParentQuery vs PriorParentQuery',
          id: 'parent-vs-prior',
          under: 'how-it-runs'
        }
      ],
      RelatedQuery: [
        { text: 'RecordsProvider', id: 'records-provider', under: 'interface' },
        { text: 'Key Patterns', id: 'key-patterns', under: 'how-it-runs' }
      ],
      OwnUnitOfWork: [
        {
          text: 'Configuring the Unit',
          id: 'configuring',
          under: 'how-it-runs'
        }
      ],
      Bypassable: [
        {
          text: 'Other Ways to Switch Off',
          id: 'other-ways',
          under: 'how-it-runs'
        },
        {
          text: 'During a Data Migration',
          id: 'data-migration',
          under: 'how-it-runs'
        }
      ],
      RecursionGuard: [
        { text: 'Edge Values', id: 'edge-values', under: 'how-it-runs' }
      ],
      ContinueOnError: [
        { text: 'What Still Throws', id: 'still-throws', under: 'how-it-runs' },
        { text: 'Logging', id: 'logging', under: 'how-it-runs' }
      ]
    }
  },
  'record-api': {
    h2: [
      { text: 'What You Receive', id: 'receive' },
      { text: 'Accessors', id: 'accessors' },
      { text: 'Change Detection', id: 'change-detection' },
      { text: 'Value Predicates', id: 'predicates' },
      { text: 'Comparisons', id: 'comparisons' },
      { text: 'Record Type', id: 'record-type' },
      { text: 'Parents and Related', id: 'parents' },
      { text: 'Collections', id: 'collections' },
      { text: 'From Trigger Variables', id: 'trigger-variables' },
      { text: 'Gotchas', id: 'gotchas' },
      { text: 'See Also', id: 'see-also' }
    ],
    h3ByContext: {},
    h3ByInterface: {}
  }
};

export function headingText(entry, contextName) {
  return entry.text.replace('<Ctx>', contextName ?? '<Ctx>');
}

export function allowedIds(template, contextName, interfaceName) {
  const definition = templates[template];
  if (!definition) return null;
  return [
    ...definition.h2.map(entry => entry.id),
    ...(definition.h3ByContext[contextName] ?? []).map(entry => entry.id),
    ...(definition.h3ByInterface[interfaceName] ?? []).map(entry => entry.id)
  ];
}
