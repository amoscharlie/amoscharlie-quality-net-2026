import fs from 'node:fs';
export function decide(register) {
 const blockers=register.risks.filter(r=>['P0','P1'].includes(r.severity) && r.status!=='fixed' && !(r.status==='accepted' && r.acceptedBy && r.acceptanceEvidence));
 const unverified=register.requiredChecks.filter(c=>c.status!=='passed');
 return {decision:blockers.length||unverified.length?'BLOCKED':'RELEASABLE',blockers:blockers.map(r=>r.id),unverified:unverified.map(c=>c.id)};
}
if(process.argv[1]?.endsWith('check-release.mjs')) {
 const result=decide(JSON.parse(fs.readFileSync('assessment/risk-register.json')));
 console.log(JSON.stringify({tag:process.env.GITHUB_REF_NAME||'local-candidate',...result},null,2));
 if(process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,`Release decision: **${result.decision}**\nUnverified: ${result.unverified.join(', ')}\n`);
 if(result.decision==='BLOCKED') process.exitCode=1;
}
