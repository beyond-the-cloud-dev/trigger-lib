// Turns force-app/ into the package source, in place. Run it only on a throwaway
// checkout (CI), never on your working copy:
//   - drops main/default/dependencies/: SOQL Lib and DML Lib come in as package
//     dependencies declared in sfdx-project.json
//   - every declaration with a `// global` line right above it becomes global
//     (@TestVisible on it is dropped, it means nothing on a global member)
//
// The repo keeps the public source, so a plain clone deploys to any org. The
// `// global` markers are the package API: add one when a new type or member has
// to be visible to orgs that install the package.

import { readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const SOURCE_DIR = join(ROOT, 'force-app');
const DEPENDENCIES_DIR = join(SOURCE_DIR, 'main', 'default', 'dependencies');

const MARKER = /^\s*\/\/ global\s*$/;
const TEST_VISIBLE = /^\s*@TestVisible\s*$/i;
const ANNOTATION = /^\s*@\w+/;
const DECLARATION = /^(\s*)(public|private)\b/;

function listClasses(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) {
      return listClasses(path);
    }
    return path.endsWith('.cls') ? [path] : [];
  });
}

function globalize(file) {
  const out = [];
  let marked = false;
  let count = 0;
  readFileSync(file, 'utf8')
    .split('\n')
    .forEach((line, index) => {
      if (MARKER.test(line)) {
        marked = true;
        out.push(line);
        return;
      }
      if (!marked) {
        out.push(line);
        return;
      }
      if (TEST_VISIBLE.test(line)) {
        return;
      }
      if (ANNOTATION.test(line)) {
        out.push(line);
        return;
      }
      if (!DECLARATION.test(line)) {
        throw new Error(
          `${relative(ROOT, file)}:${index + 1}: "// global" is not followed by a public or private declaration`
        );
      }
      out.push(line.replace(DECLARATION, '$1global'));
      marked = false;
      count++;
    });
  if (marked) {
    throw new Error(
      `${relative(ROOT, file)}: "// global" at the end of the file`
    );
  }
  writeFileSync(file, out.join('\n'));
  return count;
}

rmSync(DEPENDENCIES_DIR, { recursive: true, force: true });
const total = listClasses(SOURCE_DIR).reduce(
  (sum, file) => sum + globalize(file),
  0
);
console.log(`${total} declarations made global, dependencies/ removed`);
