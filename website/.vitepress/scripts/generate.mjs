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
  getContext,
  getInterface,
  getTriggerHandlerInterface,
  model,
  pairedContext
} from '../apex-api.mjs';
import {
  addOnFacts,
  contextFacts,
  deletePriorParentNote,
  factRows,
  honourTable,
  notHere,
  putBehaviour,
  putFact,
  recursionDefault,
  roleCalls,
  supportFacts,
  universalNotAvailable,
  unpairedRoles
} from '../context-facts.mjs';

export const GENERATED_DIR = join(WEBSITE_DIR, '_parts', 'generated');

const code = text => `\`${text}\``;
const link = (text, href) => `[${text}](${href})`;
const bold = text => `**${text}**`;

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
  return type.replace(/^TriggerHandler\./, '');
}

function paramNames(method) {
  return method.params.map(param => param.name).join(', ');
}

function callForm(method) {
  return `${method.name}(${paramNames(method)})`;
}

function interfaceLink(contextName, interfaceName, anchor) {
  const item = getInterface(contextName, interfaceName);
  if (!item?.link) {
    throw new Error(`generate: ${contextName}.${interfaceName} has no page`);
  }
  return anchor && !item.link.includes('#')
    ? `${item.link}#${anchor}`
    : item.link;
}

function qualifiedLink(contextName, interfaceName) {
  return link(
    `${contextName}.${interfaceName}`,
    interfaceLink(contextName, interfaceName)
  );
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

function honourNote(context, role, addOn) {
  return honourTable[context.name][role].notes?.[addOn] ?? '';
}

function recordInterface(context) {
  return getTriggerHandlerInterface(context.recordType);
}

function collectionInterface(context) {
  return getTriggerHandlerInterface(context.collectionType);
}

function hasMethod(declared, name) {
  return declared.methodNames.includes(name);
}

function priorParentMismatches() {
  const mismatches = [];
  for (const context of model.contexts) {
    const prior = getInterface(context.name, 'PriorParentQuery');
    if (prior && !prior.methods[0].name.startsWith('queryPriorParentsOn')) {
      mismatches.push({ context, method: prior.methods[0].name });
    }
  }
  return mismatches;
}

function priorParentNote() {
  const mismatches = priorParentMismatches();
  if (mismatches.length === 0) return null;
  if (mismatches.every(({ context }) => context.operation === 'Delete'))
    return deletePriorParentNote;
  return `In ${list(mismatches.map(({ context }) => context.name))} the PriorParentQuery method is named ${list(mismatches.map(({ method }) => code(`${method}()`)))}.`;
}

function priorParentNoteFor(context) {
  return priorParentMismatches().some(mismatch => mismatch.context === context)
    ? priorParentNote()
    : null;
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
    if (!notHere[context.name])
      throw new Error(
        `generate: context-facts.mjs has no notHere.${context.name}`
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

    const missing = model.canonicalAddOns.filter(
      addOn => !context.addOns.includes(addOn)
    );
    const listed = Object.keys(notHere[context.name]);
    for (const addOn of missing) {
      if (!listed.includes(addOn))
        throw new Error(
          `generate: notHere.${context.name} has no entry for ${addOn}`
        );
    }
    for (const addOn of listed) {
      if (!missing.includes(addOn))
        throw new Error(
          `generate: notHere.${context.name} lists ${addOn}, which ${context.name}.cls declares`
        );
      for (const [targetContext, targetInterface] of notHere[context.name][
        addOn
      ].where) {
        interfaceLink(targetContext, targetInterface);
      }
    }

    const hasPut = hasMethod(recordInterface(context), 'put');
    const factPut = contextFacts[context.name].put;
    if (hasPut !== Boolean(factPut)) {
      throw new Error(
        `generate: contextFacts.${context.name}.put is ${factPut} but ${shortType(context.recordType)} ${hasPut ? 'declares' : 'does not declare'} put`
      );
    }
  }

  for (const [contextName, entry] of Object.entries(unpairedRoles)) {
    const context = getContext(contextName);
    if (!context)
      throw new Error(
        `generate: unpairedRoles names unknown context ${contextName}`
      );
    if (pairedContext(context))
      throw new Error(
        `generate: unpairedRoles.${contextName} has a paired context`
      );
    for (const role of entry.roles) {
      if (!model.roleNames.includes(role))
        throw new Error(
          `generate: unpairedRoles.${contextName} names unknown role ${role}`
        );
    }
  }
}

function signature(context, item) {
  const members = item.methods.map(method => `        ${method.signature};`);
  const header = `    public interface ${item.name}${item.extends ? ` extends ${item.extends}` : ''} {`;
  const body =
    members.length > 0 ? [header, ...members, '    }'] : [header, '    }'];
  const block = [
    '```apex',
    `public class ${context.name} {`,
    ...body,
    '}',
    '```'
  ].join('\n');

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

  if (item.name === 'PriorParentQuery' && priorParentNoteFor(context)) {
    lines.push(priorParentNoteFor(context));
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
    if (isPredicate && honours(context, item.name).includes('RecursionGuard')) {
      called +=
        '; a record that has used up its recursion budget is skipped without a call';
    }
    parts.push(`called ${called}.`);
    if (isPredicate)
      parts.push(`Return ${code('true')} ${predicateReturns[item.name]}.`);
  } else if (item.kind === 'addOn') {
    let called = addOnFacts[item.name].called;
    if (item.name === 'Finalizer' && context.roles.includes('Dispatcher')) {
      called += '; after the dispatch for a Dispatcher';
    }
    parts.push(`called ${called}.`);
    if (item.name === 'Finalizer')
      parts.push('It receives only the qualified records.');
    if (addOnFacts[item.name].returns)
      parts.push(sentence(`returns ${addOnFacts[item.name].returns}`));
  } else if (item.kind === 'support') {
    const facts = supportFacts[item.name]?.[method.name];
    if (facts?.called) parts.push(`called ${facts.called}.`);
    if (facts?.returns) parts.push(sentence(`returns ${facts.returns}`));
  }

  return parts.join(' ');
}

function receivesCell(context, item, method) {
  if (method.params.length === 0) return 'nothing';

  return method.params
    .map(param => {
      const declared = getTriggerHandlerInterface(param.type);
      if (declared?.category === 'record')
        return `${code(shortType(param.type))}: one record`;
      if (declared?.category === 'collection') {
        return item.kind === 'support'
          ? `${code(shortType(param.type))}: every record in the chunk`
          : `${code(shortType(param.type))}: the qualified records`;
      }
      if (param.type === 'TriggerHandler.UnitOfWork')
        return `${code('TriggerHandler.UnitOfWork')}: this Writer’s unit`;
      if (param.type === 'SObject')
        return `${code('SObject')}: one row that ${code('query')} returned`;
      return code(param.type);
    })
    .join('; ');
}

const predicateReturns = {
  Populator: 'to populate the record',
  Validator: 'to reject the record',
  Writer: 'to write for the record',
  Dispatcher: 'to include the record in the dispatch',
  Handler: 'to handle the record'
};

function methodRows(context, item) {
  return item.methods.map(method => {
    let called = '';
    let returns =
      method.returnType === 'void' ? 'nothing' : code(method.returnType);

    if (item.kind === 'role') {
      const isPredicate = method === roleOfPredicate(item);
      called = isPredicate
        ? roleCalls[item.name].predicate
        : roleCalls[item.name].action;
      if (
        isPredicate &&
        honours(context, item.name).includes('RecursionGuard')
      ) {
        called +=
          '; a record that has used up its recursion budget is skipped without a call';
      }
      if (isPredicate)
        returns = `${code('Boolean')}: ${code('true')} ${predicateReturns[item.name]}`;
    } else if (item.kind === 'addOn') {
      called = addOnFacts[item.name].called;
      if (item.name === 'Finalizer' && context.roles.includes('Dispatcher')) {
        called += '; after the dispatch for a Dispatcher';
      }
      if (addOnFacts[item.name].returns)
        returns = `${returns}: ${addOnFacts[item.name].returns}`;
    } else if (item.kind === 'support') {
      const facts = supportFacts[item.name]?.[method.name];
      called = facts?.called ?? '';
      if (facts?.returns) returns = `${returns}: ${facts.returns}`;
    }

    return [
      code(
        `${method.name}(${method.params.map(param => shortType(param.type)).join(', ')})`
      ),
      called,
      receivesCell(context, item, method),
      returns
    ];
  });
}

function methodTable(context, item) {
  if (item.methods.length === 0) {
    return `${code(item.qualifiedName)} has no methods: implementing the interface is the whole opt-in.`;
  }
  return table(
    ['Method', 'Called', 'Receives', 'Returns'],
    methodRows(context, item)
  );
}

const skeletonClassNames = {
  Populator: 'ContactPopulator',
  Validator: 'ContactValidator',
  Writer: 'ContactWriter',
  Dispatcher: 'ContactDispatcher',
  Handler: 'ContactHandler'
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
        changes
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
      ],
      Handler: ['return record.isTrue(Contact.DoNotCall);']
    }[roleName],
    action: {
      Populator: [
        changes
          ? 'record.put(Contact.HasOptedOutOfEmail, false);'
          : "record.put(Contact.LeadSource, 'Web');"
      ],
      Validator: [
        changes
          ? "record.addError(Contact.Email, 'Email cannot be removed.');"
          : "record.addError(Contact.Email, 'Email is required.');"
      ],
      Writer: [
        reviewTask(`((Contact) record.${side}()).AccountId`, "'Review contact'")
      ],
      Dispatcher: [`System.enqueueJob(new ContactSyncJob(${collection}));`],
      Handler: [
        "record.getOldSObject().addError('A Do Not Call contact cannot be deleted.');"
      ]
    }[roleName],
    finalizer: []
  };

  if (addOnName === 'ParentQuery') {
    body.predicate = [
      `return ${accountChanged}record.getNewParent('Account') != null;`
    ];
    if (roleName === 'Populator')
      body.action = [
        "record.put(Contact.Description, ((Account) record.getNewParent('Account')).Name);"
      ];
    if (roleName === 'Writer')
      body.action = [
        "Account accountRecord = (Account) record.getNewParent('Account');",
        '',
        reviewTask(
          'accountRecord.Id',
          "'Review contact of ' + accountRecord.Name"
        )
      ];
  }

  if (addOnName === 'PriorParentQuery') {
    body.predicate = [
      `return ${accountChanged}record.getOldParent('Account') != null;`
    ];
    if (roleName === 'Populator')
      body.action = [
        "record.put(Contact.Description, 'Moved from ' + ((Account) record.getOldParent('Account')).Name);"
      ];
    if (roleName === 'Writer')
      body.action = [
        "Account previousAccount = (Account) record.getOldParent('Account');",
        '',
        reviewTask(
          'previousAccount.Id',
          "'Contact left ' + previousAccount.Name"
        )
      ];
    if (roleName === 'Handler')
      body.action = [
        "record.getOldSObject().addError('Remove the contact from ' + ((Account) record.getOldParent('Account')).Name + ' before you delete it.');"
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
    if (roleName === 'Handler') {
      body.action = [
        accountId,
        '',
        `if (${contacts}.size() == 1) {`,
        "    record.getOldSObject().addError('The last contact of an account cannot be deleted.');",
        '}'
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
    body.fields = ['private TriggerHandler.UnitOfWork unitOfWork;'];
    body.action = ['this.unitOfWork = unitOfWork;', ...body.action];
    body.finalizer = [
      'for (Id accountId : records.getIdsOf(Contact.AccountId)) {',
      "    this.unitOfWork.toUpdate(new Account(Id = accountId, Description = 'Contacts changed'));",
      '}'
    ];
  }

  if (addOnName === 'Finalizer' && roleName === 'Handler') {
    body.fields = ['private Set<Id> accountIds = new Set<Id>();'];
    body.predicate = ['return record.isNotNull(Contact.AccountId);'];
    body.action = [
      'this.accountIds.add(((Contact) record.getOldSObject()).AccountId);'
    ];
    body.finalizer = [
      'List<Account> accounts = new List<Account>();',
      '',
      'for (Id accountId : this.accountIds) {',
      "    accounts.add(new Account(Id = accountId, Description = 'Contacts deleted'));",
      '}',
      '',
      'update accounts;'
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
    fields.unshift('    public static Boolean isDisabled = false;');

  if (addOn && addOnName !== 'Finalizer') {
    for (const method of addOn.methods) {
      if (addOnName === 'ParentQuery' || addOnName === 'PriorParentQuery') {
        members.push(
          apexMethod(method, [
            `return new ${method.returnType}{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };`
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
        members.push(apexMethod(method, [`return ${className}.isDisabled;`]));
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

function skeletonFor(context, item) {
  if (item.kind === 'role') return skeleton(context, item.name, null);
  const role = honouringRoles(context, item.name)[0];
  return skeleton(context, role, item.name);
}

function availableIn(context, item) {
  const present = model.contexts.filter(
    candidate => getInterface(candidate.name, item.name)?.kind === item.kind
  );
  if (present.length === 1) {
    return `${bold('Available in:')} ${present[0].name} only`;
  }
  return `${bold('Available in:')} ${present.map(candidate => (candidate === context ? bold(candidate.name) : link(candidate.name, interfaceLink(candidate.name, item.name)))).join(' · ')}`;
}

function worksWith(context, item) {
  if (item.kind === 'role') {
    const rows = context.addOns.map(addOn => {
      const honoured = honours(context, item.name).includes(addOn);
      return [
        link(addOn, interfaceLink(context.name, addOn)),
        honoured ? 'honoured' : bold('ignored'),
        honourNote(context, item.name, addOn)
      ];
    });
    return table(['Add-on', `${context.name}.${item.name}`, 'Note'], rows);
  }

  const rows = context.roles.map(role => {
    const honoured = honours(context, role).includes(item.name);
    return [
      link(role, interfaceLink(context.name, role)),
      honoured ? 'honoured' : bold('ignored'),
      honourNote(context, role, item.name)
    ];
  });
  return table(['Role', `${context.name}.${item.name}`, 'Note'], rows);
}

function methodNamesCell(item) {
  return item.methods.map(method => code(method.name)).join(' · ');
}

function whereLinks(where, current) {
  return where
    .map(([targetContext, targetInterface]) =>
      current &&
      current.context === targetContext &&
      current.name === targetInterface
        ? 'this page'
        : qualifiedLink(targetContext, targetInterface)
    )
    .join(' · ');
}

function otherContexts(context, item) {
  const others = model.contexts.filter(candidate => candidate !== context);

  if (item.kind === 'role') {
    const present = others.filter(
      candidate => getInterface(candidate.name, item.name)?.kind === 'role'
    );
    const absent = others.filter(candidate => !present.includes(candidate));
    const lines = [];
    if (present.length > 0) {
      lines.push(
        table(
          ['Context', 'Methods'],
          present.map(candidate => [
            link(candidate.name, interfaceLink(candidate.name, item.name)),
            methodNamesCell(getInterface(candidate.name, item.name))
          ])
        )
      );
    } else {
      lines.push(`No other context has a ${item.name} role.`);
    }
    if (absent.length > 0) {
      lines.push(
        `Not declared in ${list(absent.map(candidate => candidate.name))}.`
      );
    }
    return lines.join('\n\n');
  }

  const rows = others.map(candidate => {
    const target = getInterface(candidate.name, item.name);
    if (target?.kind === 'addOn') {
      return [
        link(candidate.name, target.link),
        methodNamesCell(target) || 'empty marker'
      ];
    }
    const rule = notHere[candidate.name]?.[item.name];
    return [
      candidate.name,
      rule
        ? `not here (${rule.reason}) → ${whereLinks(rule.where, item)}`
        : 'not here'
    ];
  });

  const lines = [
    table(['Context', item.methods.length > 0 ? 'Method' : 'Interface'], rows)
  ];
  if (item.name === 'PriorParentQuery' && priorParentNote())
    lines.push(priorParentNote());
  return lines.join('\n\n');
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

function factValue(context, row) {
  const facts = contextFacts[context.name];
  const declared = recordInterface(context);

  switch (row.id) {
    case 'record-type': {
      const base = `${code(shortType(context.recordType))} / ${code(shortType(context.collectionType))}`;
      const extras = context.extraRecordTypes.map(
        extra =>
          `${code(shortType(extra.type))} in ${list(extra.uses.map(use => code(use.method)))}`
      );
      return extras.length > 0 ? `${base}; ${extras.join('; ')}` : base;
    }
    case 'put':
      return facts.put
        ? putFact[facts.put]
        : `not declared on ${code(shortType(context.recordType))}`;
    case 'change-detection':
      return hasMethod(declared, 'isChanged')
        ? `yes: ${code('isChanged')}, ${code('isAnyChanged')}, ${code('isChangedTo')}, ${code('isChangedFrom')}, …`
        : 'none';
    case 'parent-sides': {
      const sides = [];
      if (context.addOns.includes('ParentQuery'))
        sides.push(`new (${code('getNewParent')}, ParentQuery)`);
      if (context.addOns.includes('PriorParentQuery'))
        sides.push(`old (${code('getOldParent')}, PriorParentQuery)`);
      return sides.join('; ') || 'none';
    }
    case 'recursion-guard': {
      if (!context.addOns.includes('RecursionGuard')) return 'none';
      return `default ${recursionDefault} per record; honoured by ${list(honouringRoles(context, 'RecursionGuard'))}`;
    }
    default:
      return facts[row.id];
  }
}

function factsTable(context) {
  return table(
    ['Fact', context.name],
    factRows.map(row => [row.label, factValue(context, row)])
  );
}

function matrixFacts() {
  return table(
    [
      'Fact',
      ...model.contexts.map(context => link(context.name, context.link))
    ],
    factRows.map(row => [
      row.label,
      ...model.contexts.map(context => factValue(context, row))
    ])
  );
}

function recordsSection(context) {
  const receivers = new Map();
  for (const use of context.typeUses.filter(
    entry => entry.category !== 'service'
  )) {
    if (!receivers.has(use.type)) receivers.set(use.type, []);
    const item = getInterface(context.name, use.interfaceName);
    let label = code(
      item.kind === 'support' ? `${item.name}.${use.method}` : use.method
    );
    if (use.category === 'collection')
      label +=
        item.kind === 'support'
          ? ' (every record in the chunk)'
          : ' (the qualified records)';
    if (!receivers.get(use.type).includes(label))
      receivers.get(use.type).push(label);
  }

  const rows = [...receivers.entries()].map(([type, labels]) => [
    code(type),
    [
      ...labels.filter(label => label.includes('every record')),
      ...labels.filter(label => !label.includes('every record'))
    ].join(', ')
  ]);
  return [
    table(['Type', 'Received by'], rows),
    `Every accessor and predicate: ${link(`Record API in ${context.name}`, context.recordApiLink)}.`
  ].join('\n\n');
}

function addOnsTable(context) {
  const rows = model.canonicalAddOns.map(addOn => {
    const item = getInterface(context.name, addOn);
    if (item?.kind === 'addOn') {
      const method =
        item.methods.length > 0 ? methodNamesCell(item) : 'empty marker';
      const onlyFor =
        honouringRoles(context, addOn).length < context.roles.length
          ? ` (${list(honouringRoles(context, addOn))} only)`
          : '';
      return [
        link(addOn, item.link),
        `${method}${onlyFor}`,
        addOnFacts[addOn].purpose
      ];
    }
    const rule = notHere[context.name][addOn];
    return [addOn, 'not here', `${rule.reason} → ${whereLinks(rule.where)}`];
  });

  return [
    table(['Add-on', `In ${context.name}`, 'What it does'], rows),
    `Which roles honour each add-on, and what is not available: ${link(`Add-ons in ${context.name}`, context.addOnsLink)}.`
  ].join('\n\n');
}

function addOnsAvailable(context) {
  const rows = context.addOns.map(addOn => {
    const item = getInterface(context.name, addOn);
    const methods =
      item.methods.length > 0
        ? item.methods
            .map(method =>
              code(
                `${method.name}(${method.params.map(param => shortType(param.type)).join(', ')})`
              )
            )
            .join(' · ')
        : 'empty marker';
    return [
      link(addOn, item.link),
      methods,
      addOnFacts[addOn].purpose,
      list(honouringRoles(context, addOn))
    ];
  });
  return table(['Add-on', 'Method', 'What it does', 'Honoured by'], rows);
}

function addOnsNotAvailable(context) {
  const entries = Object.entries(notHere[context.name]);
  if (entries.length === 0) {
    return `Every add-on is available in ${context.name}.`;
  }
  return table(
    ['Add-on', 'Why not here', 'Use instead'],
    entries.map(([addOn, rule]) => [addOn, rule.reason, whereLinks(rule.where)])
  );
}

function addOnsWorksWith(context) {
  const rows = context.addOns.map(addOn => [
    link(addOn, interfaceLink(context.name, addOn)),
    ...context.roles.map(role => {
      const honoured = honours(context, role).includes(addOn);
      const note = honourNote(context, role, addOn);
      return `${honoured ? 'honoured' : bold('ignored')}${note ? `: ${note}` : ''}`;
    })
  ]);
  return table(
    [
      'Add-on',
      ...context.roles.map(role =>
        link(role, interfaceLink(context.name, role))
      )
    ],
    rows
  );
}

function notAvailable(context) {
  const rows = [];
  const paired = pairedContext(context);

  if (paired) {
    const missing = paired.roles.filter(role => !context.roles.includes(role));
    if (missing.length > 0) {
      rows.push([
        list(missing),
        missing.map(role => qualifiedLink(paired.name, role)).join(' · ')
      ]);
    }
  } else if (unpairedRoles[context.name]) {
    const entry = unpairedRoles[context.name];
    rows.push([list(entry.roles), `none: ${entry.reason}`]);
  }

  for (const [addOn, rule] of Object.entries(notHere[context.name])) {
    rows.push([addOn, `${rule.reason} → ${whereLinks(rule.where)}`]);
  }

  for (const row of universalNotAvailable) {
    rows.push([
      row.what,
      row.where.replace(
        '{bypassable}',
        link(
          `${context.name}.Bypassable`,
          interfaceLink(context.name, 'Bypassable')
        )
      )
    ]);
  }

  return table(['Not here', 'Use instead'], rows);
}

const accessorNotes = {
  getId: context =>
    contextFacts[context.name].idsExist
      ? 'the record Id'
      : `${code('null')}: the record is not saved yet`,
  getNewSObject: context =>
    contextFacts[context.name].put === 'works'
      ? `the ${code('Trigger.new')} row; change it with ${code('put')}`
      : `the ${code('Trigger.new')} row, read-only`,
  getOldSObject: () => `the ${code('Trigger.old')} row, read-only`,
  getNewParent: () =>
    `the parent loaded by ParentQuery, by relationship name (${code('Account')}, ${code('Parent')}, ${code('Owner')}, ${code('Custom__r')}); ${code('null')} when the lookup is empty or the parent was not declared`,
  getOldParent: () =>
    `the parent the old row pointed to, loaded by PriorParentQuery; ${code('null')} when the lookup was empty or the parent was not declared`,
  getRelated: () =>
    `the rows a RelatedQuery provider returned, by provider name; an unknown name throws ${code('TriggerHandler.TriggerHandlerException')}`,
  put: context => putBehaviour[contextFacts[context.name].put],
  'addError/1': () => 'a record-level error',
  'addError/2': () =>
    `a field-level error; on ${code('Name')} and compound-address fields such as ${code('BillingStreet')} the field attribution is lost and the error shows at record level`
};

function accessorKey(method) {
  return method.name === 'addError'
    ? `addError/${method.params.length}`
    : method.name;
}

function accessorRows(context, declared) {
  return declared.accessors.map(method => [
    code(callForm(method)),
    accessorNotes[accessorKey(method)]?.(context) ?? ''
  ]);
}

function accessors(context) {
  const declared = recordInterface(context);
  const lines = [
    table(
      [
        'Accessor',
        `On ${code(shortType(context.recordType))} in ${context.name}`
      ],
      accessorRows(context, declared)
    )
  ];

  for (const extra of context.extraRecordTypes) {
    const extraDeclared = getTriggerHandlerInterface(extra.type);
    const added = extraDeclared.accessors.filter(
      method => !declared.accessors.some(base => base.name === method.name)
    );
    const removed = declared.accessors.filter(
      method =>
        !extraDeclared.accessors.some(other => other.name === method.name)
    );
    lines.push(
      `In ${list(extra.uses.map(use => code(use.method)))} the record is a ${code(extraDeclared.qualifiedName)}: the same predicates and read accessors${
        removed.length > 0
          ? `, no ${list(
              removed.map(method => code(method.name)),
              'or'
            )}`
          : ''
      }, plus:`
    );
    lines.push(
      table(
        ['Accessor', 'Here'],
        added.map(method => [
          code(callForm(method)),
          accessorNotes[accessorKey(method)]?.(context) ?? ''
        ])
      )
    );
  }

  const everyAccessor = new Map();
  for (const other of model.contexts) {
    for (const method of recordInterface(other).accessors) {
      if (!everyAccessor.has(method.name))
        everyAccessor.set(method.name, method);
    }
  }
  const missing = [...everyAccessor.values()].filter(
    method => !hasMethod(declared, method.name)
  );
  if (missing.length > 0) {
    lines.push(
      `Not on ${code(shortType(context.recordType))}: ${list(missing.map(method => code(callForm(method))))}.`
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
  return ordered.map(use => {
    const item = getInterface(context.name, use.interfaceName);
    return item.kind === 'support'
      ? `${code(`${item.name}.${use.method}`)} (every record in the chunk)`
      : `${code(use.method)} (the qualified records)`;
  });
}

function collectionNote(context, method) {
  const facts = contextFacts[context.name];
  const relationship = method.params.length === 2;
  const oldForm = method.name.startsWith('getOld');
  const row = oldForm ? 'old' : facts.rowSide;
  const parentSource = row === 'old' ? 'PriorParentQuery' : 'ParentQuery';
  const hasOldForms = collectionInterface(context).methodNames.some(name =>
    name.startsWith('getOld')
  );
  const pointer =
    !oldForm && hasOldForms && row === 'new'
      ? `; ${code(method.name.replace('get', 'getOld'))} reads the old row`
      : '';

  switch (method.name) {
    case 'getIds':
      return facts.idsExist
        ? 'the record Ids'
        : 'always empty: the records have no Id yet';
    case 'getIdsOf':
    case 'getOldIdsOf':
      return relationship
        ? `Ids in a field of a parent loaded by ${parentSource}, walked by relationship path (${code("'Account'")}, ${code("'Account.Owner'")})`
        : `the non-null Ids in a lookup or Id field of the ${row} row${pointer}`;
    case 'getValuesOf':
    case 'getOldValuesOf':
      return relationship
        ? `values of a field on a parent loaded by ${parentSource}, as strings`
        : `the non-null values of a field on the ${row} row, as strings (${code('String.valueOf')})${pointer}`;
    case 'getRecords':
      return `the records, typed as ${code(shortType(context.recordType))}`;
    case 'size':
      return 'the number of records';
    default:
      return '';
  }
}

function collections(context) {
  const declared = collectionInterface(context);
  const intro = `${code(declared.qualifiedName)} reaches ${list(collectionReceivers(context))}.`;
  const rows = declared.methods.map(method => [
    code(
      `${method.name}(${method.params.map(param => shortType(param.type)).join(', ')})`
    ),
    code(method.returnType),
    collectionNote(context, method)
  ]);
  return [intro, table(['Method', 'Returns', 'Here'], rows)].join('\n\n');
}

function triggerVariables(context) {
  const declared = recordInterface(context);
  const facts = contextFacts[context.name];
  const hasNew = hasMethod(declared, 'getNewSObject');
  const hasOld = hasMethod(declared, 'getOldSObject');
  const absent = `${code('null')} in ${context.name}`;
  const provider = `${code('records.getRecords()')} in a RecordsProvider’s ${code('query')}`;
  const qualified = collectionReceivers(context)
    .filter(label => !label.includes('RecordsProvider'))
    .map(label => label.replace(' (the qualified records)', ''));

  const rows = [];
  rows.push([
    code('Trigger.new'),
    hasNew
      ? `one row per call: ${code('record.getNewSObject()')}; every row of the chunk: ${provider}`
      : absent
  ]);

  if (!hasNew) rows.push([code('Trigger.newMap'), absent]);
  else if (!facts.idsExist)
    rows.push([
      code('Trigger.newMap'),
      `none: ${code('record.getId()')} is ${code('null')} and ${code('records.getIds()')} is empty`
    ]);
  else
    rows.push([
      code('Trigger.newMap'),
      `no map: key by ${code('record.getId()')}; ${code('records.getIds()')} returns the key set`
    ]);

  rows.push([
    code('Trigger.old'),
    hasOld
      ? `one row per call: ${code('record.getOldSObject()')}, read-only`
      : absent
  ]);

  if (!hasOld) rows.push([code('Trigger.oldMap'), absent]);
  else if (hasNew)
    rows.push([
      code('Trigger.oldMap'),
      `no map: ${code('record.getOldSObject()')} is already the old row of this record`
    ]);
  else
    rows.push([
      code('Trigger.oldMap'),
      `no map: key by ${code('record.getId()')}; ${code('records.getIds()')} returns the key set`
    ]);

  if (hasNew && hasOld) {
    rows.push([
      `${code('Trigger.new[i]')} and ${code('Trigger.old[i]')}`,
      'one record, paired by list index, not by Id'
    ]);
  }

  rows.push([
    code('Trigger.size'),
    `${code('records.size()')}: every record in a RecordsProvider’s ${code('query')}; only the qualified records in ${list(qualified.map(label => label))}`
  ]);
  rows.push([
    `${code('Trigger.operationType')}, ${code(context.triggerFlags)}`,
    `${code(`System.TriggerOperation.${context.operationConstant}`)}: the ${code(`${context.name}.*`)} interfaces run`
  ]);

  return table(['Trigger variable', 'In Trigger Lib'], rows);
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
      `the parent the old row pointed to, loaded by PriorParentQuery, or ${code('null')}`
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
    names: ['isRecordTypeEqual', 'isRecordTypeNotEqual'],
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
    const extraDeclared = getTriggerHandlerInterface(extra.type);
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

function collectionMethods(context) {
  const declared = collectionInterface(context);
  return [
    `Type: ${code(declared.qualifiedName)}, passed to ${list(collectionReceivers(context))}.`,
    table(
      ['Method', `In ${context.name}`],
      declared.methods.map(method => [
        code(callForm(method)),
        collectionMethodNote(context, method)
      ])
    )
  ].join('\n\n');
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

const LEGACY_CHIP_ANCHORS = {
  'writer/unit-of-work-methods': 'interface',
  'record-api/collections': 'records',
  'continue-on-error/still-throws': 'good-to-know'
};

function chipKinds() {
  const kinds = [];

  for (const roleName of model.roleNames) {
    const contexts = model.contexts.filter(
      context => getInterface(context.name, roleName)?.kind === 'role'
    );
    kinds.push({
      kind: getInterface(contexts[0].name, roleName).slug,
      targets: contexts.map(context => ({
        context,
        href: interfaceLink(context.name, roleName)
      }))
    });
  }

  for (const addOn of model.canonicalAddOns) {
    const contexts = model.contexts.filter(context =>
      context.addOns.includes(addOn)
    );
    kinds.push({
      kind: getInterface(contexts[0].name, addOn).slug,
      targets: contexts.map(context => ({
        context,
        href: interfaceLink(context.name, addOn)
      }))
    });
  }

  kinds.push({
    kind: 'overview',
    targets: model.contexts.map(context => ({ context, href: context.link }))
  });
  kinds.push({
    kind: 'add-ons',
    targets: model.contexts.map(context => ({
      context,
      href: context.addOnsLink
    }))
  });
  kinds.push({
    kind: 'record-api',
    targets: model.contexts.map(context => ({
      context,
      href: context.recordApiLink
    }))
  });

  return kinds;
}

function chips(files) {
  const kinds = chipKinds();
  for (const entry of kinds) {
    files.set(
      `chips/${entry.kind}.md`,
      entry.targets
        .map(target => link(target.context.name, target.href))
        .join(' · ')
    );
  }

  for (const [path, anchor] of Object.entries(LEGACY_CHIP_ANCHORS)) {
    const entry = kinds.find(
      candidate => candidate.kind === path.split('/')[0]
    );
    files.set(
      `chips/${path}.md`,
      entry.targets
        .map(target => link(target.context.name, `${target.href}#${anchor}`))
        .join(' · ')
    );
  }
}

function legacyFiles() {
  const files = new Map();
  files.set('matrix-facts.md', matrixFacts());
  chips(files);

  for (const context of model.contexts) {
    const folder = context.slug;
    files.set(`${folder}/facts.md`, factsTable(context));
    files.set(`${folder}/records.md`, recordsSection(context));
    files.set(`${folder}/add-ons-table.md`, addOnsTable(context));
    files.set(`${folder}/add-ons-available.md`, addOnsAvailable(context));
    files.set(
      `${folder}/add-ons-not-available.md`,
      addOnsNotAvailable(context)
    );
    files.set(`${folder}/add-ons-works-with.md`, addOnsWorksWith(context));
    files.set(`${folder}/not-available.md`, notAvailable(context));
    files.set(`${folder}/accessors.md`, accessors(context));
    files.set(`${folder}/trigger-variables.md`, triggerVariables(context));
    files.set(`${folder}/collections.md`, collections(context));

    for (const item of pageInterfaces(context)) {
      const base = `${folder}/${item.slug}`;
      files.set(`${base}/method-table.md`, methodTable(context, item));
      files.set(`${base}/available-in.md`, availableIn(context, item));
      files.set(`${base}/works-with.md`, worksWith(context, item));
      files.set(`${base}/other-contexts.md`, otherContexts(context, item));
    }
  }

  return files;
}

const INCLUDE_PATTERN = /<!--\s*@include:\s*(.*?)\s*-->/g;
const UNSCANNED_DIRECTORIES = new Set([
  '.vitepress',
  'generated',
  'node_modules',
  'public'
]);

function markdownSources(directory) {
  const found = [];
  for (const name of readdirSync(directory)) {
    const full = join(directory, name);
    if (statSync(full).isDirectory()) {
      if (!UNSCANNED_DIRECTORIES.has(name))
        found.push(...markdownSources(full));
    } else if (name.endsWith('.md')) {
      found.push(full);
    }
  }
  return found;
}

export function includedGeneratedPaths(websiteDir = WEBSITE_DIR) {
  const generatedDir = join(websiteDir, '_parts', 'generated');
  const included = new Set();
  for (const file of markdownSources(websiteDir)) {
    for (const match of readFileSync(file, 'utf8').matchAll(INCLUDE_PATTERN)) {
      const spec = match[1].replace(/\{\d*,\d*\}$/, '').replace(/#[\w-]+$/, '');
      const target = spec.startsWith('@')
        ? join(websiteDir, spec.slice(spec[1] === '/' ? 2 : 1))
        : join(dirname(file), spec);
      const path = relative(generatedDir, target);
      if (!path.startsWith('..')) included.add(path.split(sep).join('/'));
    }
  }
  return included;
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

  const stillIncluded = includedGeneratedPaths();
  for (const [path, content] of legacyFiles()) {
    if (stillIncluded.has(path) && !files.has(path)) files.set(path, content);
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
