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
const semester = {id: '5', start_date: '2099-09-07', week_count: 20};
const course = {id: '9007199254740993', course_id: '22', teaching_class_id: '33',
  course_name: '软件工程', class_name: '软件一班', room_name: 'A101',
  start_period: 1, end_period: 2, start_time: '08:00:00', end_time: '09:40:00',
  week_day: 2, start_week: 1, end_week: 20, week_mode: 1};
let timetableCalls = [];
const api = {semesters: async () => [semester], timetables: async (id, week) => {
  timetableCalls.push({id, week}); return [course];
}};
const Page = compile(source + '\n}\nexports.Page = AttendancePage;', {
  ...qr, Error, ApiException: class extends Error {},
  CampusApi: api,
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
function selectFixture(p, date) {
  p.classDate = date; p.loadedDate = date; p.courses = [course]; p.selectCourse(course.id);
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
    ['截止等于开始', '2099-09-15', '08:00', '08:00'],
    ['达到4小时', '2099-09-15', '08:00', '12:00']
  ]) {
    await test(name + '禁止提交', async () => {
      const p = instance(); selectFixture(p, date); p.startTime = start; p.endTime = end;
      if (!date) { p.courses = []; }
      const before = requests.length; await p.createTask(); assert.equal(requests.length, before);
    });
  }
  await test('合法选择仍调用原接口并保留二维码', async () => {
    const p = instance(); selectFixture(p, '2099-09-15'); p.startTime = '08:00'; p.endTime = '08:15';
    await p.createTask(); const request = requests[requests.length - 1];
    assert.equal(request.url, '/api/attendance/tasks');
    assert.equal(request.body.timetable_id, course.id);
    assert.notEqual(request.body.timetable_id, course.course_id);
    assert.notEqual(request.body.timetable_id, course.teaching_class_id);
    assert.equal(request.body.start_time, '2099-09-15T08:00:00+08:00');
    assert.equal(request.body.end_time, '2099-09-15T08:15:00+08:00');
    assert.equal(JSON.parse(p.qrValue).sign_code, '001234'); assert.equal(p.busy, false);
  });
  await test('周次算法与后端一致，周一为一周起点，不受本机时区影响', () => {
    const p = instance();
    const sem = {...semester, start_date: '2026-09-09'};
    assert.equal(p.semesterWeek(sem, '2026-09-07'), 1);
    assert.equal(p.semesterWeek(sem, '2026-09-13'), 1);
    assert.equal(p.semesterWeek(sem, '2026-09-14'), 2);
    assert.equal(p.semesterWeek(sem, '2026-09-06'), 0);
  });
  await test('单双周、起止周与星期严格匹配', () => {
    const p = instance();
    assert.equal(p.courseMatches({...course, week_mode: 2}, 1, 2), true);
    assert.equal(p.courseMatches({...course, week_mode: 2}, 2, 2), false);
    assert.equal(p.courseMatches({...course, week_mode: 3}, 2, 2), true);
    assert.equal(p.courseMatches({...course, week_mode: 3}, 1, 2), false);
    for (const [week, day] of [[0, 2], [21, 2], [1, 1]]) {
      assert.equal(p.courseMatches(course, week, day), false);
    }
  });
  await test('加载选择日期所在周，仅列当天排课，不自动误选课程', async () => {
    const p = instance(); p.classDate = '2099-09-15';
    api.timetables = async (id, week) => {timetableCalls.push({id, week});
      return [course, {...course, id: '2', week_day: 3}, {...course, id: '3', week_mode: 2}];};
    await p.loadCourses();
    assert.deepEqual(timetableCalls.at(-1), {id: '5', week: 2});
    assert.equal(p.courses.length, 1); assert.equal(p.courses[0].id, course.id);
    assert.equal(p.timetableId, ''); assert.equal(p.loadedDate, p.classDate);
  });
  await test('同课程不同教学班/排课记录可区分，不按课程 ID 合并', async () => {
    api.timetables = async () => [course, {...course, id: '44', class_name: '软件二班'}];
    const p = instance(); p.classDate = '2099-09-15'; await p.loadCourses();
    assert.equal(p.courses.length, 2); p.selectCourse('44'); assert.equal(p.timetableId, '44');
    assert.ok(p.courseLabel(p.courses[1]).includes('软件二班'));
  });
  await test('更换日期立即清空旧排课和二维码，当天无课不能发布', async () => {
    const p = instance(); selectFixture(p, '2099-09-15'); p.qrValue = 'old'; p.createdTask = {id: '17'};
    p.classDate = '2099-09-16'; const promise = p.loadCourses();
    assert.equal(p.timetableId, ''); assert.equal(p.qrValue, ''); assert.equal(p.createdTask, null);
    await promise; assert.equal(p.courses.length, 0);
    const before = requests.length; await p.createTask(); assert.equal(requests.length, before);
  });
  await test('无学期或非法日期不向课表接口发送无效周次', async () => {
    let calls = 0; api.timetables = async () => {calls++; return [];};
    for (const date of ['2000-09-15', '2099-02-30', 'bad']) {
      const p = instance(); p.classDate = date; await p.loadCourses();
      assert.ok(p.coursesError); assert.equal(p.coursesLoading, false);
    }
    assert.equal(calls, 0);
  });
  await test('课表请求失败不保留旧 ID，重试可以恢复', async () => {
    api.timetables = async () => {throw new Error('网络错误');};
    const p = instance(); selectFixture(p, '2099-09-15'); await p.loadCourses();
    assert.equal(p.coursesError, '网络错误'); assert.equal(p.timetableId, '');
    api.timetables = async () => [course]; await p.loadCourses();
    assert.equal(p.coursesError, ''); assert.equal(p.courses.length, 1);
  });
  await test('日期快速切换时旧响应不能覆盖新课表', async () => {
    let resolveOld, started;
    const firstStarted = new Promise(resolve => {started = resolve;});
    api.timetables = () => new Promise(resolve => {resolveOld = resolve; started();});
    const p = instance(); p.classDate = '2099-09-15'; const old = p.loadCourses(); await firstStarted;
    api.timetables = async () => [{...course, id: '55', week_day: 3}];
    p.classDate = '2099-09-16'; await p.loadCourses(); resolveOld([course]); await old;
    assert.equal(p.loadedDate, '2099-09-16'); assert.equal(p.courses[0].id, '55');
  });
  await test('手填伪造 ID、旧日期或加载中均不能发布', async () => {
    for (const state of [{timetableId: '22'}, {loadedDate: '2099-09-14'}, {coursesLoading: true}]) {
      const p = instance(); selectFixture(p, '2099-09-15'); p.startTime = '08:00'; p.endTime = '08:15';
      Object.assign(p, state); const before = requests.length;
      await p.createTask(); assert.equal(requests.length, before);
    }
  });
  await test('发布请求未完成时不能换课或重复发布', async () => {
    const p = instance(); selectFixture(p, '2099-09-15'); p.startTime = '08:00'; p.endTime = '08:15';
    p.courses.push({...course, id: '66'}); const before = requests.length;
    const pending = p.createTask(); p.selectCourse('66'); await p.createTask();
    assert.equal(p.timetableId, course.id); await pending; assert.equal(requests.length, before + 1);
    assert.ok(p.createdCourse.includes('软件工程'));
  });
  await test('历史日期的课程安排也允许发布，不读取当前时刻比较', async () => {
    const p=instance(); selectFixture(p,'2000-09-15'); p.startTime='08:00'; p.endTime='08:30';
    const before=requests.length; await p.createTask(); assert.equal(requests.length,before+1);
    assert.ok(p.qrValue); assert.equal(p.teacherStatus(),'签到开放中（手动结束）');
  });
  await test('选课默认时间来自课表，而非当前手机时间',()=>{
    const p=instance();selectFixture(p,'2099-09-15'); assert.equal(p.startTime,'08:00');assert.equal(p.endTime,'09:40');
  });
  console.log(passed + ' attendance date/time tests passed.');
})().catch(error => { console.error(error); process.exitCode = 1; });
