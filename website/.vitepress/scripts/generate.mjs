import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmdirSync,
  rmSync,
  statSync,
  writeFileSync
} from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';
import { pathToFileURL } from 'node:url';
import {
  WEBSITE_DIR,
  getInterface,
  getTriggerTypesInterface,
  model
} from '../apex-api.mjs';
import {
  addOnFacts,
  contextFacts,
  honourTable,
  putFact,
  roleCalls,
  supportFacts
} from '../context-facts.mjs';

export const GENERATED_DIR = join(WEBSITE_DIR, '_parts', 'generated');

const code = text => `\`${text}\``;
const link = (text, href) => `[${text}](${href})`;

function table(headers, rows) {
  const escape = cell => String(cell ?? '').replace(/\|/g, '\\|');
  return [
    `| ${headers.map(escape).join(' | ')} |`,
    `|${headers.map(() => '---').join('|')}|`,
    ...rows.map(row => `| ${row.map(escape).join(' | ')} |`)
  ].join('\n');
}

function list(items, conjunction = 'and') {
  if (items.length <= 1) return items.join('');
  return `${items.slice(0, -1).join(', ')} ${conjunction} ${items[items.length - 1]}`;
}

function shortType(type) {
  return type.replace(/^TriggerTypes\./, '');
}

function paramNames(method) {
  return method.params.map(param => param.name).join(', ');
}

function callForm(method) {
  return `${method.name}(${paramNames(method)})`;
}

function interfaceLink(contextName, interfaceName) {
  const item = getInterface(contextName, interfaceName);
  if (!item?.link) {
    throw new Error(`generate: ${contextName}.${interfaceName} has no page`);
  }
  return item.link;
}

function roleOfPredicate(role) {
  return role.methods.find(method => method.returnType === 'Boolean');
}

function roleAction(role) {
  return role.methods.find(method => method !== roleOfPredicate(role));
}

function honours(context, role) {
  return honourTable[context.name][role].honours;
}

function honouringRoles(context, addOn) {
  return context.roles.filter(role => honours(context, role).includes(addOn));
}

function ignoringRoles(context, addOn) {
  return context.roles.filter(role => !honours(context, role).includes(addOn));
}

function recordInterface(context) {
  return getTriggerTypesInterface(context.recordType);
}

function collectionInterface(context) {
  return getTriggerTypesInterface(context.collectionType);
}

function hasMethod(declared, name) {
  return declared.methodNames.includes(name);
}

function validate() {
  for (const context of model.contexts) {
    if (!contextFacts[context.name])
      throw new Error(
        `generate: context-facts.mjs has no contextFacts.${context.name}`
      );
    if (!honourTable[context.name])
      throw new Error(
        `generate: context-facts.mjs has no honourTable.${context.name}`
      );

    for (const role of context.roles) {
      const entry = honourTable[context.name][role];
      if (!entry)
        throw new Error(`generate: honourTable.${context.name} has no ${role}`);
      for (const addOn of entry.honours) {
        if (!context.addOns.includes(addOn))
          throw new Error(
            `generate: honourTable.${context.name}.${role} honours ${addOn}, which ${context.name}.cls does not declare`
          );
      }
    }
    for (const role of Object.keys(honourTable[context.name])) {
      if (!context.roles.includes(role))
        throw new Error(
          `generate: honourTable.${context.name} lists ${role}, which is not a role in ${context.name}.cls`
        );
    }

    const hasPut = hasMethod(recordInterface(context), 'put');
    const factPut = contextFacts[context.name].put;
    if (hasPut !== Boolean(factPut)) {
      throw new Error(
        `generate: contextFacts.${context.name}.put is ${factPut} but ${shortType(context.recordType)} ${hasPut ? 'declares' : 'does not declare'} put`
      );
    }
  }
}

function qualified(context, typeName) {
  return typeName.includes('.') ? typeName : `${context.name}.${typeName}`;
}

function signature(context, item) {
  const members = item.methods.map(method => `    ${method.signature};`);
  const header = `public interface ${item.name}${item.extends ? ` extends ${qualified(context, item.extends)}` : ''} {`;
  const block = ['```apex', header, ...members, '}', '```'].join('\n');

  const lines = [block];

  if (item.methods.length === 0) {
    lines.push(
      `${code(item.qualifiedName)} has no methods: implementing it is the whole opt-in.`
    );
  } else {
    lines.push(
      item.methods
        .map(
          method =>
            `- ${code(callForm(method))}: ${methodLine(context, item, method)}`
        )
        .join('\n')
    );
  }

  if (item.kind === 'addOn') {
    const honouring = honouringRoles(context, item.name);
    const ignoring = ignoringRoles(context, item.name);
    if (ignoring.length > 0) {
      lines.push(
        `Only ${list(honouring.map(role => `a ${link(role, interfaceLink(context.name, role))}`))} ${honouring.length > 1 ? 'use' : 'uses'} it; ${list(ignoring.map(role => `a ${role}`))} ${ignoring.length > 1 ? 'ignore' : 'ignores'} it.`
      );
    }
  }

  return lines.join('\n\n');
}

function sentence(text) {
  const trimmed = text.trim();
  return `${trimmed[0].toUpperCase()}${trimmed.slice(1)}${/[.!?]$/.test(trimmed) ? '' : '.'}`;
}

function methodLine(context, item, method) {
  const parts = [];

  if (item.kind === 'role') {
    const isPredicate = method === roleOfPredicate(item);
    let called = isPredicate
      ? roleCalls[item.name].predicate
      : roleCalls[item.name].action;
    if (isPredicate && honours(context, item.name).includes('RecursionGuard'))
      called += '; a record past its recursion limit is skipped without a call';
    parts.push(`called ${called}.`);
    if (isPredicate)
      parts.push(`Return ${code('true')} ${predicateReturns[item.name]}.`);
  } else if (item.kind === 'addOn') {
    let called = addOnFacts[item.name].called;
    if (item.name === 'Finalizer' && context.roles.includes('Dispatcher')) {
      called += '; after the dispatch for a Dispatcher';
    }
    parts.push(`called ${called}.`);
    if (addOnFacts[item.name].returns)
      parts.push(sentence(`returns ${addOnFacts[item.name].returns}`));
  } else if (item.kind === 'support') {
    const facts = supportFacts[item.name]?.[method.name];
    if (facts?.called) parts.push(`called ${facts.called}.`);
    if (facts?.returns) parts.push(sentence(`returns ${facts.returns}`));
  }

  return parts.join(' ');
}

const predicateReturns = {
  Populator: 'to populate the record',
  Validator: 'to reject the record',
  Writer: 'to write for the record',
  Dispatcher: 'to include the record in the dispatch'
};

const skeletonClassNames = {
  Populator: 'ContactPopulator',
  Validator: 'ContactValidator',
  Writer: 'ContactWriter',
  Dispatcher: 'ContactDispatcher'
};

function apexMethod(method, bodyLines) {
  const header = `    public ${method.returnType} ${method.name}(${method.params.map(param => `${param.type} ${param.name}`).join(', ')}) {`;
  return [
    header,
    ...bodyLines.map(line => (line ? `        ${line}` : '')),
    '    }'
  ].join('\n');
}

function skeletonBody(context, roleName, addOnName) {
  const declared = recordInterface(context);
  const changes = hasMethod(declared, 'isChanged');
  const side = hasMethod(declared, 'getNewSObject')
    ? 'getNewSObject'
    : 'getOldSObject';
  const collection =
    contextFacts[context.name].rowSide === 'old'
      ? 'records.getIdsOf(Contact.AccountId)'
      : 'records.getIds()';
  const accountChanged = changes
    ? 'record.isChanged(Contact.AccountId) && '
    : '';
  const deletes = context.operation === 'Delete';
  const reviewTask = (whatId, subject) =>
    `unitOfWork.toInsert(new Task(WhatId = ${whatId}, Subject = ${subject}));`;

  const body = {
    fields: [],
    predicate: {
      Populator: [
        changes
          ? 'return record.isChanged(Contact.Email);'
          : 'return record.isBlank(Contact.LeadSource);'
      ],
      Validator: [
        deletes
          ? 'return record.isTrue(Contact.DoNotCall);'
          : changes
            ? 'return record.isChangedTo(Contact.Email, null);'
            : 'return record.isBlank(Contact.Email);'
      ],
      Writer: [
        changes
          ? 'return record.isChanged(Contact.AccountId);'
          : 'return record.isNotNull(Contact.AccountId);'
      ],
      Dispatcher: [
        changes
          ? 'return record.isChanged(Contact.Email);'
          : 'return record.isNotNull(Contact.Email);'
      ]
    }[roleName],
    action: {
      Populator: [
        changes
          ? 'record.put(Contact.HasOptedOutOfEmail, false);'
          : "record.put(Contact.LeadSource, 'Web');"
      ],
      Validator: [
        deletes
          ? "record.addError('A Do Not Call contact cannot be deleted.');"
          : changes
            ? "record.addError(Contact.Email, 'Email cannot be removed.');"
            : "record.addError(Contact.Email, 'Email is required.');"
      ],
      Writer: [
        reviewTask(`((Contact) record.${side}()).AccountId`, "'Review contact'")
      ],
      Dispatcher: [`System.enqueueJob(new ContactSyncJob(${collection}));`]
    }[roleName],
    finalizer: []
  };

  if (addOnName === 'ParentQuery') {
    body.predicate = [
      `return ${accountChanged}record.getNewParent(Contact.AccountId) != null;`
    ];
    if (roleName === 'Populator')
      body.action = [
        "record.put(Contact.Description, ((Account) record.getNewParent(Contact.AccountId)).Name);"
      ];
    if (roleName === 'Writer')
      body.action = [
        "Account accountRecord = (Account) record.getNewParent(Contact.AccountId);",
        '',
        reviewTask(
          'accountRecord.Id',
          "'Review contact of ' + accountRecord.Name"
        )
      ];
  }

  if (addOnName === 'PriorParentQuery') {
    body.predicate = [
      `return ${accountChanged}record.getOldParent(Contact.AccountId) != null;`
    ];
    if (roleName === 'Populator')
      body.action = [
        "record.put(Contact.Description, 'Moved from ' + ((Account) record.getOldParent(Contact.AccountId)).Name);"
      ];
    if (roleName === 'Writer')
      body.action = [
        "Account previousAccount = (Account) record.getOldParent(Contact.AccountId);",
        '',
        reviewTask(
          'previousAccount.Id',
          "'Contact left ' + previousAccount.Name"
        )
      ];
    if (roleName === 'Validator')
      body.action = [
        "record.addError('Remove the contact from ' + ((Account) record.getOldParent(Contact.AccountId)).Name + ' first.');"
      ];
  }

  if (addOnName === 'RelatedQuery') {
    const accountId = `Id accountId = ((Contact) record.${side}()).AccountId;`;
    const contacts =
      "record.getRelated('accountContacts').getAllWhereKeyEquals(accountId)";
    body.predicate = [
      changes
        ? 'return record.isChanged(Contact.AccountId);'
        : 'return record.isNotNull(Contact.AccountId);'
    ];
    if (roleName === 'Populator')
      body.action = [
        accountId,
        '',
        `record.put(Contact.Description, 'Contacts on the account: ' + ${contacts}.size());`
      ];
    if (roleName === 'Writer')
      body.action = [
        accountId,
        `Integer contactCount = ${contacts}.size();`,
        '',
        reviewTask('accountId', "'Contacts on the account: ' + contactCount")
      ];
    if (roleName === 'Validator') {
      body.predicate = [
        accountId,
        '',
        `return accountId != null && ${contacts}.size() == 1;`
      ];
      body.action = [
        "record.addError('The last contact of an account cannot be deleted.');"
      ];
    }
  }

  if (addOnName === 'Finalizer' && roleName === 'Populator') {
    body.predicate = [
      changes
        ? 'return record.isChanged(Contact.Email) && record.isNotBlank(Contact.Email);'
        : 'return record.isNotBlank(Contact.Email);'
    ];
    body.action = [
      'record.put(Contact.Email, ((Contact) record.getNewSObject()).Email.trim().toLowerCase());'
    ];
    body.finalizer = [
      'Set<String> emails = new Set<String>();',
      '',
      `for (${context.recordType} record : records.getRecords()) {`,
      '    Contact contactRecord = (Contact) record.getNewSObject();',
      '',
      '    if (!emails.add(contactRecord.Email)) {',
      "        contactRecord.Email.addError('Another contact in this save has the same email.');",
      '    }',
      '}'
    ];
  }

  if (addOnName === 'Finalizer' && roleName === 'Writer') {
    body.fields = ['private TriggerTypes.UnitOfWork unitOfWork;'];
    body.action = ['this.unitOfWork = unitOfWork;', ...body.action];
    body.finalizer = [
      'for (Id accountId : records.getIdsOf(Contact.AccountId)) {',
      "    this.unitOfWork.toUpdate(new Account(Id = accountId, Description = 'Contacts changed'));",
      '}'
    ];
  }

  return body;
}

function skeleton(context, roleName, addOnName) {
  const role = getInterface(context.name, roleName);
  const addOn = addOnName ? getInterface(context.name, addOnName) : null;
  const className = skeletonClassNames[roleName];
  const body = skeletonBody(context, roleName, addOnName);

  const fields = body.fields.map(field => `    ${field}`);
  const members = [];
  const innerClasses = [];

  if (addOnName === 'Bypassable')
    fields.unshift('    public static Boolean isBypassed = false;');

  if (addOn && addOnName !== 'Finalizer') {
    for (const method of addOn.methods) {
      if (addOnName === 'ParentQuery' || addOnName === 'PriorParentQuery') {
        members.push(
          apexMethod(method, [
            `return new ${method.returnType}{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };`
          ])
        );
      } else if (addOnName === 'RelatedQuery') {
        members.push(
          apexMethod(method, [
            `return new ${method.returnType}{ 'accountContacts' => new AccountContactsProvider() };`
          ])
        );
      } else if (addOnName === 'OwnUnitOfWork') {
        members.push(
          apexMethod(method, [
            `return new DML().userMode().identifier('${className}');`
          ])
        );
      } else if (addOnName === 'Bypassable') {
        members.push(apexMethod(method, [`return ${className}.isBypassed;`]));
      } else if (addOnName === 'RecursionGuard') {
        members.push(apexMethod(method, ['return 1;']));
      }
    }
  }

  members.push(apexMethod(roleOfPredicate(role), body.predicate));
  members.push(apexMethod(roleAction(role), body.action));

  if (addOnName === 'Finalizer') {
    members.push(apexMethod(addOn.methods[0], body.finalizer));
  }

  if (addOnName === 'RelatedQuery') {
    const provider = getInterface(context.name, 'RecordsProvider');
    const query = provider.methods.find(method => method.name === 'query');
    const keyOf = provider.methods.find(method => method.name === 'keyOf');
    innerClasses.push(
      [
        `    private with sharing class AccountContactsProvider implements ${provider.qualifiedName} {`,
        `        public ${query.returnType} ${query.name}(${query.params.map(param => `${param.type} ${param.name}`).join(', ')}) {`,
        `            return [SELECT Id, AccountId FROM Contact WHERE AccountId IN :${query.params[0].name}.getIdsOf(Contact.AccountId)];`,
        '        }',
        '',
        `        public ${keyOf.returnType} ${keyOf.name}(${keyOf.params.map(param => `${param.type} ${param.name}`).join(', ')}) {`,
        `            return ((Contact) ${keyOf.params[0].name}).AccountId;`,
        '        }',
        '    }'
      ].join('\n')
    );
  }

  if (roleName === 'Dispatcher') {
    innerClasses.push(
      [
        '    public class ContactSyncJob implements Queueable {',
        '        private Set<Id> recordIds;',
        '',
        '        public ContactSyncJob(Set<Id> recordIds) {',
        '            this.recordIds = recordIds;',
        '        }',
        '',
        '        public void execute(QueueableContext context) {',
        '        }',
        '    }'
      ].join('\n')
    );
  }

  const implementsList = [
    role.qualifiedName,
    ...(addOn ? [addOn.qualifiedName] : [])
  ].join(', ');
  const blocks = [
    ...(fields.length > 0 ? [fields.join('\n')] : []),
    ...members,
    ...innerClasses
  ];

  return [
    '```apex [Skeleton]',
    `public with sharing class ${className} implements ${implementsList} {`,
    blocks.join('\n\n'),
    '}',
    '```'
  ].join('\n');
}

const finalizerRoles = ['Populator', 'Writer'];

function skeletonFor(context, item) {
  if (item.kind === 'role') return skeleton(context, item.name, null);
  const honouring = honouringRoles(context, item.name);
  const role =
    item.name === 'Finalizer'
      ? (honouring.find(name => finalizerRoles.includes(name)) ?? honouring[0])
      : honouring[0];
  return skeleton(context, role, item.name);
}

function recordsProvider(context) {
  return signature(context, getInterface(context.name, 'RecordsProvider'));
}

function register(context) {
  const method = context.registration.method;
  const handlers = context.roles
    .map(role => `new ${skeletonClassNames[role]}()`)
    .join(', ');
  const snippet = [
    '```apex',
    `public with sharing class ContactTriggerOrchestrator implements ${context.registration.interfaceName} {`,
    `    public ${method.returnType} ${method.name}() {`,
    `        return new ${method.returnType}{ ${handlers} };`,
    '    }',
    '}',
    '```'
  ].join('\n');

  return [
    `Implement ${code(context.registration.interfaceName)} on the orchestrator and return the handlers from ${code(`${method.name}()`)}. List order is run order. The trigger must list ${code(context.triggerEvent)} and call ${code('TriggerOrchestrator.run(new ContactTriggerOrchestrator())')}.`,
    snippet
  ].join('\n\n');
}

function addOnsList(context) {
  return context.addOns
    .map(addOn => {
      const item = getInterface(context.name, addOn);
      const honouring = honouringRoles(context, addOn);
      const only =
        honouring.length < context.roles.length
          ? ` ${list(honouring)} only.`
          : '';
      const summary = addOnFacts[addOn].summary;
      return `- ${link(addOn, item.link)}: ${summary[0].toLowerCase()}${summary.slice(1)}${only}`;
    })
    .join('\n');
}

const recordMethodGroups = [
  {
    names: ['getId'],
    note: context =>
      contextFacts[context.name].idsExist
        ? 'the record Id'
        : `${code('null')}: not saved yet`
  },
  {
    names: ['getNewSObject'],
    note: context =>
      contextFacts[context.name].put === 'works'
        ? `the ${code('Trigger.new')} row`
        : `the ${code('Trigger.new')} row, read-only`
  },
  {
    names: ['getOldSObject'],
    note: () => `the ${code('Trigger.old')} row, read-only`
  },
  {
    names: ['getNewParent'],
    note: () => `the parent loaded by ParentQuery, or ${code('null')}`
  },
  {
    names: ['getOldParent'],
    note: () =>
      `the old row's parent, loaded by PriorParentQuery, or ${code('null')}`
  },
  {
    names: ['getRelated'],
    note: () => 'rows from a RelatedQuery provider'
  },
  {
    names: ['put'],
    note: context =>
      contextFacts[context.name].put === 'works'
        ? `sets a field on the ${code('Trigger.new')} row`
        : putFact.throws
  },
  {
    names: ['addError'],
    note: () => 'rejects the record, with a record-level or a field error'
  },
  {
    names: ['isRecordType', 'isNotRecordType'],
    note: () => 'record type developer name matches / differs'
  },
  {
    names: ['equals', 'doesNotEqual'],
    note: () => 'equal / different; text ignores case'
  },
  {
    names: ['contains', 'doesNotContain', 'startsWith', 'endsWith'],
    note: () => 'text match; case-sensitive'
  },
  {
    names: ['isNull', 'isNotNull'],
    note: () => 'null / not null'
  },
  {
    names: ['isEmpty', 'isNotEmpty'],
    note: () => `null or ${code("''")} / neither`
  },
  {
    names: ['isBlank', 'isNotBlank'],
    note: () => `null, ${code("''")} or whitespace / none`
  },
  {
    names: ['isTrue', 'isFalse'],
    note: () => `${code('true')} / ${code('false')}`
  },
  {
    names: [
      'greaterThan',
      'greaterThanOrEqualTo',
      'lessThan',
      'lessThanOrEqualTo'
    ],
    note: () => 'number or date comparison; false for null'
  },
  {
    names: ['isChanged'],
    note: () => 'the new value differs from the old one'
  },
  {
    names: ['isAnyChanged', 'areAllChanged'],
    call: name => `${name}(field1, field2, …)`,
    note: () =>
      `any / every field changed; 2 to 5 fields or an ${code('Iterable<SObjectField>')}`
  },
  {
    names: ['isChangedTo', 'isChangedFrom'],
    note: () => 'changed to / from the value'
  },
  {
    names: ['isChangedFromTo'],
    note: () => 'the old value is `fromValue` and the new one is `toValue`'
  }
];

function groupCalls(declared, group) {
  return group.names
    .map((name, index) => {
      if (group.call) return code(group.call(name));
      if (index > 0) return code(name);
      return code(
        callForm(declared.methods.find(method => method.name === name))
      );
    })
    .join(', ');
}

function recordMethodRows(context, declared) {
  const covered = new Set(recordMethodGroups.flatMap(group => group.names));
  const uncovered = declared.methodNames.filter(name => !covered.has(name));
  if (uncovered.length > 0) {
    throw new Error(
      `generate: ${declared.qualifiedName} declares ${uncovered.join(', ')}, which recordMethodGroups in generate.mjs does not describe`
    );
  }

  return recordMethodGroups
    .filter(group => group.names.some(name => hasMethod(declared, name)))
    .map(group => {
      const missing = group.names.filter(name => !hasMethod(declared, name));
      if (missing.length > 0) {
        throw new Error(
          `generate: ${declared.qualifiedName} declares ${group.names.filter(name => !missing.includes(name)).join(', ')} but not ${missing.join(', ')}; split the group in recordMethodGroups`
        );
      }
      return [groupCalls(declared, group), group.note(context)];
    });
}

function recordMethods(context) {
  const declared = recordInterface(context);
  const lines = [
    `Type: ${code(declared.qualifiedName)}. Predicates read the ${contextFacts[context.name].rowSide} row and never throw on null.`,
    table(['Method', `In ${context.name}`], recordMethodRows(context, declared))
  ];

  for (const extra of context.extraRecordTypes) {
    const extraDeclared = getTriggerTypesInterface(extra.type);
    const added = extraDeclared.methods.filter(
      method => !hasMethod(declared, method.name)
    );
    const removed = declared.methodNames.filter(
      name => !hasMethod(extraDeclared, name)
    );
    lines.push(
      `${list(extra.uses.map(use => code(use.method)))} gets a ${code(extraDeclared.qualifiedName)}: ${
        removed.length > 0
          ? `no ${list(
              removed.map(name => code(name)),
              'or'
            )}, plus `
          : 'the same methods, plus '
      }${list(added.map(method => code(callForm(method))))}.`
    );
  }

  return lines.join('\n\n');
}

function collectionReceivers(context) {
  const uses = context.typeUses.filter(use => use.category === 'collection');
  const ordered = [
    ...uses.filter(use => use.kind === 'support'),
    ...uses.filter(use => use.kind !== 'support')
  ];
  const support = ordered
    .filter(use => getInterface(context.name, use.interfaceName).kind === 'support')
    .map(use => code(`${getInterface(context.name, use.interfaceName).name}.${use.method}`));
  const qualified = ordered
    .filter(use => getInterface(context.name, use.interfaceName).kind !== 'support')
    .map(use => code(use.method));
  const verb = items => (items.length > 1 ? 'get' : 'gets');
  return [
    support.length ? `${list(support)} ${verb(support)} the whole chunk.` : '',
    qualified.length ? `${list(qualified)} ${verb(qualified)} the qualified records.` : ''
  ]
    .filter(Boolean)
    .join(' ');
}

function collectionMethodNote(context, method) {
  const facts = contextFacts[context.name];
  const relationship = method.params.length === 2;
  const oldForm = method.name.startsWith('getOld');
  const row = oldForm ? 'old' : facts.rowSide;
  const parentSource = row === 'old' ? 'PriorParentQuery' : 'ParentQuery';
  const bothRows = collectionInterface(context).methodNames.some(name =>
    name.startsWith('getOld')
  );
  const ofRow = bothRows ? ` of the ${row} row` : '';

  switch (method.name) {
    case 'getIds':
      return facts.idsExist ? 'the record Ids' : 'always empty: no Id yet';
    case 'getIdsOf':
    case 'getOldIdsOf':
      return relationship
        ? `Ids in a field of a parent loaded by ${parentSource}`
        : `non-null Ids in a lookup or Id field${ofRow}`;
    case 'getValuesOf':
    case 'getOldValuesOf':
      return relationship
        ? `values of a field of a parent loaded by ${parentSource}, as text`
        : `non-null values of a field${ofRow}, as text`;
    case 'getRecords':
      return `the records, as ${code(shortType(context.recordType))}`;
    case 'size':
      return 'the number of records';
    default:
      throw new Error(
        `generate: collectionMethodNote does not describe ${method.name}`
      );
  }
}

function collectionMethodRows(context, declared) {
  if (!declared.methodNames.some(name => name.startsWith('getOld'))) {
    return declared.methods.map(method => [
      code(callForm(method)),
      collectionMethodNote(context, method)
    ]);
  }

  const grouped = {
    getIdsOf: [
      `${code('getIdsOf(field)')}, ${code('getOldIdsOf(field)')}`,
      'non-null Ids in a lookup or Id field of the new / old row'
    ],
    getValuesOf: [
      `${code('getValuesOf(field)')}, ${code('getOldValuesOf(field)')}`,
      'non-null values of a field of the new / old row, as text'
    ]
  };
  const rows = [];
  for (const method of declared.methods) {
    if (grouped[method.name]) {
      rows.push(grouped[method.name]);
      delete grouped[method.name];
    } else if (
      !['getIdsOf', 'getOldIdsOf', 'getValuesOf', 'getOldValuesOf'].includes(method.name)
    ) {
      rows.push([code(callForm(method)), collectionMethodNote(context, method)]);
    }
  }
  return rows;
}

function collectionMethods(context) {
  const declared = collectionInterface(context);
  const grouped = declared.methodNames.some(name => name.startsWith('getOld'));
  return [
    `Type: ${code(declared.qualifiedName)}. ${collectionReceivers(context)}`,
    table(['Method', `In ${context.name}`], collectionMethodRows(context, declared)),
    grouped ? 'Pass `relationshipName` first to read a parent’s field.' : ''
  ]
    .filter(Boolean)
    .join('\n\n');
}

function matrixCell(context, name) {
  const item = getInterface(context.name, name);
  if (!item || (item.kind !== 'role' && item.kind !== 'addOn')) return '';

  const text =
    item.methods.length === 0
      ? '✓'
      : item.methods.map(method => code(method.name)).join(', ');
  const honouring =
    item.kind === 'addOn' ? honouringRoles(context, name) : context.roles;
  const only =
    honouring.length < context.roles.length ? ` (${list(honouring)} only)` : '';

  return `${link(text, item.link)}${only}`;
}

function matrixMethods() {
  const rows = model.matrixRows
    .filter(name =>
      model.contexts.some(context =>
        ['role', 'addOn'].includes(getInterface(context.name, name)?.kind)
      )
    )
    .map(name => [
      name,
      ...model.contexts.map(context => matrixCell(context, name))
    ]);

  rows.push([
    'Registration',
    ...model.contexts.map(context =>
      link(
        `${code(context.registration.interfaceName)}, ${code(`${context.registration.method.name}()`)}`,
        `${context.link}#register`
      )
    )
  ]);

  return table(
    [
      'Interface',
      ...model.contexts.map(context => link(context.name, context.link))
    ],
    rows
  );
}

function pageInterfaces(context) {
  return context.interfaces.filter(
    candidate => candidate.kind === 'role' || candidate.kind === 'addOn'
  );
}

function buildFiles() {
  validate();

  const files = new Map();
  files.set('matrix-methods.md', matrixMethods());

  for (const context of model.contexts) {
    const folder = context.slug;
    files.set(`${folder}/add-ons-list.md`, addOnsList(context));
    files.set(`${folder}/register.md`, register(context));
    files.set(`${folder}/record-methods.md`, recordMethods(context));
    files.set(`${folder}/collection-methods.md`, collectionMethods(context));

    for (const item of pageInterfaces(context)) {
      const base = `${folder}/${item.slug}`;
      files.set(`${base}/signature.md`, signature(context, item));
      files.set(`${base}/skeleton.md`, skeletonFor(context, item));
      if (item.name === 'RelatedQuery') {
        files.set(`${base}/records-provider.md`, recordsProvider(context));
      }
    }
  }

  for (const [path, content] of files) {
    assertSafeMarkdown(path, content);
    files.set(path, `${content.trimEnd()}\n`);
  }

  return files;
}

function assertSafeMarkdown(path, content) {
  const withoutFences = content.replace(/```[\s\S]*?```/g, '');
  const withoutCode = withoutFences.replace(/`[^`\n]*`/g, '');
  const tag = withoutCode.match(/<[A-Za-z/!]/);
  if (tag) {
    throw new Error(
      `generate: ${path} has a raw "<" outside code ("${withoutCode.slice(Math.max(0, tag.index - 30), tag.index + 30)}"); Vue would parse it as HTML`
    );
  }
  if (withoutFences.includes('{{')) {
    throw new Error(
      `generate: ${path} has "{{" outside a code fence; Vue would interpolate it`
    );
  }
}

function listFiles(directory) {
  if (!existsSync(directory)) return [];
  const found = [];
  for (const name of readdirSync(directory)) {
    const full = join(directory, name);
    if (statSync(full).isDirectory()) found.push(...listFiles(full));
    else found.push(full);
  }
  return found;
}

function removeEmptyDirectories(directory) {
  if (!existsSync(directory)) return;
  for (const name of readdirSync(directory)) {
    const full = join(directory, name);
    if (statSync(full).isDirectory()) removeEmptyDirectories(full);
  }
  if (directory !== GENERATED_DIR && readdirSync(directory).length === 0)
    rmdirSync(directory);
}

export function generate() {
  const files = buildFiles();
  const expected = new Set();
  let written = 0;

  for (const [path, content] of files) {
    const full = join(GENERATED_DIR, ...path.split('/'));
    expected.add(full);
    if (existsSync(full) && readFileSync(full, 'utf8') === content) continue;
    mkdirSync(dirname(full), { recursive: true });
    writeFileSync(full, content);
    written++;
  }

  let removed = 0;
  for (const full of listFiles(GENERATED_DIR)) {
    if (!expected.has(full)) {
      rmSync(full);
      removed++;
    }
  }
  removeEmptyDirectories(GENERATED_DIR);

  return { files, written, removed, directory: GENERATED_DIR };
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  const result = generate();
  console.log(
    `generate: ${result.files.size} partials in ${relative(process.cwd(), result.directory).split(sep).join('/') || '.'} (${result.written} written, ${result.removed} removed)`
  );
}
