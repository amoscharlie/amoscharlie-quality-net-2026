import fs from 'node:fs';
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
if(process.argv[1]?.endsWith('check-gate.mjs')) {
 const event=JSON.parse(fs.readFileSync(process.env.QUALITY_EVENT_PATH||'assessment/change-inputs.json','utf8'));
 checkInputs(event.pull_request?.body ?? event.body);
 console.log('PASS: spec, acceptance, design and runnable tests are present');
}
