// 无需真机的前端逻辑回归：执行实际 ETS 方法，ArkUI 组件仅用桩替代。
// 这不是相机、相册或页面布局的真机测试。
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const ts = require(process.env.TYPESCRIPT_PATH ||
  '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const root = path.join(__dirname, '../entry/src/main/ets');
let passed = 0;
function test(name, fn) { fn(); passed++; console.log('PASS ' + name); }
function execute(source, globals = {}) {
  const result = ts.transpileModule(source, {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
  });
  const context = { exports: {}, ...globals };
  vm.runInNewContext(result.outputText, context);
  return context.exports;
}
const qr = execute(fs.readFileSync(path.join(root, 'common/AttendanceQr.ets'), 'utf8'));
const payload = { type: 'zhixiaotong.attendance', version: 1, task_id: '9007199254740993',
  sign_code: '001234', start_time: '2026-09-15T08:00:00+08:00', end_time: '2026-09-15T08:15:00+08:00' };
test('二维码往返保留大整数 ID 和签到码前导零', () => {
  assert.equal(qr.parseAttendanceQr(JSON.stringify(payload)).task_id, payload.task_id);
  assert.equal(qr.parseAttendanceQr(JSON.stringify(payload)).sign_code, '001234');
});
for (const raw of ['', 'https://example.com', 'null', '[]', '1', 'false', '{broken', 'x'.repeat(1025)]) {
  test('拒绝非签到内容 ' + raw.substring(0, 20), () => assert.throws(() => qr.parseAttendanceQr(raw)));
}
for (const [key, value] of [['type', 'other'], ['version', 2], ['task_id', '../admin'],
  ['task_id', 12], ['task_id', '0'], ['sign_code', '12345'], ['sign_code', 'abcdef'],
  ['start_time', 'invalid'], ['end_time', '2026-09-15T07:00:00+08:00']]) {
  test('拒绝非法字段 ' + key + '=' + value,
    () => assert.throws(() => qr.parseAttendanceQr(JSON.stringify({ ...payload, [key]: value }))));
}
const begin = Date.parse(payload.start_time), end = Date.parse(payload.end_time);
test('安排开始前也不由本机时钟拦截签到', () => assert.equal(qr.attendanceTimeError(payload, begin - 1), ''));
test('开始时允许签到', () => assert.equal(qr.attendanceTimeError(payload, begin), ''));
test('截止前允许签到', () => assert.equal(qr.attendanceTimeError(payload, end - 1), ''));
test('安排截止后仍由教师开放状态决定签到', () => assert.equal(qr.attendanceTimeError(payload, end), ''));

// 保留并执行页面实际逻辑方法，仅去掉声明式 UI build()/装饰器/import。
function pageLogic(file, name, marker, globals) {
  let source = fs.readFileSync(path.join(root, file), 'utf8');
  source = source.slice(0, source.indexOf(marker));
  source = source.replace(/^import .*;\n/gm, '').replace(/@(Entry|Component)\s*/g, '')
    .replace(/@State\s+/g, '').replace(/(export )?struct /g, 'class ');
  return execute(source + '\n}\nexports.Page = ' + name + ';', globals).Page;
}
let dialogs = [], calls = 0;
const Timetable = pageLogic('pages/TimetablePage.ets', 'TimetablePage', '  @Builder', {
  AppTheme: { COLOR_PRIMARY: '#002FA7' },
  promptAction: { showDialog: data => dialogs.push(data) }
});
const timetable = new Timetable();
timetable.loading = false;
timetable.weekCount = 20;
timetable.loadTimetable = () => { calls++; };
test('第一周不能再向前', () => { timetable.changeWeek(-1); assert.equal(timetable.selectedWeek, 1); assert.equal(calls, 0); });
test('右箭头下一周', () => { timetable.changeWeek(1); assert.equal(timetable.selectedWeek, 2); assert.equal(calls, 1); });
test('左箭头上一周', () => { timetable.changeWeek(-1); assert.equal(timetable.selectedWeek, 1); });
test('最后一周不能再向后', () => { timetable.selectedWeek = 20; timetable.changeWeek(1); assert.equal(timetable.selectedWeek, 20); });
test('加载中不重复请求', () => { timetable.loading = true; timetable.changeWeek(-1); assert.equal(timetable.selectedWeek, 20); timetable.loading = false; });
timetable.semesterStart = '2026-09-07'; timetable.selectedWeek = 1;
timetable.items = [{ id: '1', course_id: '1', course_name: '软件工程', teacher_name: '张老师',
  class_name: '软件一班', room_name: 'A101', week_mode: 2, week_day: 1,
  start_week: 1, end_week: 20, start_period: 1, end_period: 2, start_time: '08:00:00', end_time: '09:40:00' }];
test('点击课程展示教师/教室/时间/单周详情', () => {
  timetable.showCourse(1, 1);
  for (const text of ['张老师', 'A101', '08:00', '单周', '软件一班']) assert.ok(dialogs[0].message.includes(text));
});
test('空白格不打开详情', () => { timetable.showCourse(3, 7); assert.equal(dialogs.length, 1); });

const constants = execute(fs.readFileSync(path.join(root, 'common/Constants.ets'), 'utf8')).AppConstants;
const Campus = pageLogic('components/CampusPage.ets', 'CampusPage', '  build() {', { AppConstants: constants });
test('多角色校园菜单按路由去重', () => {
  const p = new Campus(); p.isStudent = true; p.isTeacher = true; p.isAdmin = true; p.isCounselor = true;
  const menu = p.buildMenu();
  assert.equal(new Set(menu.map(item => item.page)).size, menu.length);
  assert.ok(menu.some(item => item.page === constants.PAGE_APPROVALS));
  assert.ok(menu.some(item => item.page === constants.PAGE_ADMIN));
  assert.ok(!menu.some(item => item.page === constants.PAGE_NOTICES));
});
test('管理员迁移后保留管理入口', () => {
  const p = new Campus(); p.isAdmin = true;
  assert.ok(p.buildMenu().some(item => item.page === constants.PAGE_ADMIN));
});

let options;
const Leave = pageLogic('pages/LeavePage.ets', 'LeavePage', '  build() {', {
  Scroller: class { scrollEdge() {} }, Edge: { Top: 0 },
  CustomDialogController: class { constructor(value) { options = value; } open() {} close() {} },
  LeaveTimeDialog: value => value, promptAction: { showToast: () => {} }
});
test('请假菜单仅在弹窗确认后回填', () => {
  const p = new Leave(); const before = p.startDate.getTime();
  p.openTimeForm(true);
  assert.equal(p.startDate.getTime(), before);
  options.builder.onConfirm(new Date(2026, 8, 16, 9, 30));
  assert.equal(p.startHour, 9); assert.equal(p.startMinute, 30);
  p.openTimeForm(false); options.builder.onConfirm(new Date(2026, 8, 17, 18, 15));
  assert.equal(p.endHour, 18); assert.equal(p.endMinute, 15);
});
console.log(`\n${passed} frontend logic tests passed. Native camera/album/layout still require device testing.`);
