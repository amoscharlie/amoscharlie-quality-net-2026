import {test} from 'node:test';
import assert from 'node:assert/strict';
import {decide} from './check-release.mjs';
const ready={risks:[{id:'x',severity:'P1',status:'fixed'}],requiredChecks:[{id:'live',status:'passed'}]};
test('verified fixed release passes',()=>assert.equal(decide(ready).decision,'RELEASABLE'));
test('open P1 blocks',()=>assert.equal(decide({...ready,risks:[{id:'x',severity:'P1',status:'open'}]}).decision,'BLOCKED'));
test('unverified critical acceptance blocks even green tests',()=>assert.equal(decide({...ready,requiredChecks:[{id:'live',status:'pending'}]}).decision,'BLOCKED'));
test('owner acceptance needs evidence',()=>assert.equal(decide({...ready,risks:[{id:'x',severity:'P1',status:'accepted',acceptedBy:'Owner'}]}).decision,'BLOCKED'));
test('documented owner acceptance may pass',()=>assert.equal(decide({...ready,risks:[{id:'x',severity:'P1',status:'accepted',acceptedBy:'Owner',acceptanceEvidence:'signed-note'}]}).decision,'RELEASABLE'));
