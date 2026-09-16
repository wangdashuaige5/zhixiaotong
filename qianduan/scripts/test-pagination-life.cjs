// 执行实际 ArkTS 的分页和生活服务逻辑；HTTP/提示使用桩，不修改业务数据库。
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const ts = require(process.env.TYPESCRIPT_PATH || '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const root = path.join(__dirname, '../entry/src/main/ets');
class ApiException extends Error { constructor(code, message) { super(message); this.code = code; } }
let messages = [], serial = 0;
function compile(source, globals = {}) {
  const context = { exports: {}, Error, Date, console, ApiException,
    Scroller: class { scrollEdge() {} }, Edge: { Top: 0 },
    promptAction: { showToast: value => messages.push(value.message) },
    randomRequestKey: prefix => `${prefix}-${++serial}`, ...globals };
  vm.runInNewContext(ts.transpileModule(source, { compilerOptions: {
    target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS
  }}).outputText, context);
  return context.exports;
}
function withoutImports(source) { return source.replace(/^import[\s\S]*?;\n/gm, ''); }
function page(file, name, api, http = {}) {
  let source = withoutImports(fs.readFileSync(path.join(root, file), 'utf8'));
  source = source.slice(0, source.indexOf('  build() {')).replace(/@(Entry|Component)\s*/g, '')
    .replace(/@State\s+/g, '').replace(`export struct ${name}`, `class ${name}`).replace(`struct ${name}`, `class ${name}`);
  return new (compile(source + `\n}\nexports.Page = ${name};`, { CampusApi: api, HttpClient: http }).Page)();
}
function data(items = [{id: '21'}], total = '41') { return {items, total, page_no: 2, page_size: 20}; }
let passed = 0;
async function test(name, fn) { await fn(); passed++; console.log('PASS ' + name); }
(async () => {
  const calls = [];
  const http = {
    get: async (url, query) => { calls.push({method:'GET', url, query}); return {data: data()}; },
    post: async (url, body) => { calls.push({method:'POST', url, body}); return {data: {id:'99'}}; },
    delete: async url => { calls.push({method:'DELETE', url}); return {data:null}; }
  };
  const api = compile(withoutImports(fs.readFileSync(path.join(root, 'services/Api.ets'), 'utf8')), {HttpClient:http}).CampusApi;
  await test('真实权限对象数组规范为教师页面可识别的编码', async () => {
    let response = {id:'6',user_name:'teacher_demo',real_name:'演示教师',roles:[{role_code:'teacher',scope_type:2}],
      permissions:[{permission_code:'grade:write'},{permission_code:'grade:publish'},{permission_code:'teaching:write'}]};
    const actualApi = compile(withoutImports(fs.readFileSync(path.join(root, 'services/Api.ets'), 'utf8')),
      {HttpClient:{get:async()=>({data:response}),put:async()=>({data:response})}}).CampusApi;
    let me = await actualApi.me();
    assert.deepEqual(Array.from(me.permissions), ['grade:write','grade:publish','teaching:write']);
    assert.ok(me.permissions.indexOf('grade:write') >= 0);assert.equal(me.id,'6');assert.equal(me.roles[0].role_code,'teacher');
    me = await actualApi.updateProfile({email:'teacher@example.com'});assert.ok(me.permissions.includes('grade:publish'));
  });
  await test('权限兼容字符串和混合数组、忽略异常条目并去重', async () => {
    let response = {permissions:['grade:write',{permission_code:'grade:write'},null,123,{}, {permission_code:99},'', ' teaching:write ']};
    const actualApi = compile(withoutImports(fs.readFileSync(path.join(root, 'services/Api.ets'), 'utf8')),
      {HttpClient:{get:async()=>({data:response})}}).CampusApi;
    let me = await actualApi.me();assert.deepEqual(Array.from(me.permissions),['grade:write','teaching:write']);
    for (const malformed of [{}, {permissions:null}, {permissions:'grade:write'}, {permissions:{permission_code:'admin:write'}}]) {
      response=malformed;me=await actualApi.me();assert.equal(me.permissions.length,0);
    }
  });
  for (const [name, args] of [
    ['exams', [undefined]], ['enrollmentOptions', ['batch-3', '课程']], ['myEnrollments',[undefined]],
    ['myGrades',[undefined]], ['myLeaves',[]], ['cardTransactions',[]], ['books',['检索词']], ['loans',[]],
    ['reservations',[]], ['notices',[]], ['messages',[]], ['adminUsers',[]], ['adminData',['courses']], ['auditLogs',[]]
  ]) {
    await test(name + ' 兼容第一页并支持显式分页', async () => {
      await api[name](...args); let q = calls.at(-1).query;
      assert.equal(q.get('page_no'), '1'); assert.equal(q.get('page_size'), '20');
      await api[name](...args, 3, 7); q = calls.at(-1).query;
      assert.equal(q.get('page_no'), '3'); assert.equal(q.get('page_size'), '7');
    });
  }
  await test('预约与订单查询仅使用已存在的安全接口', async () => {
    await api.cancelReservation('9007199254740993');
    assert.equal(calls.at(-1).url, '/api/library/reservations/9007199254740993');
    assert.equal(calls.at(-1).method, 'DELETE');
    await api.rechargeOrder('99'); assert.equal(calls.at(-1).url, '/api/cards/recharges/99');
    await api.recharge('10.00', 'stable');
    assert.equal(calls.at(-1).body.request_key, 'stable'); assert.equal(calls.at(-1).body.pay_channel, 'MOCK_PAY');
    assert.equal(calls.some(c => c.url.includes('callback')), false);
  });
  for (const [file, name, method] of [
    ['pages/ExamsPage.ets','ExamsPage','exams'], ['pages/LeavePage.ets','LeavePage','myLeaves'],
    ['pages/NoticesPage.ets','NoticesPage','notices'], ['components/MessagesPage.ets','MessagesPage','messages']
  ]) {
    await test(name + ' 翻页、字符串总数和失败清空', async () => {
      let args, fail = false;
      const apiMock = {[method]:async (...values) => { args = values; if(fail) throw new Error('offline'); return data(); }};
      const p = page(file,name,apiMock);
      await p.loadData(2); assert.equal(p.pageNo,2); assert.equal(p.total,41); assert.equal(p.items.length,1);
      assert.equal(args[method === 'exams' ? 1 : 0],2);
      fail = true; await p.loadData(3); assert.equal(p.items.length,0); assert.equal(p.total,0); assert.ok(p.error);
      assert.equal(p.loading,false);
    });
  }
  await test('通知详情失败清空旧详情，重复确认已阅不发送请求', async () => {
    let posts = 0;
    const p = page('pages/NoticesPage.ets','NoticesPage',{noticeDetail:async()=>{throw new Error('offline');}},
      {post:async()=>{ posts++; }});
    p.detail = {notice_title:'旧标题'}; await p.openDetail('2'); assert.equal(p.detail,null);
    await p.ack('2'); await p.ack('2'); assert.equal(posts,1); assert.equal(p.busy,false);
  });
  await test('消息读取期间阻止重复标记并保留分页', async () => {
    let release, posts=0;
    const p = page('components/MessagesPage.ets','MessagesPage',{messages:async()=>data()},
      {post:()=>{posts++; return new Promise(r=>{release=r;});}});
    p.pageNo=2; const pending=p.read('2'); await p.read('2'); assert.equal(posts,1);
    release(); await pending; assert.equal(p.busy,false); assert.equal(p.pageNo,2);
  });
  await test('图书检索、借阅和预约保持独立页码', async () => {
    let inputs=[];
    const p = page('pages/LibraryPage.ets','LibraryPage',{
      books:async (...a)=>{inputs.push(a);return data();}, loans:async (...a)=>{inputs.push(a);return data();},
      reservations:async (...a)=>{inputs.push(a);return data();}
    });
    p.appliedKeyword='数据库'; p.keyword='尚未检索'; p.bookPage=3; p.loanPage=2; p.reservationPage=4;
    await p.loadData(); assert.deepEqual(inputs,[['数据库',3],[2],[4]]);
    assert.equal(p.bookTotal,41); assert.equal(p.reservationTotal,41);
  });
  await test('图书组合加载失败不展示不完整或旧列表', async () => {
    const p = page('pages/LibraryPage.ets','LibraryPage',{
      books:async()=>data(),loans:async()=>data(),reservations:async()=>{throw new Error('offline');}
    });
    p.books=[{id:'old'}];p.loans=[{id:'old'}];p.reservations=[{id:'old'}];
    await p.loadData(); assert.equal(p.books.length+p.loans.length+p.reservations.length,0);
    assert.ok(p.error); assert.equal(p.loading,false);
  });
  await test('取消本人预约防重复并刷新状态', async () => {
    let release,cancelled=0;
    const p = page('pages/LibraryPage.ets','LibraryPage',{
      cancelReservation:()=>{cancelled++;return new Promise(r=>{release=r;});},
      books:async()=>data(),loans:async()=>data(),reservations:async()=>data([{id:'21',reserve_status:3}])
    });
    const pending=p.cancelReservation('21'); await p.cancelReservation('21'); assert.equal(cancelled,1);
    release();await pending;assert.equal(p.reservations[0].reserve_status,3);assert.equal(p.busy,false);
    assert.equal(p.reservationStatus(1),'可领取');
  });
  for(const code of [403,404]) {
    await test(`校园卡 ${code} 展示业务提示且移除旧余额`,async()=>{
      const p=page('pages/CampusCardPage.ets','CampusCardPage',{
        cardBalance:async()=>{throw new ApiException(code,'原始错误');}
      });
      p.balance={balance:'999.00'}; p.transactions=[{id:'1'}];
      await p.loadData();assert.equal(p.balance,null);assert.equal(p.transactions.length,0);assert.equal(p.unavailable,true);
      assert.match(p.error, code===403?/权限/:/绑定/); assert.equal(p.loading,false);
    });
  }
  await test('校园卡金额校验拒绝负数、超额和精度错误',()=>{
    const p=page('pages/CampusCardPage.ets','CampusCardPage',{});
    for(const x of ['','0','-1','10000.01','1.001','1e2','NaN']) assert.equal(p.validAmount(x),false,x);
    for(const x of ['0.01','1','10000','99.90']) assert.equal(p.validAmount(x),true,x);
  });
  await test('创建充值订单不改余额，不伪造支付或到账',async()=>{
    let posts=0;
    const p=page('pages/CampusCardPage.ets','CampusCardPage',{
      recharge:async()=>{posts++;return {id:'99',order_no:'MOCK-99',amount:'10.00',order_status:0};}
    });
    p.balance={balance:'50.00',account_status:1,integration_mode:'mock'};p.amount='10.00';
    await p.recharge();assert.equal(posts,1);assert.equal(p.balance.balance,'50.00');
    assert.equal(p.order.order_status,0);assert.match(p.orderStatusText(0),/尚未到账/);assert.equal(p.busy,false);
  });
  await test('充值失败重试保留幂等键，避免产生两个订单',async()=>{
    let keys=[];
    const p=page('pages/CampusCardPage.ets','CampusCardPage',{
      recharge:async(a,key)=>{keys.push(key);throw new Error('timeout');}
    });
    p.balance={balance:'50.00',account_status:1,integration_mode:'mock'};p.amount='10.00';
    await p.recharge();await p.recharge();assert.equal(keys.length,2);assert.equal(keys[0],keys[1]);assert.equal(p.busy,false);
  });
  await test('订单查询只有服务端已入账才重新获取余额',async()=>{
    let balanceCalls=0,status=0;
    const p=page('pages/CampusCardPage.ets','CampusCardPage',{
      rechargeOrder:async()=>({id:'99',order_status:status}),
      cardBalance:async()=>{balanceCalls++;return {balance:'60.00',account_status:1};},cardTransactions:async()=>data()
    });
    p.order={id:'99',order_status:0};await p.refreshOrder();assert.equal(balanceCalls,0);
    status=2;await p.refreshOrder();assert.equal(balanceCalls,1);assert.equal(p.balance.balance,'60.00');
  });
  await test('未绑定、冻结或正式接口未配置时不发送充值请求',async()=>{
    let posts=0;const p=page('pages/CampusCardPage.ets','CampusCardPage',{recharge:async()=>{posts++;}});
    p.amount='10';await p.recharge();p.balance={account_status:0,integration_mode:'mock'};await p.recharge();
    p.balance={account_status:1,integration_mode:'school'};await p.recharge();assert.equal(posts,0);
  });
  await test('管理列表分页与无默认组织编号',async()=>{
    let args;const p=page('pages/AdminPage.ets','AdminPage',{adminUsers:async(...a)=>{args=a;return data();}});
    assert.equal(p.courseOrgId,'');await p.loadResource({label:'用户',resource:'users'},2);
    assert.equal(args[0],2);assert.equal(p.total,41);assert.equal(p.rows.length,1);assert.equal(p.activeResource,'users');
  });
  await test('管理表单拒绝无效数值且不发出保存',async()=>{
    let saves=0;const p=page('pages/AdminPage.ets','AdminPage',{adminSave:async()=>{saves++;}});
    p.courseCode='C1';p.courseName='课程';p.courseType='必修';p.courseCredit='1';p.courseHours='3x';p.courseOrgId='2';
    await p.saveCourse();p.roomCode='R';p.roomName='R';p.campusName='校区';p.buildingName='楼';p.roomCapacity='1.5';
    await p.saveClassroom();assert.equal(saves,0);assert.equal(p.saving,false);
  });
  const leave = { id:'123',leave_type:'事假',leave_reason:'待修改',leave_status:5,apply_round:2,
    start_time:'2099-09-15T09:30:00',end_time:'2099-09-16T18:15:00',
    approvals:[{apply_round:1,decision:3,opinion:'旧意见'},{apply_round:2,decision:3,opinion:'请补充原因'}] };
  await test('退回申请读取当前状态并回填时间和本轮意见',async()=>{
    const p=page('pages/LeavePage.ets','LeavePage',{leaveDetail:async()=>leave});
    await p.editLeave('123');assert.equal(p.editingId,'123');assert.equal(p.startHour,9);assert.equal(p.startMinute,30);
    assert.equal(p.endHour,18);assert.equal(p.returnOpinion,'请补充原因');assert.equal(p.actionBusy,false);
  });
  await test('状态已进入审批则阻止继续编辑旧记录',async()=>{
    const p=page('pages/LeavePage.ets','LeavePage',{
      leaveDetail:async()=>({...leave,leave_status:1}),myLeaves:async()=>data()
    });
    await p.editLeave('123');assert.equal(p.editingId,'');assert.equal(p.actionBusy,false);
  });
  await test('退回重提使用 PUT 编辑原 ID，不创建重复申请、不在客户端递增轮次',async()=>{
    let body,id,created=0;
    const p=page('pages/LeavePage.ets','LeavePage',{
      leaveDetail:async()=>leave,updateLeave:async(i,b)=>{id=i;body=b;return {...leave,leave_status:1,apply_round:3};},
      createLeave:async()=>{created++;},myLeaves:async()=>data()
    });
    await p.editLeave('123');p.reason='补充后的原因';await p.submit();
    assert.equal(id,'123');assert.equal(body.action,'submit');assert.equal(body.leave_reason,'补充后的原因');
    assert.equal(body.apply_round,undefined);assert.equal(created,0);assert.equal(p.editingId,'');assert.equal(p.submitting,false);
  });
  await test('保存草稿保留编辑 ID，后续提交不会额外创建申请',async()=>{
    let created=0,updated=0,lastAction;
    const p=page('pages/LeavePage.ets','LeavePage',{
      createLeave:async b=>{created++;lastAction=b.action;return {...leave,leave_status:0};},
      updateLeave:async(i,b)=>{updated++;lastAction=b.action;return {...leave,leave_status:1};},myLeaves:async()=>data()
    });
    p.reason='草稿';await p.submit('draft');assert.equal(p.editingId,'123');assert.equal(lastAction,'draft');
    await p.submit();assert.equal(created,1);assert.equal(updated,1);assert.equal(lastAction,'submit');
  });
  await test('退回修改提交失败保留输入供重试，忙碌时禁止重复提交',async()=>{
    let release,updates=0;
    const p=page('pages/LeavePage.ets','LeavePage',{
      leaveDetail:async()=>leave,updateLeave:()=>{updates++;return new Promise((resolve,reject)=>{release=()=>reject(new Error('offline'));});}
    });
    await p.editLeave('123');p.reason='保留内容';const pending=p.submit();await p.submit();assert.equal(updates,1);
    release();await pending;assert.equal(p.reason,'保留内容');assert.equal(p.editingId,'123');assert.equal(p.submitting,false);
  });
  console.log(`\n${passed} pagination/life tests passed`);
})().catch(e=>{console.error(e);process.exitCode=1;});
