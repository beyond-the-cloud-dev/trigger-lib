import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const REPO_ROOT = fileURLToPath(new URL('../../', import.meta.url));
export const WEBSITE_DIR = join(REPO_ROOT, 'website');
export const CLASSES_DIR = join(
  REPO_ROOT,
  'force-app',
  'main',
  'default',
  'classes'
);

const INTERFACE_PATTERN =
  /public\s+interface\s+(\w+)(?:\s+extends\s+([\w.]+))?\s*\{([^}]*)\}/g;
const METHOD_PATTERN = /^([\w.<>,\s[\]]+?)\s+(\w+)\s*\(([\s\S]*)\)$/;
const CONTEXT_NAME_PATTERN = /^(Before|After)([A-Z]\w*)$/;
const REGISTRATION_RETURN_PATTERN = /^List<(\w+)\.(\w+)>$/;
const CLASS_HEADER_PATTERN =
  /\b(?:public|private|global)\s+(?:(?:abstract|virtual|inherited|with|without|sharing)\s+)*class\s+(\w+)[^{;]*\{/g;

export function kebab(name) {
  return name.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
}

export function simpleType(type) {
  return type.replace(/\bTriggerTypes\./g, '');
}

function stripComments(source) {
  let result = '';
  let index = 0;

  while (index < source.length) {
    const char = source[index];
    const next = source[index + 1];

    if (char === "'") {
      const start = index;
      index++;
      while (index < source.length && source[index] !== "'") {
        index += source[index] === '\\' ? 2 : 1;
      }
      index++;
      result += source.slice(start, index);
    } else if (char === '/' && next === '/') {
      while (index < source.length && source[index] !== '\n') {
        index++;
      }
    } else if (char === '/' && next === '*') {
      const end = source.indexOf('*/', index + 2);
      index = end === -1 ? source.length : end + 2;
    } else {
      result += char;
      index++;
    }
  }

  return result;
}

function splitTopLevel(text, separator) {
  const parts = [];
  let depth = 0;
  let current = '';

  for (const char of text) {
    if (char === '<') depth++;
    if (char === '>') depth--;
    if (char === separator && depth === 0) {
      parts.push(current);
      current = '';
    } else {
      current += char;
    }
  }

  parts.push(current);
  return parts.map(part => part.trim()).filter(Boolean);
}

function normalizeType(type) {
  return type
    .replace(/\s+/g, ' ')
    .replace(/\s*<\s*/g, '<')
    .replace(/\s*>/g, '>')
    .replace(/\s*,\s*/g, ', ')
    .trim();
}

function parseParam(param) {
  const match = param.match(/^([\s\S]+?)\s+(\w+)$/);
  if (!match) {
    throw new Error(`apex-api: cannot parse parameter "${param}"`);
  }
  return { type: normalizeType(match[1]), name: match[2] };
}

function parseMethods(body, interfaceName) {
  return body
    .split(';')
    .map(statement => statement.replace(/\s+/g, ' ').trim())
    .filter(Boolean)
    .map(statement => {
      const match = statement.match(METHOD_PATTERN);
      if (!match) {
        throw new Error(
          `apex-api: cannot parse method "${statement}" in interface ${interfaceName}`
        );
      }
      const returnType = normalizeType(match[1]);
      const params = splitTopLevel(match[3], ',').map(parseParam);
      return {
        returnType,
        name: match[2],
        params,
        signature: `${returnType} ${match[2]}(${params.map(param => `${param.type} ${param.name}`).join(', ')})`
      };
    });
}

export function parseInterfaces(source) {
  const stripped = stripComments(source);
  const interfaces = [];

  for (const match of stripped.matchAll(INTERFACE_PATTERN)) {
    interfaces.push({
      name: match[1],
      extends: match[2] ? match[2].split('.').pop() : null,
      methods: parseMethods(match[3], match[1])
    });
  }

  return interfaces;
}

function readClass(name) {
  return readFileSync(join(CLASSES_DIR, `${name}.cls`), 'utf8');
}

function referencesType(type, contextName, interfaceName) {
  return new RegExp(
    `(?:^|[^\\w.])(?:${contextName}\\.)?${interfaceName}\\b`
  ).test(type);
}

function parseRegistrations(source) {
  return parseInterfaces(source)
    .filter(
      declared =>
        declared.methods.length === 1 && declared.methods[0].params.length === 0
    )
    .map(declared => ({
      declared,
      match: declared.methods[0].returnType.match(REGISTRATION_RETURN_PATTERN)
    }))
    .filter(
      ({ declared, match }) =>
        match &&
        match[1] === declared.name &&
        CONTEXT_NAME_PATTERN.test(declared.name)
    )
    .map(({ declared, match }) => ({
      interfaceName: declared.name,
      qualifiedName: `TriggerOrchestrator.${declared.name}`,
      baseInterface: match[2],
      method: declared.methods[0]
    }));
}

function classifyTriggerTypesInterface(declared) {
  const methodNames = declared.methods.map(method => method.name);
  if (methodNames.includes('getRecords') && methodNames.includes('size'))
    return 'collection';
  if (methodNames.includes('getId')) return 'record';
  return 'service';
}

function parseTriggerTypes() {
  const interfaces = new Map();
  for (const declared of parseInterfaces(readClass('TriggerTypes'))) {
    const category = classifyTriggerTypesInterface(declared);
    const methodNames = [
      ...new Set(declared.methods.map(method => method.name))
    ];
    interfaces.set(`TriggerTypes.${declared.name}`, {
      ...declared,
      qualifiedName: `TriggerTypes.${declared.name}`,
      category,
      methodNames
    });
  }
  return interfaces;
}

function buildContext(registration, triggerTypes) {
  const name = registration.interfaceName;
  const [, phase, operation] = name.match(CONTEXT_NAME_PATTERN);
  const slug = kebab(name);
  const declared = parseInterfaces(readClass(name));
  const byName = new Map(declared.map(item => [item.name, item]));
  const base = byName.get(registration.baseInterface);

  if (!base) {
    throw new Error(
      `apex-api: ${name}.cls declares no ${registration.baseInterface} interface, which TriggerOrchestrator.${name} registers`
    );
  }

  const baseIsMarker = base.methods.length === 0;
  const roleNames = [
    ...(baseIsMarker ? [] : [base.name]),
    ...declared
      .filter(item => item.extends === base.name)
      .map(item => item.name)
  ];

  const referencedBy = new Map();
  for (const item of declared) {
    for (const method of item.methods) {
      for (const type of [
        method.returnType,
        ...method.params.map(param => param.type)
      ]) {
        for (const other of declared) {
          if (other !== item && referencesType(type, name, other.name)) {
            if (!referencedBy.has(other.name)) referencedBy.set(other.name, []);
            if (!referencedBy.get(other.name).includes(item.name))
              referencedBy.get(other.name).push(item.name);
          }
        }
      }
    }
  }

  const interfaces = declared.map(item => {
    let kind = 'addOn';
    if (item === base && baseIsMarker) kind = 'marker';
    else if (roleNames.includes(item.name)) kind = 'role';
    else if (referencedBy.has(item.name)) kind = 'support';

    return {
      ...item,
      kind,
      context: name,
      qualifiedName: `${name}.${item.name}`,
      slug: kebab(item.name),
      supportFor: kind === 'support' ? referencedBy.get(item.name) : [],
      supports: []
    };
  });

  for (const item of interfaces) {
    for (const owner of item.supportFor) {
      interfaces
        .find(candidate => candidate.name === owner)
        .supports.push(item.name);
    }
  }

  for (const item of interfaces) {
    if (item.kind === 'role') {
      item.pagePath = `${slug}/${item.slug}`;
      item.link = `/${item.pagePath}`;
    } else if (item.kind === 'addOn') {
      item.pagePath = `${slug}/add-ons/${item.slug}`;
      item.link = `/${item.pagePath}`;
    } else {
      item.pagePath = null;
      item.link = null;
    }
  }

  for (const item of interfaces) {
    if (item.kind === 'support') {
      const owner = interfaces.find(
        candidate => candidate.name === item.supportFor[0]
      );
      item.link = owner.link ? `${owner.link}#${item.slug}` : null;
    }
  }

  const roles = interfaces.filter(item => item.kind === 'role');
  const addOns = interfaces.filter(item => item.kind === 'addOn');
  const supports = interfaces.filter(item => item.kind === 'support');
  const marker = interfaces.find(item => item.kind === 'marker') ?? null;

  const typeUses = [];
  for (const item of [...roles, ...addOns, ...supports]) {
    for (const method of item.methods) {
      for (const param of method.params) {
        const declaredType = triggerTypes.get(param.type);
        if (declaredType) {
          typeUses.push({
            type: param.type,
            category: declaredType.category,
            interfaceName: item.name,
            kind: item.kind,
            method: method.name
          });
        }
      }
    }
  }

  const predicate = roles[0]?.methods.find(
    method => method.returnType === 'Boolean' && method.params.length === 1
  );
  if (!predicate) {
    throw new Error(
      `apex-api: ${name}.cls has no role with a Boolean predicate method`
    );
  }

  const recordType = predicate.params[0].type;
  const collectionTypes = [
    ...new Set(
      typeUses.filter(use => use.category === 'collection').map(use => use.type)
    )
  ];
  if (collectionTypes.length !== 1) {
    throw new Error(
      `apex-api: ${name}.cls should use exactly one TriggerTypes collection type, found ${collectionTypes.join(', ') || 'none'}`
    );
  }

  const extraRecordTypes = [];
  for (const use of typeUses) {
    if (use.category === 'record' && use.type !== recordType) {
      const existing = extraRecordTypes.find(extra => extra.type === use.type);
      if (existing)
        existing.uses.push({
          interfaceName: use.interfaceName,
          method: use.method
        });
      else
        extraRecordTypes.push({
          type: use.type,
          uses: [{ interfaceName: use.interfaceName, method: use.method }]
        });
    }
  }

  return {
    name,
    slug,
    phase,
    operation,
    triggerEvent: `${phase.toLowerCase()} ${operation.toLowerCase()}`,
    file: `force-app/main/default/classes/${name}.cls`,
    link: `/${slug}/`,
    addOnsLink: `/${slug}/add-ons/`,
    recordApiLink: `/${slug}/record-api`,
    registration: {
      interfaceName: registration.qualifiedName,
      method: registration.method,
      handlerType: `${name}.${base.name}`
    },
    baseInterface: base.name,
    marker: marker?.name ?? null,
    interfaces,
    roles: roles.map(item => item.name),
    addOns: addOns.map(item => item.name),
    supports: supports.map(item => item.name),
    recordType,
    extraRecordTypes,
    collectionType: collectionTypes[0],
    typeUses
  };
}

function mergeOrder(sequences) {
  const order = [];

  for (const sequence of sequences) {
    let previous = -1;
    for (const item of sequence) {
      const at = order.indexOf(item);
      if (at === -1) {
        order.splice(previous + 1, 0, item);
        previous = previous + 1;
      } else if (at < previous) {
        throw new Error(
          `apex-api: add-on order conflict at ${item}; every context must declare add-ons in the same relative order`
        );
      } else {
        previous = at;
      }
    }
  }

  return order;
}

function buildModel() {
  const triggerTypes = parseTriggerTypes();
  const registrations = parseRegistrations(readClass('TriggerOrchestrator'));

  if (registrations.length === 0) {
    throw new Error(
      'apex-api: no registration interfaces found in TriggerOrchestrator.cls'
    );
  }

  const contexts = registrations.map(registration =>
    buildContext(registration, triggerTypes)
  );
  const canonicalAddOns = mergeOrder(contexts.map(context => context.addOns));

  for (const context of contexts) {
    context.addOns.sort(
      (left, right) =>
        canonicalAddOns.indexOf(left) - canonicalAddOns.indexOf(right)
    );
  }

  const leadingInterfaces = [];
  for (const context of contexts) {
    for (const item of context.interfaces) {
      if (
        (item.kind === 'role' || item.kind === 'marker') &&
        !leadingInterfaces.includes(item.name)
      ) {
        leadingInterfaces.push(item.name);
      }
    }
  }

  const matrixRows = [...leadingInterfaces];
  for (const name of canonicalAddOns) {
    matrixRows.push(name);
    for (const context of contexts) {
      for (const support of context.interfaces.filter(
        item => item.kind === 'support' && item.supportFor.includes(name)
      )) {
        if (!matrixRows.includes(support.name)) matrixRows.push(support.name);
      }
    }
  }

  const roleNames = [];
  for (const context of contexts) {
    for (const role of context.roles) {
      if (!roleNames.includes(role)) roleNames.push(role);
    }
  }

  const methodNames = new Set();
  for (const context of contexts) {
    methodNames.add(context.registration.method.name);
    for (const item of context.interfaces) {
      for (const method of item.methods) methodNames.add(method.name);
    }
  }

  return {
    contexts,
    canonicalAddOns,
    roleNames,
    matrixRows,
    methodNames,
    triggerTypes
  };
}

export const model = buildModel();

export function getContext(name) {
  return model.contexts.find(context => context.name === name);
}

export function getInterface(contextName, interfaceName) {
  return getContext(contextName)?.interfaces.find(
    item => item.name === interfaceName
  );
}

export function getTriggerTypesInterface(type) {
  return model.triggerTypes.get(
    type.startsWith('TriggerTypes.') ? type : `TriggerTypes.${type}`
  );
}

export function pageLink(contextName, interfaceName, anchor) {
  const context = getContext(contextName);
  if (!context) return null;
  const base = interfaceName
    ? (getInterface(contextName, interfaceName)?.link ?? null)
    : context.link;
  if (!base || !anchor) return base;
  return base.includes('#') ? base : `${base}#${anchor}`;
}

export function expectedPages() {
  const pages = [];

  for (const context of model.contexts) {
    pages.push({
      path: `${context.slug}/index.md`,
      link: context.link,
      template: 'context',
      context: context.name
    });
    for (const role of context.roles) {
      const item = getInterface(context.name, role);
      pages.push({
        path: `${item.pagePath}.md`,
        link: item.link,
        template: 'role',
        context: context.name,
        interface: role
      });
    }
    pages.push({
      path: `${context.slug}/add-ons/index.md`,
      link: context.addOnsLink,
      template: 'add-ons',
      context: context.name
    });
    for (const addOn of context.addOns) {
      const item = getInterface(context.name, addOn);
      pages.push({
        path: `${item.pagePath}.md`,
        link: item.link,
        template: 'add-on',
        context: context.name,
        interface: addOn
      });
    }
    pages.push({
      path: `${context.slug}/record-api.md`,
      link: context.recordApiLink,
      template: 'record-api',
      context: context.name
    });
  }

  return pages;
}

function extractClassBodies(source) {
  const bodies = new Map();

  for (const match of source.matchAll(CLASS_HEADER_PATTERN)) {
    const start = match.index + match[0].length;
    let depth = 1;
    let index = start;

    while (index < source.length && depth > 0) {
      const char = source[index];
      if (char === "'") {
        index++;
        while (index < source.length && source[index] !== "'") {
          index += source[index] === '\\' ? 2 : 1;
        }
      } else if (char === '{') {
        depth++;
      } else if (char === '}') {
        depth--;
      }
      index++;
    }

    bodies.set(match[1], source.slice(start, index - 1));
  }

  return bodies;
}

export function parseAdapterHonours() {
  const bodies = extractClassBodies(
    stripComments(readClass('TriggerOrchestrator'))
  );
  const honours = {};

  for (const context of model.contexts) {
    honours[context.name] = {};

    for (const role of context.roles) {
      const adapterName = `${context.name}${role}Adapter`;
      if (!bodies.has(adapterName)) {
        throw new Error(
          `apex-api: TriggerOrchestrator.cls has no ${adapterName}`
        );
      }

      const visited = new Set();
      const queue = [adapterName];
      const found = new Set();

      while (queue.length > 0) {
        const className = queue.shift();
        if (visited.has(className)) continue;
        visited.add(className);
        const body = bodies.get(className);

        for (const match of body.matchAll(
          new RegExp(`instanceof\\s+${context.name}\\.(\\w+)`, 'g')
        )) {
          if (context.addOns.includes(match[1])) found.add(match[1]);
        }

        for (const match of body.matchAll(/\bnew\s+(\w+)\s*\(/g)) {
          if (bodies.has(match[1]) && !visited.has(match[1]))
            queue.push(match[1]);
        }
      }

      honours[context.name][role] = model.canonicalAddOns.filter(addOn =>
        found.has(addOn)
      );
    }
  }

  return honours;
}

const docs = {
  text: 'Docs',
  items: [
    { text: 'Introduction', link: '/introduction' },
    { text: 'Installation', link: '/installation' },
    { text: 'Your First Handler', link: '/guide/first-handler' },
    { text: 'Trigger & Orchestrator', link: '/guide/orchestrator' },
    { text: 'Contexts at a Glance', link: '/contexts' },
    { text: 'Design Principles', link: '/introduction/design-principles' }
  ]
};

const advanced = {
  text: 'Advanced',
  collapsed: true,
  items: [
    { text: 'Execution Order & Cost', link: '/guide/execution-order' },
    { text: 'Bypassing', link: '/guide/bypasses' },
    { text: 'Unit of Work', link: '/guide/unit-of-work' },
    { text: 'Errors & Logging', link: '/guide/error-handling' },
    { text: 'RelatedQuery Recipes', link: '/guide/related-query' },
    { text: 'Testing', link: '/guide/testing' }
  ]
};

const api = {
  text: 'API',
  collapsed: true,
  items: [
    { text: 'TriggerOrchestrator', link: '/api/trigger-orchestrator' },
    { text: 'Record API', link: '/api/record' },
    { text: 'Record Collections', link: '/api/record-collections' },
    { text: 'TriggerTypes.ParentFields', link: '/api/parent-fields' },
    { text: 'RelatedRecords & RecordsProvider', link: '/api/related-records' },
    { text: 'TriggerTypes.UnitOfWork', link: '/api/unit-of-work' },
    { text: 'Custom Metadata', link: '/api/custom-metadata' }
  ]
};

function interfaceLeaf(context, interfaceName) {
  const item = getInterface(context.name, interfaceName);
  return {
    text: interfaceName,
    link: item.link,
    docFooterText: item.qualifiedName
  };
}

function contextGroup(context) {
  const items = context.roles.map(role => interfaceLeaf(context, role));

  if (context.addOns.length > 0) {
    items.push({
      text: 'Add-ons',
      link: context.addOnsLink,
      docFooterText: `Add-ons in ${context.name}`,
      collapsed: true,
      items: context.addOns.map(addOn => interfaceLeaf(context, addOn))
    });
  }

  items.push({
    text: 'Record API',
    link: context.recordApiLink,
    docFooterText: `Record API in ${context.name}`
  });

  return { text: context.name, link: context.link, collapsed: false, items };
}

function buildSidebar() {
  const contextItems = model.contexts.map(context => contextGroup(context));

  return [docs, ...contextItems, advanced, api];
}

function buildNav() {
  return [{ text: 'Docs', link: '/introduction', activeMatch: '^/.+' }];
}

export const sidebar = buildSidebar();
export const nav = buildNav();

function withIndexLeaf(item, text) {
  const { link, ...group } = item;
  return {
    ...group,
    items: [{ text, link: `${link.replace(/\/$/, '')}/index` }, ...item.items]
  };
}

export function addOverviewLeaves(configSidebar) {
  const source = configSidebar ?? sidebar;

  if (!Array.isArray(source)) {
    return source;
  }

  const contextsByLink = new Map(
    model.contexts.map(context => [context.link, context])
  );

  return source.map(item => {
    const context = contextsByLink.get(item.link);

    if (context && Array.isArray(item.items)) {
      const items = item.items.map(child =>
        child.link === context.addOnsLink && Array.isArray(child.items)
          ? withIndexLeaf(child, `Add-ons in ${context.name}`)
          : child
      );
      return withIndexLeaf({ ...item, items }, context.name);
    }

    if (!Array.isArray(item.items) && item.link) {
      return { text: item.text, items: [{ text: item.text, link: item.link }] };
    }

    return item;
  });
}
