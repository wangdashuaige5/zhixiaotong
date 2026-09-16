// 运行真实页面逻辑，密码修改/签到使用桩，不写入真实业务数据。
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const ts=require(process.env.TYPESCRIPT_PATH||'/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const root=path.join(__dirname,'../entry/src/main/ets');
function page(file,globals={}) {
 let s=fs.readFileSync(path.join(root,file),'utf8');
 const cut=s.includes('  @Builder')?s.indexOf('  @Builder'):s.indexOf('  build() {');
 s=s.slice(0,cut).replace(/^import .*;\n/gm,'').replace(/@(Entry|Component)\s*/g,'').replace(/@State\s+/g,'').replace(/export struct |struct /g,'class ');
 const name=path.basename(file,'.ets'),context={exports:{},Error,...globals};
 vm.runInNewContext(ts.transpileModule(s+'\n}\nexports.Page='+name,{compilerOptions:{target:ts.ScriptTarget.ES2021,module:ts.ModuleKind.CommonJS}}).outputText,context);return context.exports.Page;
}
const me={id:'7',real_name:'示例用户',user_name:'demo',email:'demo@example.edu',user_status:1,roles:[{role_code:'STUDENT'}]};
let passed=0;
async function test(name,run){await run();passed++;console.log('PASS '+name);}
function fixture(){
 const calls=[],toasts=[],state={choice:1,fail:false,hold:false};let release;
 const P=page('components/ProfilePage.ets',{ApiException:class extends Error{},AppConstants:{PAGE_LOGIN:'pages/LoginPage'},
  promptAction:{showToast:x=>toasts.push(x.message),showDialog:async()=>({index:state.choice})},
  router:{replaceUrl:async()=>calls.push('navigate')},HttpClient:{clearTokens:()=>calls.push('clear')},
  CampusApi:{me:async()=>{if(state.fail)throw new Error('offline');return {...me};},updateProfile:async(body)=>{calls.push(body);if(state.hold)await new Promise(r=>release=r);return {...me,...body};},
  changePassword:async()=>calls.push('password'),logout:async()=>calls.push('logout')}});
 return {p:new P(),calls,toasts,state,release:()=>release()};
}
(async()=>{
 await test('六种角色都有中文身份且学号工号区分',()=>{
  const {p}=fixture();for(const [role,text] of Object.entries({STUDENT:'学生',TEACHER:'任课教师',COUNSELOR:'辅导员',SECRETARY:'教学秘书',DEAN:'院系负责人',ADMIN:'管理员'})){
   p.user={...me,roles:[{role_code:role}]};assert.equal(p.roleText(),text);assert.equal(p.numberLabel(),role==='STUDENT'?'学号':'工号');
  }
 });
 await test('资料加载成功后表单默认收起',async()=>{const {p}=fixture();await p.loadData();assert.equal(p.editor,'');assert.equal(p.email,me.email);});
 await test('切换编辑区清空密码、取消邮箱编辑恢复原值',async()=>{const {p}=fixture();await p.loadData();p.oldPassword='secret';p.email='wrong';p.toggleEditor('email');assert.equal(p.oldPassword,'');assert.equal(p.email,me.email);p.toggleEditor('email');assert.equal(p.editor,'');});
 await test('无效邮箱不向后端提交',async()=>{const f=fixture();await f.p.loadData();f.p.email='bad';await f.p.updateEmail();assert.equal(f.calls.length,0);});
 await test('邮箱保存并发点击只发送一次',async()=>{const f=fixture();await f.p.loadData();f.state.hold=true;f.p.email='next@example.edu';const first=f.p.updateEmail();await f.p.updateEmail();assert.equal(f.calls.length,1);f.release();await first;assert.equal(f.p.user.email,'next@example.edu');assert.equal(f.p.busy,false);});
 await test('新密码二次确认不一致不会发送',async()=>{const f=fixture();f.p.oldPassword='old';f.p.newPassword='abcdef12345';f.p.confirmPassword='abcdef99999';await f.p.changePassword();assert.equal(f.calls.length,0);});
 await test('弱密码不会发送',async()=>{const f=fixture();f.p.oldPassword='old';f.p.newPassword='12345678901';f.p.confirmPassword=f.p.newPassword;await f.p.changePassword();assert.equal(f.calls.length,0);});
 await test('改密成功清除旧凭据和输入再回登录',async()=>{const f=fixture();f.p.oldPassword='old';f.p.newPassword='abcdef12345';f.p.confirmPassword=f.p.newPassword;await f.p.changePassword();assert.deepEqual(f.calls,['password','clear','navigate']);assert.equal(f.p.oldPassword,'');assert.equal(f.p.newPassword,'');});
 await test('退出取消不结束会话',async()=>{const f=fixture();f.state.choice=0;await f.p.logout();assert.equal(f.calls.length,0);assert.equal(f.p.busy,false);});
 await test('资料失败清除旧身份，离开页面清除密码',async()=>{const f=fixture();f.p.user=me;f.state.fail=true;await f.p.loadData();assert.equal(f.p.user,null);assert.ok(f.p.error);f.p.oldPassword='old';f.p.editor='password';f.p.aboutToDisappear();assert.equal(f.p.oldPassword,'');assert.equal(f.p.editor,'');});
 const source=fs.readFileSync(path.join(root,'pages/AttendancePage.ets'),'utf8');
 await test('签到不使用计时器、时间比较或当前时钟识码拦截',()=>{
  assert.ok(!source.includes('setInterval'));assert.ok(!source.includes('attendanceTimeError'));assert.ok(!source.includes('end <= Date.now()'));
 });
 await test('手动结束确认后调用任务接口并隐藏二维码',async()=>{
  const calls=[];const P=page('pages/AttendancePage.ets',{ApiException:class extends Error{},promptAction:{showDialog:async()=>({index:1}),showToast:()=>{}},HttpClient:{post:async p=>calls.push(p)}});
  const p=new P();p.createdTask={id:'9007199254740993',task_status:1};p.qrValue='code';await p.closeTask();
  assert.deepEqual(calls,['/api/attendance/tasks/9007199254740993/close']);assert.equal(p.qrValue,'');assert.equal(p.createdTask.task_status,2);assert.equal(p.busy,false);
 });
 await test('取消手动结束保留二维码',async()=>{
  const P=page('pages/AttendancePage.ets',{ApiException:class extends Error{},promptAction:{showDialog:async()=>({index:0})},HttpClient:{post:async()=>assert.fail('不应请求')}});
  const p=new P();p.createdTask={id:'1',task_status:1};p.qrValue='code';await p.closeTask();assert.equal(p.qrValue,'code');assert.equal(p.busy,false);
 });
 console.log(`${passed} profile/manual-sign tests passed.`);
})().catch(e=>{console.error(e);process.exitCode=1;});
