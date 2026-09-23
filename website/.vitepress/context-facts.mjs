const recursionDefault = 3;

export const contextFacts = {
  BeforeInsert: {
    rowSide: 'new',
    idsExist: false,
    put: 'works'
  },
  AfterInsert: {
    rowSide: 'new',
    idsExist: true,
    put: 'throws'
  },
  BeforeUpdate: {
    rowSide: 'new',
    idsExist: true,
    put: 'works'
  },
  AfterUpdate: {
    rowSide: 'new',
    idsExist: true,
    put: 'throws'
  },
  BeforeDelete: {
    rowSide: 'old',
    idsExist: true,
    put: null
  },
  AfterDelete: {
    rowSide: 'old',
    idsExist: true,
    put: null
  },
  AfterUndelete: {
    rowSide: 'new',
    idsExist: true,
    put: null
  }
};

export const putFact = {
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
    summary:
      'Load parent (lookup) fields before the first handler runs; read them with `getNewParent`.',
    called:
      'once per chunk, before the first handler runs; not called for a bypassed handler',
    returns: 'lookup field → the parent fields to load'
  },
  PriorParentQuery: {
    summary:
      'Load the parent the old row pointed to; read it with `getOldParent`.',
    called:
      'once per chunk, before the first handler runs; not called for a bypassed handler',
    returns: 'lookup field → the parent fields to load'
  },
  RelatedQuery: {
    summary:
      'Query children, siblings or any other records once per chunk; read them with `getRelated`.',
    called:
      'once per chunk, at this handler’s turn, before its first predicate',
    returns: 'provider name → `RecordsProvider`'
  },
  OwnUnitOfWork: {
    summary: 'Give the handler its own unit of work, committed right after it.',
    called:
      'once per chunk, when the handler list is built, even for a handler that is then bypassed',
    returns: 'the unit this Writer registers into'
  },
  Bypassable: {
    summary: 'Skip this handler for the whole chunk when a condition holds.',
    called:
      'once per chunk, before parents load; not called when metadata or `TriggerOrchestrator.bypass()` already skips the handler',
    returns: '`true` to skip this handler for this chunk'
  },
  RecursionGuard: {
    summary: `Cap how many times this handler acts on the same record in one transaction (default ${recursionDefault}).`,
    called:
      'once per chunk, when the handler list is built, even for a handler that is then bypassed',
    returns:
      'how many times one record may qualify for this handler in the transaction'
  },
  Finalizer: {
    summary:
      'Run once after this handler’s records, with the records that qualified.',
    called:
      'once per chunk, after this handler’s records, only if at least one record qualified',
    returns: null
  },
  ContinueOnError: {
    summary: 'Log and swallow this handler’s exceptions, so the save goes on.',
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
      ]
    },
    Validator: {
      honours: [
        'ParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ]
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
      ]
    },
    Dispatcher: {
      honours: [
        'ParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ]
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
      ]
    },
    Validator: {
      honours: [
        'ParentQuery',
        'PriorParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ]
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
      ]
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
      ]
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
      ]
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
      ]
    },
    Dispatcher: {
      honours: [
        'PriorParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ]
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
      ]
    },
    Dispatcher: {
      honours: [
        'ParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ]
    }
  }
};

export const deletePriorParentNote =
  'In delete contexts the PriorParentQuery method is named `queryParentsOn<Ctx>()`.';
