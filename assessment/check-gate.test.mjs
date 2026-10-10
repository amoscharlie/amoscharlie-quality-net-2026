import {test} from 'node:test';
import assert from 'node:assert/strict';
import {checkInputs} from './check-gate.mjs';
import fs from 'node:fs';
const body=JSON.parse(fs.readFileSync('assessment/change-inputs.json')).body;
test('complete inputs pass',()=>assert.doesNotThrow(()=>checkInputs(body)));
for(const field of ['Spec','Acceptance','Design','Tests']) test(`missing ${field} blocks`,()=>assert.throws(()=>checkInputs(body.replace(new RegExp(`^${field}:.*$`,'m'),''))));
test('nonexistent evidence blocks',()=>assert.throws(()=>checkInputs(body.replace('api/spec/requests/result_isolation_spec.rb','missing.test.ts'))));
