// 执行课堂考勤页面实际逻辑；弹窗和HTTP使用桩，不创建真实签到任务。
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const assert = require('node:assert/strict');
const ts = require(process.env.TYPESCRIPT_PATH ||
  '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const root = path.join(__dirname, '../entry/src/main/ets');
function compile(source, globals = {}) {
  const context = { exports: {}, ...globals };
  vm.runInNewContext(ts.transpileModule(source, { compilerOptions: {
    target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS
  }}).outputText, context);
  return context.exports;
}
const qr = compile(fs.readFileSync(path.join(root, 'common/AttendanceQr.ets'), 'utf8'));
let source = fs.readFileSync(path.join(root, 'pages/AttendancePage.ets'), 'utf8');
source = source.slice(0, source.indexOf('  build() {')).replace(/^import .*;\n/gm, '')
  .replace(/@(Entry|Component)\s*/g, '').replace(/@State\s+/g, '').replace('struct AttendancePage', 'class AttendancePage');
let requests = [], messages = [], dateOptions, timeOptions;
const Page = compile(source + '\n}\nexports.Page = AttendancePage;', {
  ...qr, ApiException: class extends Error {},
  promptAction: { showToast: value => messages.push(value.message) },
  HttpClient: { post: async (url, body) => {
    requests.push({url, body});
    return {data: {id: '17', sign_code: '001234', start_time: body.start_time, end_time: body.end_time}};
  }}
}).Page;
function instance() {
  const p = new Page();
  p.getUIContext = () => ({
    showDatePickerDialog: options => { dateOptions = options; },
    showTimePickerDialog: options => { timeOptions = options; }
  });
  return p;
}
let passed = 0;
async function test(name, fn) { await fn(); passed++; console.log('PASS ' + name); }
(async () => {
  await test('选择日期前和取消时不回填', () => {
    const p = instance(); p.pickClassDate(); assert.equal(p.classDate, '');
  });
  await test('日期确认正确转换零基月份及补零', () => {
    const p = instance(); p.pickClassDate(); dateOptions.onAccept({year: 2099, month: 0, day: 2});
    assert.equal(p.classDate, '2099-01-02');
  });
  await test('选择开始时间，24小时制并补零', () => {
    const p = instance(); p.pickSignTime(true); assert.equal(timeOptions.useMilitaryTime, true);
    assert.equal(p.startTime, ''); timeOptions.onAccept({hour: 0, minute: 5});
    assert.equal(p.startTime, '00:05'); assert.equal(p.endTime, '');
  });
  await test('截止时间独立选择，不改变开始时间', () => {
    const p = instance(); p.startTime = '08:00'; p.pickSignTime(false);
    timeOptions.onAccept({hour: 8, minute: 30});
    assert.equal(p.startTime, '08:00'); assert.equal(p.endTime, '08:30');
  });
  await test('重开时间选择器回显已有时分', () => {
    const p = instance(); p.startTime = '09:25'; p.pickSignTime(true);
    assert.equal(timeOptions.selected.getHours(), 9); assert.equal(timeOptions.selected.getMinutes(), 25);
  });
  await test('改变日期保留时分，组合新的北京时间', () => {
    const p = instance(); p.startTime = '08:00'; p.pickClassDate();
    dateOptions.onAccept({year: 2099, month: 8, day: 15});
    assert.equal(p.signDateTime(p.startTime), '2099-09-15T08:00:00+08:00');
  });
  for (const [name, date, start, end] of [
    ['未选日期', '', '08:00', '08:15'], ['未选开始时间', '2099-09-15', '', '08:15'],
    ['未选截止时间', '2099-09-15', '08:00', ''], ['截止早于开始', '2099-09-15', '09:00', '08:00'],
    ['截止等于开始', '2099-09-15', '08:00', '08:00'], ['已过期', '2000-09-15', '08:00', '08:15'],
    ['达到4小时', '2099-09-15', '08:00', '12:00']
  ]) {
    await test(name + '禁止提交', async () => {
      const p = instance(); p.timetableId = '1'; p.classDate = date; p.startTime = start; p.endTime = end;
      const before = requests.length; await p.createTask(); assert.equal(requests.length, before);
    });
  }
  await test('合法选择仍调用原接口并保留二维码', async () => {
    const p = instance(); p.timetableId = '1'; p.classDate = '2099-09-15'; p.startTime = '08:00'; p.endTime = '08:15';
    await p.createTask(); const request = requests[requests.length - 1];
    assert.equal(request.url, '/api/attendance/tasks');
    assert.equal(request.body.start_time, '2099-09-15T08:00:00+08:00');
    assert.equal(request.body.end_time, '2099-09-15T08:15:00+08:00');
    assert.equal(JSON.parse(p.qrValue).sign_code, '001234'); assert.equal(p.busy, false);
  });
  console.log(passed + ' attendance date/time tests passed.');
})().catch(error => { console.error(error); process.exitCode = 1; });
