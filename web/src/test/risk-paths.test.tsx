import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { vi, it, expect, beforeEach } from 'vitest';
import SkillPicker from '@/components/assessment/SkillPicker';
import AssessmentEditPage from '@/pages/assessments/AssessmentEditPage';
import VacancyEditPage from '@/pages/vacancies/VacancyEditPage';
import InterviewPage from '@/pages/interview/InterviewPage';
const mocks=vi.hoisted(()=>({taxonomy:vi.fn(),get:vi.fn(),update:vi.fn(),vacancyGet:vi.fn(),vacancyUpdate:vi.fn(),candidate:vi.fn()}));
vi.mock('@/services/skillTaxonomies',()=>({skillTaxonomiesApi:{list:mocks.taxonomy}}));
vi.mock('@/services/assessments',()=>({assessmentsApi:{get:mocks.get,update:mocks.update}}));
vi.mock('@/services/vacancies',()=>({vacanciesApi:{get:mocks.vacancyGet,update:mocks.vacancyUpdate}}));
vi.mock('@/services/sessions',()=>({sessionsApi:{getCandidateInfo:mocks.candidate}}));
vi.mock('@/components/assessment/SkillCard',()=>({default:({index,onRemove,form}:any)=><button type="button" onClick={onRemove}>Remove {form.watch(`skills.${index}.skill_label`)}</button>}));
vi.mock('@/hooks/useAudioCapture',()=>({useAudioCapture:()=>({start:vi.fn(),stop:vi.fn(),mute:vi.fn(),unmute:vi.fn()})}));
vi.mock('@/hooks/useAudioPlayback',()=>({useAudioPlayback:()=>({playChunk:vi.fn(),stop:vi.fn(),scheduleAfterPlayback:vi.fn(),waitForDrain:vi.fn(),cancelDrain:vi.fn()})}));
vi.mock('@/hooks/useAudioWebSocket',()=>({useAudioWebSocket:()=>({connect:vi.fn(),send:vi.fn(),sendJson:vi.fn(),disconnect:vi.fn(),connectionState:'disconnected'})}));
vi.mock('@/components/HardwareCheck',()=>({default:()=> <div>Hardware</div>}));
function page(element:any,path:string){return render(<MemoryRouter initialEntries={[path]}><Routes><Route path="/assessments/:id/edit" element={element}/><Route path="/vacancies/:id/edit" element={element}/><Route path="/interview/:token" element={element}/><Route path="*" element={<div>Saved</div>}/></Routes></MemoryRouter>)}
beforeEach(()=>{vi.clearAllMocks();mocks.update.mockResolvedValue({});mocks.vacancyUpdate.mockResolvedValue({});});
it('A04 preserves canonical taxonomy identity and excluded scope',async()=>{
 mocks.taxonomy.mockResolvedValue({data:{skill_taxonomies:[{skill_id:'SK-ENG-001',skill_label:'Frontend',scope_include:'UI',scope_exclude:'Backend'}]}});
 const select=vi.fn();render(<SkillPicker open onOpenChange={vi.fn()} onSelect={select}/>);
 fireEvent.click(await screen.findByRole('button',{name:'Frontend'}));
 expect(select).toHaveBeenCalledWith(expect.objectContaining({skill_id:'SK-ENG-001',scope_exclude:'Backend'}));
});
it('A03 sends an assessment deletion and retains the other database identity',async()=>{
 mocks.get.mockResolvedValue({data:{assessment:{name:'Engineer',time_limit_min:45,skills:[{id:11,skill_label:'Frontend'},{id:12,skill_label:'Backend'}]}}});
 page(<AssessmentEditPage/>,'/assessments/1/edit');fireEvent.click(await screen.findByRole('button',{name:'Remove Frontend'}));fireEvent.click(screen.getByRole('button',{name:'Save Changes'}));
 await waitFor(()=>expect(mocks.update).toHaveBeenCalled());
 expect(mocks.update.mock.calls[0][1].assessment_skills_attributes).toEqual(expect.arrayContaining([expect.objectContaining({id:11,_destroy:true}),expect.objectContaining({id:12})]));
});
it('A03 sends a vacancy deletion to the API',async()=>{
 mocks.vacancyGet.mockResolvedValue({data:{vacancy:{role_title:'Engineer',culture_dimensions:'',competency_expectations:'',skills:[{id:21,skill_label:'Frontend',expected_level:3}]}}});
 const view=page(<VacancyEditPage/>,'/vacancies/1/edit');await screen.findByText('Frontend');
 const remove=view.container.querySelector('form button[type="button"]')!;fireEvent.click(remove);fireEvent.click(screen.getByRole('button',{name:'Save Changes'}));
 await waitFor(()=>expect(mocks.vacancyUpdate).toHaveBeenCalled());
 expect(mocks.vacancyUpdate.mock.calls[0][1].vacancy_skills_attributes).toEqual(expect.arrayContaining([expect.objectContaining({id:21,_destroy:true})]));
});
it('A07 does not claim an invalid invite has a recorded interview',async()=>{
 mocks.candidate.mockRejectedValue(new Error('404'));page(<InterviewPage/>,'/interview/invalid');
 await waitFor(()=>expect(screen.queryByText('Hardware')).not.toBeInTheDocument());
 expect(screen.queryByText('Interview Complete')).not.toBeInTheDocument();
 expect(screen.getByRole('alert')).toHaveTextContent(/unable|failed|unavailable/i);
});

it('A08 shows the API expected level in the Required column',async()=>{
 const {default:ComparisonTable}=await import('@/components/fitgap/ComparisonTable');
 const view=render(<ComparisonTable comparisons={[{skill_label:'Frontend',expected_level:3,candidate_level:2,result:'gap',delta:-1} as any]}/>);
 expect(view.container.querySelectorAll('tbody td')[1]).toHaveTextContent('L3');
});

it('A07 reloaded failed termination does not claim successful recording',async()=>{
 mocks.candidate.mockResolvedValue({data:{session_id:1,role_title:'Engineer',time_limit_min:10,session_status:'ended',end_reason:'error'}});
 page(<InterviewPage/>,'/interview/failed-session');
 await waitFor(()=>expect(screen.queryByText('Hardware')).not.toBeInTheDocument());
 expect(screen.queryByText('Interview Complete')).not.toBeInTheDocument();
 expect(screen.getByRole('alert')).toBeInTheDocument();
});
