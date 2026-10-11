import { act, render, screen } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { beforeEach, afterEach, it, expect, vi } from 'vitest';
import InterviewPage from '@/pages/interview/InterviewPage';
const m=vi.hoisted(()=>({audioComplete:vi.fn(),candidate:vi.fn(),state:null as any,stop:vi.fn(),playStop:vi.fn(),disconnect:vi.fn(),drain:vi.fn(),cancel:vi.fn()}));
vi.mock('@/services/sessions',()=>({sessionsApi:{getCandidateInfo:m.candidate,audioComplete:m.audioComplete}}));
vi.mock('@/hooks/useAudioCapture',()=>({useAudioCapture:()=>({start:vi.fn(),stop:m.stop,mute:vi.fn(),unmute:vi.fn()})}));
vi.mock('@/hooks/useAudioPlayback',()=>({useAudioPlayback:()=>({playChunk:vi.fn(),stop:m.playStop,scheduleAfterPlayback:vi.fn(),waitForDrain:m.drain,cancelDrain:m.cancel})}));
vi.mock('@/hooks/useAudioWebSocket',()=>({useAudioWebSocket:(o:any)=>{m.state=o.onStateChange;return {connect:vi.fn(),send:vi.fn(),sendJson:vi.fn(),disconnect:m.disconnect,connectionState:'connected'};}}));
vi.mock('@/components/HardwareCheck',()=>({default:()=> <div>Hardware</div>}));
beforeEach(()=>{vi.useFakeTimers();vi.clearAllMocks();m.candidate.mockResolvedValue({data:{session_id:1,session_status:'active',role_title:'Engineer',time_limit_min:10}});m.drain.mockImplementation((cb:any)=>cb());});
afterEach(()=>{vi.useRealTimers();});
async function setup(){await act(async()=>{render(<MemoryRouter initialEntries={['/interview/test']}><Routes><Route path='/interview/:token' element={<InterviewPage/>}/></Routes></MemoryRouter>);});}
it('R01 permanent completion rejection becomes failed and stops recording without retries',async()=>{
 m.audioComplete.mockRejectedValue({response:{status:422}});await setup();
 await act(async()=>m.state('draining_audio'));
 expect(screen.getByRole('alert')).toBeInTheDocument();
 expect(m.stop).toHaveBeenCalled();expect(m.playStop).toHaveBeenCalled();expect(m.disconnect).toHaveBeenCalled();
 await act(async()=>vi.advanceTimersByTimeAsync(60000));expect(m.audioComplete).toHaveBeenCalledTimes(1);
});
it('R01 transient completion failures stop after a bounded retry budget',async()=>{
 m.audioComplete.mockRejectedValue(new Error('network'));await setup();
 await act(async()=>m.state('draining_audio'));
 await act(async()=>vi.advanceTimersByTimeAsync(60000));
 expect(screen.getByRole('alert')).toBeInTheDocument();expect(m.audioComplete).toHaveBeenCalledTimes(3);
});
it('R01 server error cancels outstanding acknowledgment work and stops the microphone',async()=>{
 m.audioComplete.mockRejectedValue(new Error('network'));await setup();
 await act(async()=>m.state('draining_audio'));await act(async()=>m.state('failed'));
 await act(async()=>vi.advanceTimersByTimeAsync(60000));
 expect(m.audioComplete).toHaveBeenCalledTimes(1);expect(m.stop).toHaveBeenCalled();expect(m.disconnect).toHaveBeenCalled();
});
