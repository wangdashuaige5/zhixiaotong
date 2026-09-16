// 教学工作流回归：执行实际页面方法并模拟接口，不写入真实业务数据库。
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const ts = require(process.env.TYPESCRIPT_PATH ||
  '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const root = path.join(__dirname, '../entry/src/main/ets');
function execute(source, globals = {}) {
  const out = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS } });
  const context = { exports: {}, ...globals }; vm.runInNewContext(out.outputText, context); return context.exports;
}
const helper = execute(fs.readFileSync(path.join(root, 'common/TeachingWorkflows.ets'), 'utf8'));
function page(file, name, marker, globals) {
  let source = fs.readFileSync(path.join(root, 'pages', file), 'utf8');
  source = source.slice(0, source.indexOf(marker)).replace(/^import[\s\S]*?;\n/gm, '')
    .replace(/@(Entry|Component|State)\s*/g, '').replace(/struct /g, 'class ');
  return execute(source + '\n}\nexports.Page = ' + name + ';', { ...helper, ...globals }).Page;
}
class ApiException extends Error {}
let calls = [], toasts = [], responses = new Map(), dialogAnswer = 1;
const HttpClient = {
  get: async (url, query) => { calls.push({ method: 'get', url, query }); return { data: responses.get(url) ?? [] }; },
  post: async (url, body) => { calls.push({ method: 'post', url, body }); return { data: {} }; },
  put: async (url, body) => { calls.push({ method: 'put', url, body }); return { data: {} }; }
};
const globals = { HttpClient, ApiException, promptAction: { showToast: data => toasts.push(data.message),
  showDialog: async () => ({ index: dialogAnswer }) } };
const Assignments = page('AssignmentsPage.ets', 'AssignmentsPage', '  build() {', globals);
const Grades = page('GradesPage.ets', 'GradesPage', '  @Builder', globals);
const Records = page('AttendanceRecordsPage.ets', 'AttendanceRecordsPage', '  build() {',
  { ...globals, router: { getParams: () => ({ task_id: '../admin' }) } });
let passed = 0;
async function test(name, fn) { calls = []; toasts = []; responses = new Map(); dialogAnswer = 1; await fn(); passed++; console.log('PASS ' + name); }
const choice = { id: '9007199254740993', course_id: '42', course_name: '软件工程', class_name: '软件一班', teacher_id: '8', semester_id: '2' };
const assignment = { id: '100', max_score: '100', allow_late: 0, deadline: '2099-09-20T23:59:00+08:00', assignment_title: '设计作业' };
function teacherAssignment() { const p = new Assignments(); p.classes = [choice]; p.classIndex = 0; p.userId = '8'; return p; }
function teacherGrade() { const p = new Grades(); p.classes = [choice]; p.classIndex = 0; p.canWrite = true; p.mode = 'teacher'; return p; }
(async () => {
  await test('分数拒绝负数、科学计数和超精度', () => {
    for (const text of ['-1', '1e2', '2.001', 'Infinity', 'abc']) assert.notEqual(helper.scoreInputError(text, 100), '');
  });
  await test('分数允许0与上界100、草稿允许空值', () => {
    for (const text of ['0', '99.99', '100']) assert.equal(helper.scoreInputError(text, 100), '');
    assert.equal(helper.scoreInputError('', 100, false), ''); assert.notEqual(helper.scoreInputError('', 100), '');
  });
  await test('截止时间为中国时区且禁止过期', () => {
    assert.equal(helper.assignmentDeadline('2099-09-20', '09:30', 0), '2099-09-20T09:30:00+08:00');
    assert.throws(() => helper.assignmentDeadline('2020-01-01', '09:30', Date.now()));
    assert.throws(() => helper.assignmentDeadline('2099-09-20', '25:00', 0));
  });
  await test('教学班展示不含手填内部ID', () => { assert.equal(helper.classChoiceLabel(choice), '软件工程 · 软件一班'); });
  await test('选择课程带真实课程和大整数教学班ID', async () => {
    const p = teacherAssignment(); await p.selectClass(0);
    assert.equal(calls[0].url, '/api/courses/42/assignments'); assert.equal(calls[0].query.get('teaching_class_id'), choice.id);
  });
  await test('换课清空上份作业的提交内容与批改记录', async () => {
    const p = teacherAssignment(); p.submitContent = '旧课程'; p.selectedAssignment = assignment;
    await p.selectClass(0); assert.equal(p.submitContent, ''); assert.equal(p.selectedAssignment, null);
  });
  await test('按所选班任课教师ID判断身份，不凭全局teacher角色越权', () => {
    const p = teacherAssignment(); assert.equal(p.isTeacher(), true); p.userId = '9'; assert.equal(p.isTeacher(), false);
  });
  await test('未选课不请求固定课程5', async () => { const p = new Assignments(); await p.fetchAssignments(); assert.equal(calls.length, 0); });
  await test('学生首次提交和退回后可重交，待批改/已发布不可重交', () => {
    const p = teacherAssignment(); p.userId = '9'; p.selectedAssignment = assignment;
    assert.equal(p.canSubmit(), true);
    p.submissions = [{ submit_round: 1, submit_status: 1 }]; assert.equal(p.canSubmit(), true);
    p.submissions.push({ submit_round: 2, submit_status: 0 }); assert.equal(p.canSubmit(), false);
    p.submissions[1].submit_status = 3; assert.equal(p.canSubmit(), false);
  });
  await test('禁止未授权迟交', () => {
    const p = teacherAssignment(); p.userId = '9'; p.selectedAssignment = { ...assignment, deadline: '2020-01-01' };
    assert.equal(p.canSubmit(), false); p.selectedAssignment.allow_late = 1; assert.equal(p.canSubmit(), true);
  });
  await test('发布作业不再使用课程5，content必填', async () => {
    const p = teacherAssignment(); p.title = '作业'; p.content = ''; await p.createAssignment(); assert.equal(calls.length, 0);
    p.content = '说明'; p.deadlineDate = '2099-09-20'; await p.createAssignment();
    assert.equal(calls[0].url, '/api/courses/42/assignments'); assert.equal(calls[0].body.teaching_class_id, choice.id);
  });
  await test('操作忙碌时禁止重复发布', async () => { const p = teacherAssignment(); p.busy = true; await p.createAssignment(); assert.equal(calls.length, 0); });
  await test('评分超满分不能发送', async () => {
    const p = teacherAssignment(); p.selectedAssignment = assignment; p.selectedSubmission = { id: '1', submit_status: 0 }; p.score = '101';
    await p.gradeSubmission('grade'); assert.equal(calls.length, 0);
  });
  await test('退回必须有反馈', async () => {
    const p = teacherAssignment(); p.selectedAssignment = assignment; p.selectedSubmission = { id: '1', submit_status: 0 };
    await p.gradeSubmission('return'); assert.equal(calls.length, 0);
  });
  await test('评分保存不等于发布且发正确动作', async () => {
    const p = teacherAssignment(); p.selectedAssignment = assignment; p.selectedSubmission = { id: '3', submit_status: 0 }; p.score = '80';
    await p.gradeSubmission('grade'); assert.equal(calls[0].url, '/api/submissions/3/grade'); assert.equal(calls[0].body.action, 'grade'); assert.equal(calls[0].body.score, 80);
  });
  await test('未批改作业不能发布成绩', async () => {
    const p = teacherAssignment(); p.selectedAssignment = assignment; p.selectedSubmission = { id: '1', submit_status: 0 };
    await p.gradeSubmission('publish'); assert.equal(calls.length, 0);
  });
  await test('教师成绩名册使用真实教学班', async () => {
    const p = teacherGrade(); await p.fetchRoster(); assert.equal(calls[0].url, '/api/courses/42/grades'); assert.equal(calls[0].query.get('teaching_class_id'), choice.id);
  });
  await test('保存成绩保留版本号和选课ID，空分不转成0', async () => {
    const p = teacherGrade(); p.selectedGrade = { enrollment_id: '9999999999999999', version: 7, grade_status: 2 };
    p.usualScore = ''; p.finalScore = '90'; await p.saveGrade();
    const row = calls[0].body.items[0]; assert.equal(row.version, 7); assert.equal(row.enrollment_id, '9999999999999999');
    assert.equal('usual_score' in row, false); assert.equal(row.final_score, 90);
  });
  await test('待审核成绩不能直接保存', async () => {
    const p = teacherGrade(); p.selectedGrade = { grade_status: 1 }; await p.saveGrade(); assert.equal(calls.length, 0);
  });
  await test('已发布成绩只能走更正申请接口', async () => {
    const p = teacherGrade(); p.selectedGrade = { id: '55', enrollment_id: '1', grade_status: 3, version: 8 };
    p.usualScore = '75'; p.finalScore = '80'; p.changeReason = '核对原卷后调整'; await p.saveGrade();
    assert.equal(calls[0].url, '/api/grades/55/changes'); assert.equal(calls[0].body.version, 8);
  });
  await test('更正缺理由和缓考直接更正被拦截', async () => {
    const p = teacherGrade(); p.selectedGrade = { id: '55', grade_status: 3 }; p.usualScore = '75'; p.finalScore = '80';
    await p.saveGrade(); assert.equal(calls.length, 0); p.changeReason = '原因'; p.examFlag = 2; await p.saveGrade(); assert.equal(calls.length, 0);
  });
  await test('学生成绩请求page_no/page_size并兼容字符串total', async () => {
    const p = new Grades(); p.semesters = [{ id: '2' }]; p.pageNo = 3;
    responses.set('/api/grades/me', { items: [], total: '45' }); await p.fetchStudent();
    assert.equal(calls[0].query.get('page_no'), '3'); assert.equal(calls[0].query.get('page_size'), '20'); assert.equal(p.total, 45);
  });
  await test('提交审核不含未保存编辑并需用户确认', async () => {
    const p = teacherGrade(); p.roster = [{ grade_status: 0 }]; p.selectedGrade = { id: '2' };
    await p.confirmSubmit(); assert.equal(calls.length, 0); p.selectedGrade = null; dialogAnswer = 0;
    await p.confirmSubmit(); assert.equal(calls.length, 0); assert.equal(p.busy, false);
  });
  await test('学生实际翻页方法可调用且末页禁止越界', async () => {
    const p = new Grades(); p.semesters = [{ id: '2' }]; p.total = 21;
    responses.set('/api/grades/me', { items: [{ id: '21' }], total: '21' });
    await p.changePage(2); assert.equal(p.pageNo, 2); assert.equal(calls[0].query.get('page_no'), '2');
    await p.changePage(3); assert.equal(calls.length, 1); assert.equal(p.pageNo, 2);
  });
  await test('所有评分输入框都允许小数键盘', () => {
    for (const file of ['AssignmentsPage.ets', 'GradesPage.ets']) {
      const source = fs.readFileSync(path.join(root, 'pages', file), 'utf8');
      assert.ok(source.includes('InputType.NUMBER_DECIMAL')); assert.ok(!source.includes('InputType.Number'));
    }
  });
  await test('提交审核真实课程与教学班', async () => {
    const p = teacherGrade(); p.roster = [{ grade_status: 0 }]; await p.confirmSubmit();
    assert.equal(calls[0].url, '/api/courses/42/grades/submit'); assert.equal(calls[0].body.teaching_class_id, choice.id);
  });
  await test('成绩审核驳回必须填写意见', async () => {
    const p = new Grades(); p.canReview = true; p.selectedReview = { id: '2' }; await p.decide(2); assert.equal(calls.length, 0);
  });
  await test('成绩更正审核发送正确decision和意见', async () => {
    const p = new Grades(); p.canReview = true; p.selectedChange = { id: '9' }; p.reviewComment = '核对无误';
    await p.decide(1); assert.equal(calls[0].url, '/api/grade-changes/9/decision'); assert.equal(calls[0].body.decision, 1);
  });
  await test('审核快照兼容数组与JSON字符串', () => {
    const p = new Grades(); p.openReview({ id: '1', grade_snapshot: '[{"id":"2","total_score":"88"}]' }); assert.equal(p.reviewScores[0].total_score, '88');
    p.openReview({ id: '3', grade_snapshot: [{ id: '4', real_name: '同学' }] }); assert.equal(p.reviewScores[0].real_name, '同学');
  });
  await test('签到记录拒绝路径注入型任务参数', () => {
    const p = new Records(); p.aboutToAppear(); assert.equal(calls.length, 0); assert.ok(p.error.includes('缺少有效签到任务'));
  });
  await test('签到记录刷新不写业务数据且保留任务大整数ID', async () => {
    const p = new Records(); p.taskId = '9007199254740993'; await p.loadRecords();
    assert.equal(calls[0].method, 'get'); assert.equal(calls[0].url, '/api/attendance/tasks/9007199254740993/records');
  });
  await test('签到状态映射不将未签推算成缺勤', () => { const p = new Records(); assert.equal(p.stateText(0), '待签'); assert.equal(p.stateText(4), '缺勤'); });
  console.log(`\n${passed} teaching workflow tests passed. UI layout and true device flows need separate validation.`);
})().catch(error => { console.error(error); process.exitCode = 1; });
