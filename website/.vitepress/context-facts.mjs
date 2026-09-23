export const recursionDefault = 3;

export const factRows = [
  { id: 'record-type', label: 'Record / bulk type', source: 'parser' },
  { id: 'record-id', label: 'Record Id' },
  { id: 'new-values', label: 'New values' },
  { id: 'old-values', label: 'Old values' },
  { id: 'put', label: '`put`', source: 'parser+facts' },
  { id: 'change-detection', label: 'Change detection', source: 'parser' },
  { id: 'add-error', label: '`addError`' },
  { id: 'dml', label: 'DML' },
  { id: 'shared-unit', label: 'Shared unit of work' },
  { id: 'parent-sides', label: 'Parent sides', source: 'parser' },
  { id: 'parent-query-path', label: 'Parent query path' },
  { id: 'recursion-guard', label: 'Recursion guard', source: 'parser+honour' }
];

export const contextFacts = {
  BeforeInsert: {
    rowSide: 'new',
    idsExist: false,
    put: 'works',
    'record-id': '`null`: the record is not saved yet',
    'new-values': 'read, and write with `put`',
    'old-values': 'none',
    'add-error':
      'Validator action: `record.addError(…)`; the record is not saved',
    dml: 'forbidden: the DML guard throws',
    'shared-unit': 'none: nothing can register',
    'parent-query-path':
      'one query per declared lookup; the new side is re-queried after a Populator re-points a lookup'
  },
  AfterInsert: {
    rowSide: 'new',
    idsExist: true,
    put: 'throws',
    'record-id': 'set',
    'new-values': 'read-only',
    'old-values': 'none',
    'add-error':
      '`record.getNewSObject().addError(…)` rolls back that record’s insert',
    dml: 'Writer: unit of work; Dispatcher: direct DML',
    'shared-unit': 'commits once, after the last handler',
    'parent-query-path':
      'one query on the trigger object through relationship paths, plus one query per lookup for a parent it did not return'
  },
  BeforeUpdate: {
    rowSide: 'new',
    idsExist: true,
    put: 'works',
    'record-id': 'set',
    'new-values': 'read, and write with `put`',
    'old-values': 'read-only',
    'add-error':
      'Validator action: `record.addError(…)`; the change is not saved',
    dml: 'forbidden: the DML guard throws',
    'shared-unit': 'none: nothing can register',
    'parent-query-path':
      'one query per declared lookup, new and old Ids together; the new side is re-queried after a Populator re-points a lookup'
  },
  AfterUpdate: {
    rowSide: 'new',
    idsExist: true,
    put: 'throws',
    'record-id': 'set',
    'new-values': 'read-only',
    'old-values': 'read-only',
    'add-error':
      '`record.getNewSObject().addError(…)` rolls back that record’s update',
    dml: 'Writer: unit of work; Dispatcher: direct DML',
    'shared-unit': 'commits once, after the last handler',
    'parent-query-path':
      'one query on the trigger object for the new side, plus one query per lookup for old parents and for new parents it did not return'
  },
  BeforeDelete: {
    rowSide: 'old',
    idsExist: true,
    put: null,
    'record-id': 'set',
    'new-values': 'none',
    'old-values': 'read-only',
    'add-error': '`record.getOldSObject().addError(…)` blocks the delete',
    dml: 'direct DML: no guard and no unit of work',
    'shared-unit': 'none: nothing can register',
    'parent-query-path': 'one query per declared lookup (old side)'
  },
  AfterDelete: {
    rowSide: 'old',
    idsExist: true,
    put: null,
    'record-id': 'set',
    'new-values': 'none',
    'old-values': 'read-only',
    'add-error': '`record.getOldSObject().addError(…)` rolls back the delete',
    dml: 'Writer: unit of work; Dispatcher: direct DML',
    'shared-unit': 'commits once, after the last handler',
    'parent-query-path': 'one query per declared lookup (old side)'
  },
  AfterUndelete: {
    rowSide: 'new',
    idsExist: true,
    put: null,
    'record-id': 'set',
    'new-values': 'read-only',
    'old-values': 'none',
    'add-error':
      '`record.getNewSObject().addError(…)` rolls back the restore; the record stays deleted',
    dml: 'Writer: unit of work; Dispatcher: direct DML',
    'shared-unit': 'commits once, after the last handler',
    'parent-query-path':
      'one query on the trigger object through relationship paths, plus one query per lookup for a parent it did not return'
  }
};

export const putBehaviour = {
  works: 'works: writes to the `Trigger.new` row; later handlers see the value',
  throws:
    'compiles, but throws `System.FinalException` at run time: the row is read-only, no catch inside the trigger stops it, and the caller’s DML fails with a `DmlException`'
};

export const putFact = {
  works: 'works',
  throws: 'compiles, but throws `System.FinalException`: the row is read-only'
};

export const roleCalls = {
  Populator: {
    predicate: 'once per record in the chunk',
    action: 'right after its predicate returns true, for that record'
  },
  Validator: {
    predicate: 'once per record in the chunk',
    action:
      'right after its predicate returns true; it must attach an error to the record, or the library throws'
  },
  Writer: {
    predicate: 'once per record in the chunk',
    action:
      'right after its predicate returns true, with this Writer’s unit of work'
  },
  Dispatcher: {
    predicate: 'once per record in the chunk; it only selects records',
    action:
      'once, after every record was checked, with the qualified records; not called when none qualified'
  },
  Handler: {
    predicate: 'once per record in the chunk',
    action: 'right after its predicate returns true, for that record'
  }
};

export const addOnFacts = {
  ParentQuery: {
    purpose:
      'Load fields of the parent a lookup points to before any handler runs; read them with `record.getNewParent(relationshipName)`.',
    called:
      'once per run, before the first handler runs; not called for a bypassed handler',
    returns: 'lookup field → the parent fields to load'
  },
  PriorParentQuery: {
    purpose:
      'Load fields of the parent the old row pointed to; read them with `record.getOldParent(relationshipName)`.',
    called:
      'once per run, before the first handler runs; not called for a bypassed handler',
    returns: 'lookup field → the parent fields to load'
  },
  RelatedQuery: {
    purpose:
      'Name providers that query children, siblings or any other records once per run; read them with `record.getRelated(providerName)`.',
    called: 'once per run, at this handler’s turn, before its first predicate',
    returns: 'provider name → `RecordsProvider`'
  },
  OwnUnitOfWork: {
    purpose:
      'Give a Writer its own DML Lib unit (user mode, sharing, partial success, statement order); it commits right after this Writer.',
    called:
      'once per run, when the handler list is built, even for a handler that is then bypassed',
    returns: 'the unit this Writer registers into'
  },
  Bypassable: {
    purpose:
      'Skip (bypass, disable) this handler for the whole run when a condition holds.',
    called:
      'once per run, before parents load; not called when metadata or `TriggerOrchestrator.bypass()` already skips the handler',
    returns: '`true` to skip this handler for this run'
  },
  RecursionGuard: {
    purpose: `Cap how many times this handler acts on the same record in one transaction (default ${recursionDefault}).`,
    called:
      'once per run, when the handler list is built, even for a handler that is then bypassed',
    returns:
      'how many times one record may qualify for this handler in the transaction'
  },
  Finalizer: {
    purpose:
      'Run once after this handler’s records, with the records that qualified.',
    called:
      'once per run, after this handler’s records, only if at least one record qualified',
    returns: null
  },
  ContinueOnError: {
    purpose:
      'Log and swallow this handler’s exceptions, so later handlers run and the save goes on.',
    called: null,
    returns: null
  }
};

export const supportFacts = {
  RecordsProvider: {
    query: {
      called:
        'once per provider, at the handler’s turn, with every record in the chunk',
      returns: 'the rows to index by key; `null` counts as no rows'
    },
    keyOf: {
      called: 'once per row that `query` returned',
      returns:
        'the key that `getFirstWhereKeyEquals` and `getAllWhereKeyEquals` match; `null` leaves the row out of the index'
    }
  }
};

export const honourTable = {
  BeforeInsert: {
    Populator: {
      honours: [
        'ParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        ParentQuery: 'parents are re-queried after it re-points a lookup',
        Finalizer: 'the DML guard covers it',
        ContinueOnError: 'the DML guard still throws'
      }
    },
    Validator: {
      honours: [
        'ParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        ParentQuery: 'no re-query after it',
        Finalizer: 'receives only records it already rejected',
        ContinueOnError: 'a qualified record left without an error still throws'
      }
    }
  },
  AfterInsert: {
    Writer: {
      honours: [
        'ParentQuery',
        'RelatedQuery',
        'OwnUnitOfWork',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        OwnUnitOfWork: 'its unit commits right after this Writer',
        Finalizer: 'gets no unit; keep the action’s unit in a field',
        ContinueOnError: 'also gives the Writer a private unit'
      }
    },
    Dispatcher: {
      honours: [
        'ParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        OwnUnitOfWork: 'a Dispatcher never receives a unit',
        Finalizer: 'runs after the dispatch'
      }
    }
  },
  BeforeUpdate: {
    Populator: {
      honours: [
        'ParentQuery',
        'PriorParentQuery',
        'RelatedQuery',
        'Bypassable',
        'RecursionGuard',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        ParentQuery: 'parents are re-queried after it re-points a lookup',
        PriorParentQuery: 'old-side parents are never re-queried',
        RecursionGuard: `default ${recursionDefault} per record`,
        Finalizer: 'the DML guard covers it',
        ContinueOnError: 'the DML guard still throws'
      }
    },
    Validator: {
      honours: [
        'ParentQuery',
        'PriorParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        ParentQuery: 'no re-query after it',
        RecursionGuard: 'a Validator runs on every pass',
        Finalizer: 'receives only records it already rejected',
        ContinueOnError: 'a qualified record left without an error still throws'
      }
    }
  },
  AfterUpdate: {
    Writer: {
      honours: [
        'ParentQuery',
        'PriorParentQuery',
        'RelatedQuery',
        'OwnUnitOfWork',
        'Bypassable',
        'RecursionGuard',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        OwnUnitOfWork: 'its unit commits right after this Writer',
        RecursionGuard: `default ${recursionDefault} per record`,
        Finalizer: 'gets no unit; keep the action’s unit in a field',
        ContinueOnError: 'also gives the Writer a private unit'
      }
    },
    Dispatcher: {
      honours: [
        'ParentQuery',
        'PriorParentQuery',
        'RelatedQuery',
        'Bypassable',
        'RecursionGuard',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        OwnUnitOfWork: 'a Dispatcher never receives a unit',
        RecursionGuard: `default ${recursionDefault} per record`,
        Finalizer: 'runs after the dispatch'
      }
    }
  },
  BeforeDelete: {
    Handler: {
      honours: [
        'PriorParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        Finalizer: 'direct DML is allowed here (no guard)',
        ContinueOnError: 'also swallows a failed direct DML statement'
      }
    }
  },
  AfterDelete: {
    Writer: {
      honours: [
        'PriorParentQuery',
        'RelatedQuery',
        'OwnUnitOfWork',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        OwnUnitOfWork: 'its unit commits right after this Writer',
        Finalizer: 'gets no unit; keep the action’s unit in a field',
        ContinueOnError: 'also gives the Writer a private unit'
      }
    },
    Dispatcher: {
      honours: [
        'PriorParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        OwnUnitOfWork: 'a Dispatcher never receives a unit',
        Finalizer: 'runs after the dispatch'
      }
    }
  },
  AfterUndelete: {
    Writer: {
      honours: [
        'ParentQuery',
        'RelatedQuery',
        'OwnUnitOfWork',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        OwnUnitOfWork: 'its unit commits right after this Writer',
        Finalizer: 'gets no unit; keep the action’s unit in a field',
        ContinueOnError: 'also gives the Writer a private unit'
      }
    },
    Dispatcher: {
      honours: [
        'ParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ],
      notes: {
        OwnUnitOfWork: 'a Dispatcher never receives a unit',
        Finalizer: 'runs after the dispatch'
      }
    }
  }
};

export const notHere = {
  BeforeInsert: {
    PriorParentQuery: {
      reason: 'an insert has no old row',
      where: [
        ['BeforeUpdate', 'PriorParentQuery'],
        ['AfterUpdate', 'PriorParentQuery']
      ]
    },
    OwnUnitOfWork: {
      reason: 'no DML in before insert (the DML guard throws)',
      where: [['AfterInsert', 'OwnUnitOfWork']]
    },
    RecursionGuard: {
      reason: 'update contexts only',
      where: [
        ['BeforeUpdate', 'RecursionGuard'],
        ['AfterUpdate', 'RecursionGuard']
      ]
    }
  },
  AfterInsert: {
    PriorParentQuery: {
      reason: 'an insert has no previous parent',
      where: [['AfterUpdate', 'PriorParentQuery']]
    },
    RecursionGuard: {
      reason:
        'update contexts only; a self-update from here fires the update contexts, where it is counted',
      where: [
        ['BeforeUpdate', 'RecursionGuard'],
        ['AfterUpdate', 'RecursionGuard']
      ]
    }
  },
  BeforeUpdate: {
    OwnUnitOfWork: {
      reason: 'no DML in before update (the DML guard throws)',
      where: [['AfterUpdate', 'OwnUnitOfWork']]
    }
  },
  AfterUpdate: {},
  BeforeDelete: {
    ParentQuery: {
      reason: 'a delete has no new row',
      where: [['BeforeDelete', 'PriorParentQuery']]
    },
    OwnUnitOfWork: {
      reason: 'BeforeDelete has no unit of work; its DML is direct',
      where: [['AfterDelete', 'OwnUnitOfWork']]
    },
    RecursionGuard: {
      reason: 'update contexts only',
      where: [
        ['BeforeUpdate', 'RecursionGuard'],
        ['AfterUpdate', 'RecursionGuard']
      ]
    }
  },
  AfterDelete: {
    ParentQuery: {
      reason: 'a delete has no new row',
      where: [['AfterDelete', 'PriorParentQuery']]
    },
    RecursionGuard: {
      reason: 'update contexts only',
      where: [
        ['BeforeUpdate', 'RecursionGuard'],
        ['AfterUpdate', 'RecursionGuard']
      ]
    }
  },
  AfterUndelete: {
    PriorParentQuery: {
      reason: 'a restore has no old row',
      where: [['AfterUndelete', 'ParentQuery']]
    },
    RecursionGuard: {
      reason: 'update contexts only',
      where: [
        ['BeforeUpdate', 'RecursionGuard'],
        ['AfterUpdate', 'RecursionGuard']
      ]
    }
  }
};

export const unpairedRoles = {
  AfterUndelete: {
    roles: ['Populator', 'Validator'],
    reason: 'there is no before undelete trigger event'
  }
};

export const universalNotAvailable = [
  {
    what: 'A hook that runs once after the last chunk of a DML statement',
    where:
      'none: each chunk of up to 200 records is its own run, with its own Finalizer calls and its own shared commit'
  },
  {
    what: 'A metadata switch for this context only',
    where:
      '`TriggerObject__mdt` and `TriggerHandler__mdt` switch handlers off in every context of the object; use this context’s {bypassable}'
  }
];

export const deletePriorParentNote =
  'In delete contexts the PriorParentQuery method is named `queryParentsOn<Ctx>()`.';
