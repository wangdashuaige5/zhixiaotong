// 公共会话恢复、账号隔离、选课批次与入口回归；不连接真实服务或写入真实业务数据。
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const assert = require('node:assert/strict');
const ts = require(process.env.TYPESCRIPT_PATH || '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const project = process.env.FRONTEND_PROJECT || path.join(__dirname, '..');
const root = path.join(project, 'entry/src/main/ets');
function compile(text, globals = {}) {
  const sandbox = {exports: {}, Error, Map, Date, Promise, ...globals};
  vm.runInNewContext(ts.transpileModule(text, {compilerOptions: {target:ts.ScriptTarget.ES2021,module:ts.ModuleKind.CommonJS}}).outputText,sandbox);
  return sandbox.exports;
}
const constants=compile(fs.readFileSync(path.join(root,'common/Constants.ets'),'utf8')).AppConstants;
function httpFixture(handler) {
  const storage=new Map(), calls=[], redirects=[]; let destroyed=0;
  const native={RequestMethod:{GET:'GET',POST:'POST',PUT:'PUT',DELETE:'DELETE'},createHttp:()=>({
    request:async(url, options)=>{const call={path:url.replace(constants.BASE_URL,''),...options};calls.push(call);return handler(call);},
    destroy:()=>{destroyed++;}
  })};
  const code=fs.readFileSync(path.join(root,'common/Http.ets'),'utf8').replace(/^import .*;\n/gm,'');
  const {HttpClient,ApiException}=compile(code,{http:native,AppConstants:constants,
    AppStorage:{get:key=>storage.get(key),setOrCreate:(key,value)=>storage.set(key,value)},
    router:{replaceUrl:async(options)=>{redirects.push(options.url);}}});
  HttpClient.setTokens('old','refresh-old');
  storage.set('attendance_device_id','device-1'); storage.set('login_device_code','login-1');
  return {HttpClient,ApiException,storage,calls,redirects,destroyed:()=>destroyed};
}
const response=(status,data={},message='')=>({responseCode:status,result:JSON.stringify({code:status===200?0:status,data,message})});
const pair={access_token:'new',refresh_token:'refresh-new'};
let passed=0;
async function test(name, run){await run();passed++;console.log('PASS '+name);}
(async()=>{
 await test('同时过期的多个请求只刷新一次，各重试一次',async()=>{
  const f=httpFixture(async c=>c.path==='/api/auth/refresh'?response(200,pair):response(c.header.Authorization==='Bearer new'?200:401));
  await Promise.all([f.HttpClient.get('/api/a'),f.HttpClient.get('/api/b'),f.HttpClient.get('/api/c')]);
  assert.equal(f.calls.filter(c=>c.path==='/api/auth/refresh').length,1);assert.equal(f.calls.length,7);
  assert.equal(f.storage.get('attendance_device_id'),'device-1');assert.equal(f.storage.get('refresh_token'),'refresh-new');
  assert.equal(f.destroyed(),f.calls.length);
 });
 await test('登录和刷新不携带已过期的Authorization',async()=>{
  const f=httpFixture(async c=>c.path==='/api/auth/login'?response(200):c.path==='/api/auth/refresh'?response(200,pair):response(c.header.Authorization==='Bearer new'?200:401));
  await f.HttpClient.post('/api/auth/login',{});await f.HttpClient.get('/api/a');
  for(const c of f.calls.filter(c=>c.path.startsWith('/api/auth/')))assert.equal(c.header.Authorization,undefined);
  assert.equal(JSON.parse(f.calls.find(c=>c.path==='/api/auth/refresh').extraData).refresh_token,'refresh-old');
 });
 await test('403权限拒绝不刷新、不重复写操作',async()=>{
  const f=httpFixture(async()=>response(403,{},'无权'));
  await assert.rejects(f.HttpClient.post('/api/write',{}),e=>e.code===403);assert.equal(f.calls.length,1);assert.equal(f.redirects.length,0);
 });
 await test('网络错误不重放写请求、不清空账号',async()=>{
  const f=httpFixture(async()=>{throw new Error('offline');});
  await assert.rejects(f.HttpClient.post('/api/write',{}),e=>e.code===0);assert.equal(f.calls.length,1);assert.equal(f.storage.get('access_token'),'old');
 });
 await test('刷新暂时503保留会话供网络恢复重试',async()=>{
  const f=httpFixture(async c=>response(c.path==='/api/auth/refresh'?503:401));
  await assert.rejects(f.HttpClient.get('/api/a'),e=>e.code===503);assert.equal(f.storage.get('refresh_token'),'refresh-old');assert.equal(f.redirects.length,0);
 });
 await test('刷新凭据失效清理设备并只跳转一次',async()=>{
  const f=httpFixture(async()=>response(401));
  await Promise.allSettled([f.HttpClient.get('/api/a'),f.HttpClient.get('/api/b')]);
  assert.equal(f.redirects.length,1);assert.equal(f.storage.get('access_token'),'');assert.equal(f.storage.get('attendance_device_id'),'');assert.equal(f.storage.get('login_device_code'),'');
 });
 await test('重试仍401只执行一次刷新，避免无限循环',async()=>{
  const f=httpFixture(async c=>c.path==='/api/auth/refresh'?response(200,pair):response(401));
  await assert.rejects(f.HttpClient.get('/api/a'),e=>e.code===401);assert.equal(f.calls.length,3);assert.equal(f.redirects.length,1);
 });
 await test('旧账号刷新晚到不能覆盖新登录或替新账号重放请求',async()=>{
  let release,started;const ready=new Promise(r=>{started=r;});
  const f=httpFixture(c=>c.path==='/api/auth/refresh'?new Promise(r=>{release=r;started();}):Promise.resolve(response(401)));
  const pending=f.HttpClient.get('/api/a');await ready;f.HttpClient.setTokens('another-user','another-refresh');release(response(200,pair));
  await assert.rejects(pending,e=>e.code===409);assert.equal(f.storage.get('access_token'),'another-user');assert.equal(f.calls.length,2);
 });
 await test('刷新已经完成时到达的旧401不再次消耗刷新令牌',async()=>{
  let releaseOld;const f=httpFixture(c=>{
   if(c.path==='/api/auth/refresh')return Promise.resolve(response(200,pair));
   if(c.path==='/api/slow'&&c.header.Authorization==='Bearer old')return new Promise(r=>{releaseOld=r;});
   return Promise.resolve(response(c.header.Authorization==='Bearer new'?200:401));
  });
  const slow=f.HttpClient.get('/api/slow');await f.HttpClient.get('/api/fast');releaseOld(response(401));await slow;
  assert.equal(f.calls.filter(c=>c.path==='/api/auth/refresh').length,1);
 });
 function page(name,globals={}){
  let source=fs.readFileSync(path.join(root,name),'utf8');source=source.slice(0,source.indexOf('  build() {'))
   .replace(/^import .*;\n/gm,'').replace(/@(Entry|Component)\s*/g,'').replace(/@State\s+/g,'').replace(/(export )?struct /g,'class ');
  const className=path.basename(name,'.ets');return compile(source+'\n}\nexports.Page='+className+';',globals).Page;
 }
 await test('菜单补齐考试和教务成绩且不向非学生显示校园卡',()=>{
  const Campus=page('components/CampusPage.ets',{AppConstants:constants});
  const teacher=new Campus();teacher.isTeacher=true;const menus=teacher.buildMenu().map(i=>i.page);
  assert.ok(menus.includes(constants.PAGE_EXAMS));assert.ok(menus.includes(constants.PAGE_GRADES));assert.ok(!menus.includes(constants.PAGE_CARD));
  const secretary=new Campus();secretary.isSecretary=true;assert.ok(secretary.buildMenu().some(i=>i.page===constants.PAGE_GRADES));
  const student=new Campus();student.isStudent=true;assert.ok(student.buildMenu().some(i=>i.page===constants.PAGE_CARD));
 });
 let calls=[];const now=Date.now();
 const openBatch={id:'17',batch_name:'当前批次',batch_status:1,start_time:new Date(now-10000).toISOString(),end_time:new Date(now+60000).toISOString()};
 const CoursePage=page('pages/CoursesPage.ets',{ApiException:class extends Error{},randomRequestKey:()=> 'stable-key',
  promptAction:{showToast:()=>{},showDialog:async()=>({index:0})},CampusApi:{
   enrollmentBatches:async()=>[openBatch,{...openBatch,id:'18',batch_status:0}],
   myEnrollments:async(sem,p)=>{calls.push(['records',sem,p]);return {items:[],total:'25'};},
   enrollmentOptions:async(id,keyword,p)=>{calls.push(['options',id,keyword,p]);return {items:[],total:'21'};}
  }});
 await test('开放批次自动选择真实ID，关闭批次不作为选课选项',async()=>{
  calls=[];const p=new CoursePage();await p.loadData();assert.equal(p.batchId,'17');assert.equal(p.batches.length,1);
  assert.deepEqual(calls.find(c=>c[0]==='options'),['options','17','',1]);assert.equal(p.optionsTotal,21);
 });
 await test('选课与个人记录分别请求正确页码',async()=>{
  calls=[];const p=new CoursePage();await p.loadData();await p.changeOptionsPage(1);await p.changeRecordsPage(1);
  assert.ok(calls.some(c=>c[0]==='options'&&c[3]===2));assert.ok(calls.some(c=>c[0]==='records'&&c[2]===2));
 });
 await test('请求忙碌和页码边界阻止重复翻页',async()=>{
  calls=[];const p=new CoursePage();p.optionsTotal=21;p.optionsPage=1;await p.changeOptionsPage(-1);p.busy=true;await p.changeOptionsPage(1);assert.equal(calls.length,0);
 });
 await test('账号切换后的刷新不等待或复用旧账号刷新',async()=>{
  let releaseOld,notifyOld;const oldStarted=new Promise(r=>notifyOld=r);
  const f=httpFixture(c=>{
   if(c.path==='/api/auth/refresh') {
    if(JSON.parse(c.extraData).refresh_token==='refresh-old') return new Promise(r=>{releaseOld=r;notifyOld();});
    return Promise.resolve(response(200,{access_token:'second-new',refresh_token:'second-refresh-new'}));
   }
   return Promise.resolve(response(c.header.Authorization==='Bearer second-new'?200:401));
  });
  const old=f.HttpClient.get('/api/old');await oldStarted;
  f.HttpClient.setTokens('second-old','second-refresh');await f.HttpClient.get('/api/second');
  releaseOld(response(200,pair));await assert.rejects(old,e=>e.code===409);
  assert.equal(f.storage.get('access_token'),'second-new');
 });
 await test('旧账号已经成功的迟到数据也不会渲染到新账号',async()=>{
  let release;const f=httpFixture(()=>new Promise(r=>release=r));
  const pending=f.HttpClient.get('/api/private');f.HttpClient.setTokens('another','another-refresh');
  release(response(200,{private:'old-account'}));await assert.rejects(pending,e=>e.code===409);
 });
 function approvalFixture(dialogIndex=1){
  const calls=[],toasts=[];let resolvePost;const state={hold:false,failList:false};
  const Page=page('pages/ApprovalsPage.ets',{ApiException:class extends Error{},AppTheme:{COLOR_PRIMARY:'#000'},
   promptAction:{showToast:o=>toasts.push(o.message),showDialog:async()=>({index:dialogIndex})},
   CampusApi:{pendingLeaves:async()=>{if(state.failList)throw new Error('offline');return [];},
    approveLeave:async(id,body)=>{calls.push([id,body]);if(state.hold)await new Promise(r=>resolvePost=r);}}});
  return {p:new Page(),calls,toasts,state,release:()=>resolvePost()};
 }
 const application={id:'71',apply_round:2,node_order:1};
 await test('驳回和退回修改缺少意见不发出审批',async()=>{
  const f=approvalFixture();await f.p.decide(application,2);await f.p.decide(application,3);assert.equal(f.calls.length,0);
 });
 await test('审批确认取消不发请求且释放忙碌状态',async()=>{
  const f=approvalFixture(0);await f.p.decide(application,1);assert.equal(f.calls.length,0);assert.equal(f.p.busy,false);
 });
 await test('退回审批带原轮次及节点，防止审批错误轮次',async()=>{
  const f=approvalFixture();f.p.opinion='  请补充证明  ';await f.p.decide(application,3);
  assert.equal(f.calls.length,1);assert.equal(f.calls[0][0],'71');
  assert.deepEqual(JSON.parse(JSON.stringify(f.calls[0][1])),{apply_round:2,node_order:1,decision:3,opinion:'请补充证明'});
  assert.equal(f.p.opinion,'');assert.equal(f.p.busy,false);
 });
 await test('审批正在发送时重复点击只执行一次',async()=>{
  const f=approvalFixture();f.state.hold=true;const first=f.p.decide(application,1);await Promise.resolve();
  await f.p.decide(application,1);assert.equal(f.calls.length,1);f.release();await first;assert.equal(f.p.busy,false);
 });
 await test('待办刷新失败清空旧申请并展示错误',async()=>{
  const f=approvalFixture();f.p.items=[application];f.state.failList=true;await f.p.loadData();
  assert.equal(f.p.items.length,0);assert.ok(f.p.error);assert.equal(f.p.loading,false);
 });
 console.log(`${passed} session/enrollment tests passed.`);
})().catch(e=>{console.error(e);process.exitCode=1;});
