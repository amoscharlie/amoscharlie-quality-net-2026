import {renderHook,act} from '@testing-library/react';
import {vi,it,expect,afterEach} from 'vitest';
import {useAudioWebSocket} from '@/hooks/useAudioWebSocket';
vi.mock('@/services/api',()=>({WS_URL:'ws://localhost:3001'}));
class Socket {
 static OPEN=1; static latest:Socket;
 readyState=0; binaryType=''; onopen:any; onmessage:any; onclose:any; onerror:any;
 constructor(_url:string){Socket.latest=this;} send(){} close(){}
}
afterEach(()=>{vi.unstubAllGlobals();vi.useRealTimers();});
function setup(){vi.stubGlobal('WebSocket',Socket);const state=vi.fn();const hook=renderHook(()=>useAudioWebSocket({sessionId:1,token:'invite',onAudioChunk:vi.fn(),onTranscript:vi.fn(),onStateChange:state,onSpeakerChange:vi.fn()}));act(()=>hook.result.current.connect());return {state,hook};}
it('A07 terminal provider error remains failed after socket closes',()=>{
 const {state}=setup();act(()=>Socket.latest.onmessage({data:JSON.stringify({type:'error',recoverable:false})}));
 expect(state).toHaveBeenLastCalledWith('failed');
 act(()=>Socket.latest.onclose());expect(state).toHaveBeenLastCalledWith('failed');
});
it('A07 error end reason is not successful completion',()=>{
 const {state}=setup();act(()=>Socket.latest.onmessage({data:JSON.stringify({type:'session_ended',reason:'error'})}));expect(state).toHaveBeenLastCalledWith('failed');
});
it('A07 exhausted reconnect attempts fail without claiming a recording',()=>{
 vi.useFakeTimers();const {state}=setup();
 for(let i=0;i<4;i++){act(()=>Socket.latest.onclose());act(()=>vi.advanceTimersByTime(4000));}
 expect(state).toHaveBeenLastCalledWith('failed');
});
it('acknowledged clean termination is complete',()=>{
 const {state}=setup();act(()=>Socket.latest.onmessage({data:JSON.stringify({type:'session_ended',reason:'manual_candidate'})}));expect(state).toHaveBeenLastCalledWith('complete');
});
