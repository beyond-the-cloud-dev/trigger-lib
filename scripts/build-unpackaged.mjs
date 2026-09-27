// Builds unpackaged/, the source variant of Trigger Lib for orgs that deploy the
// code instead of installing the package:
//   - every class from force-app/ with `global` turned into `public`
//   - the public SOQL Lib and DML Lib classes it needs, at the versions pinned in
//     the package dependencies of sfdx-project.json
//
// force-app/ is the only source that is edited by hand. Run this after changing it
// or after bumping a dependency, and commit the result:
//   npm run build:unpackaged
// CI rebuilds unpackaged/ and fails when the committed copy is out of date.

import {
  mkdirSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync
} from 'node:fs';
import { basename, dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const SOURCE_DIR = 'force-app';
const TARGET_DIR = 'unpackaged';
const OWNER = 'beyond-the-cloud-dev';

// Public files of each dependency that Trigger Lib needs, as paths in that repo.
// A new dependency in sfdx-project.json has to be added here too.
const DEPENDENCY_FILES = {
  'SOQL Lib': [
    'force-app/main/default/classes/standard-soql/SOQL.cls',
    'force-app/main/default/classes/standard-soql/SOQL_Test.cls'
  ],
  'DML Lib': [
    'force-app/main/default/classes/DML.cls',
    'force-app/main/default/classes/DML_Test.cls'
  ]
};

const DECLARATION_GLOBAL = /^(\s*)global\b/gm;
const ANY_GLOBAL = /\bglobal\b/;

function listFiles(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const path = join(dir, entry.name);
    return entry.isDirectory() ? listFiles(path) : [path];
  });
}

function write(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}

function copySource() {
  const sourceRoot = join(ROOT, SOURCE_DIR);
  for (const file of listFiles(sourceRoot)) {
    let content = readFileSync(file, 'utf8');
    if (file.endsWith('.cls')) {
      content = content.replace(DECLARATION_GLOBAL, '$1public');
      if (ANY_GLOBAL.test(content)) {
        throw new Error(
          `${relative(ROOT, file)} still has "global" outside a declaration start; extend build-unpackaged.mjs`
        );
      }
    }
    write(join(ROOT, TARGET_DIR, relative(sourceRoot, file)), content);
  }
}

function packageDependencies() {
  const project = JSON.parse(
    readFileSync(join(ROOT, 'sfdx-project.json'), 'utf8')
  );
  const packageDir = project.packageDirectories.find(
    dir => dir.path === SOURCE_DIR
  );
  return (packageDir.dependencies ?? []).map(
    ({ package: alias, versionNumber }) => {
      const [name, aliasVersion] = alias.split('@');
      const version = (aliasVersion ?? versionNumber ?? '').match(
        /^\d+\.\d+\.\d+/
      )?.[0];
      if (!version) {
        throw new Error(`Cannot read a version from dependency "${alias}"`);
      }
      return { name, version, repo: name.toLowerCase().replaceAll(' ', '-') };
    }
  );
}

async function fetchText(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`${response.status} for ${url}`);
  }
  return response.text();
}

async function copyDependencies() {
  for (const { name, version, repo } of packageDependencies()) {
    const files = DEPENDENCY_FILES[name];
    if (!files) {
      throw new Error(
        `No DEPENDENCY_FILES entry for "${name}" in scripts/build-unpackaged.mjs`
      );
    }
    for (const file of files.flatMap(path => [path, `${path}-meta.xml`])) {
      const url = `https://raw.githubusercontent.com/${OWNER}/${repo}/refs/tags/v${version}/${file}`;
      write(
        join(
          ROOT,
          TARGET_DIR,
          'main/default/dependencies',
          repo,
          basename(file)
        ),
        await fetchText(url)
      );
    }
    console.log(`${name} ${version} from ${OWNER}/${repo}@v${version}`);
  }
}

rmSync(join(ROOT, TARGET_DIR), { recursive: true, force: true });
copySource();
await copyDependencies();
console.log(`${TARGET_DIR}/ built from ${SOURCE_DIR}/`);
