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
    predicate: 'once per record in the chunk',
    action:
      'once, after every record was checked, with the qualified records; not called when none qualified'
  }
};

export const addOnFacts = {
  ParentQuery: {
    summary:
      'Load lookup parent fields; read them with `getNewParent`.',
    called:
      'once per chunk, before the first handler runs',
    returns: 'lookup field → the parent fields to load'
  },
  PriorParentQuery: {
    summary:
      'Load the parent the old row pointed to; read it with `getOldParent`.',
    called:
      'once per chunk, before the first handler runs',
    returns: 'lookup field → the parent fields to load'
  },
  RelatedQuery: {
    summary:
      'Query children, siblings or other records once per handler per run; read them with `getRelated`.',
    called:
      'once per handler per run, at this handler’s turn, before its first predicate',
    returns: 'provider name → `RecordsProvider`'
  },
  OwnUnitOfWork: {
    summary: 'Give the handler its own unit of work, committed right after it.',
    called:
      'once per chunk, when the handler list is built',
    returns: 'the unit this Writer registers into'
  },
  Bypassable: {
    summary: 'Skip this handler for the chunk when a condition holds.',
    called:
      'once per chunk, before parents load',
    returns: '`true` to skip this handler for this chunk'
  },
  RecursionGuard: {
    summary: `Cap how often this handler acts on one record per transaction (default ${recursionDefault}).`,
    called:
      'once per chunk, when the handler list is built',
    returns:
      'how many times one record may qualify for this handler in the transaction'
  },
  Finalizer: {
    summary:
      'Run once per chunk with the qualified records.',
    called:
      'once per chunk, after this handler’s records, only if at least one record qualified',
    returns: null
  },
  ContinueOnError: {
    summary: 'Log and swallow this handler’s exceptions.',
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
    Validator: {
      honours: [
        'PriorParentQuery',
        'RelatedQuery',
        'Bypassable',
        'Finalizer',
        'ContinueOnError'
      ]
    },
    Writer: {
      honours: [
        'PriorParentQuery',
        'RelatedQuery',
        'OwnUnitOfWork',
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
