// Fills force-app/main/default/dependencies/ with the public SOQL Lib and DML Lib
// classes Trigger Lib needs, at the versions pinned in the package dependencies
// of sfdx-project.json. That way a plain clone of this repo deploys to any org.
//
// Never edit dependencies/ by hand. After bumping a dependency in
// sfdx-project.json, run this and commit the result:
//   npm run build:dependencies
// CI rebuilds the folder and fails when the committed copy does not match.

import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const PACKAGE_DIR = 'force-app';
const TARGET_DIR = join(ROOT, PACKAGE_DIR, 'main', 'default', 'dependencies');
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

function packageDependencies() {
  const project = JSON.parse(
    readFileSync(join(ROOT, 'sfdx-project.json'), 'utf8')
  );
  const packageDir = project.packageDirectories.find(
    dir => dir.path === PACKAGE_DIR
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

rmSync(TARGET_DIR, { recursive: true, force: true });
for (const { name, version, repo } of packageDependencies()) {
  const files = DEPENDENCY_FILES[name];
  if (!files) {
    throw new Error(
      `No DEPENDENCY_FILES entry for "${name}" in scripts/build-dependencies.mjs`
    );
  }
  for (const file of files.flatMap(path => [path, `${path}-meta.xml`])) {
    const url = `https://raw.githubusercontent.com/${OWNER}/${repo}/refs/tags/v${version}/${file}`;
    const target = join(TARGET_DIR, repo, basename(file));
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, await fetchText(url));
  }
  console.log(`${name} ${version} from ${OWNER}/${repo}@v${version}`);
}
