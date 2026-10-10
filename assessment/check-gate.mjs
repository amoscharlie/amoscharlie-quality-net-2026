import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
export function checkInputs(body) {
 for (const field of ['Spec','Acceptance','Design','Tests']) {
  const value=body.match(new RegExp(`^${field}:\\s*(.+)$`,'m'))?.[1]?.trim();
  if(!value) throw Error(`Missing ${field} input`);
  const file=value.split('#')[0];
  if(file.includes('..') || file.startsWith('/') || !fs.existsSync(file) || !fs.statSync(file).isFile()) throw Error(`Invalid ${field} path`);
  if(field==='Tests' && !/(spec\/.*_spec\.rb|.*\.test\.tsx?)$/.test(file)) throw Error('Tests must link a runnable regression check');
  if(!fs.readFileSync(file,'utf8').trim()) throw Error(`Empty ${field} input`);
 }
}
export function checkChangedFiles(files) {
 const production=files.some(f=> /^(api\/app\/|web\/src\/)/.test(f) && !/(spec|test)\//.test(f) && !/\.test\./.test(f));
 const test=files.some(f=> /api\/spec\/.*_spec\.rb$|web\/src\/.*\.test\.tsx?$/.test(f));
 if(production && !test) throw Error('Production change requires a changed regression check');
}
if(process.argv[1]?.endsWith('check-gate.mjs')) {
 const event=JSON.parse(fs.readFileSync(process.env.QUALITY_EVENT_PATH||'assessment/change-inputs.json','utf8'));
 checkInputs(event.pull_request?.body ?? event.body);
 if(event.pull_request) {
  const files=execFileSync('git',['diff','--name-only',`${event.pull_request.base.sha}...${event.pull_request.head.sha}`],{encoding:'utf8'}).trim().split('\n');
  checkChangedFiles(files);
 }
 console.log('PASS: spec, acceptance, design and runnable tests are present');
}
