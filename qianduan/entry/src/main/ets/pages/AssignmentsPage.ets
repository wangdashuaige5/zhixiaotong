import { promptAction } from '@kit.ArkUI';
import { ApiException, HttpClient } from '../common/Http';
import { formatDateTime } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { AssignmentItem, SemesterItem } from '../model/Models';
import { TeachingClassChoice, classChoiceLabel, scoreInputError, submissionStateText,
  teachingDate, teachingTime, assignmentDeadline } from '../common/TeachingWorkflows';

interface SubmissionRow {
  id: string;
  student_id: string;
  real_name?: string;
  user_no?: string;
  content?: string;
  submit_round: number;
  submit_status: number;
  submit_time: string;
  feedback?: string;
  score?: string;
}

@Entry
@Component
struct AssignmentsPage {
  @State classes: TeachingClassChoice[] = [];
  @State semesters: SemesterItem[] = [];
  @State semesterIndex: number = 0;
  @State classIndex: number = -1;
  @State userId: string = '';
  @State items: AssignmentItem[] = [];
  @State loading: boolean = false;
  @State busy: boolean = false;
  @State error: string = '';
  @State pageNo: number = 1;
  @State selectedAssignment: AssignmentItem | null = null;
  @State submissions: SubmissionRow[] = [];
  @State submissionPage: number = 1;
  @State selectedSubmission: SubmissionRow | null = null;
  @State submitContent: string = '';
  @State score: string = '';
  @State feedback: string = '';
  @State title: string = '';
  @State deadlineDate: string = teachingDate(new Date(Date.now() + 86400000));
  @State deadlineTime: string = '23:59';
  @State maxScore: string = '100';
  @State content: string = '';
  @State allowLate: boolean = false;
  private readonly pageSize: number = 10;

  aboutToAppear(): void { this.initialize(); }

  // 功能：先加载身份、学期和本人相关教学班，彻底移除固定课程/教学班编号。
  async initialize(): Promise<void> {
    if (this.loading || this.busy) { return; }
    this.loading = true;
    this.error = '';
    try {
      const me = await CampusApi.me();
      this.userId = String(me.id);
      this.semesters = (await HttpClient.get('/api/semesters')).data as SemesterItem[];
      const current = this.semesters.findIndex((item: SemesterItem) => item.is_current === 1);
      this.semesterIndex = current >= 0 ? current : 0;
      await this.fetchClasses();
    } catch (e) { this.error = this.message(e, '教学班加载失败'); }
    finally { this.loading = false; }
  }

  async fetchClasses(): Promise<void> {
    this.classIndex = -1;
    this.items = [];
    this.classes = [];
    this.clearSelection();
    if (this.semesters.length === 0) { return; }
    const query = new Map<string, string>();
    query.set('semester_id', String(this.semesters[this.semesterIndex].id));
    this.classes = (await HttpClient.get('/api/teaching-classes/mine', query)).data as TeachingClassChoice[];
    if (this.classes.length > 0) { this.classIndex = 0; await this.fetchAssignments(); }
  }

  async switchSemester(index: number): Promise<void> {
    if (this.busy || this.loading || index < 0 || index >= this.semesters.length) { return; }
    this.semesterIndex = index;
    this.loading = true;
    this.error = '';
    try { await this.fetchClasses(); }
    catch (e) { this.error = this.message(e, '教学班加载失败'); }
    finally { this.loading = false; }
  }

  isTeacher(): boolean {
    return this.classIndex >= 0 && this.classIndex < this.classes.length &&
      String(this.classes[this.classIndex].teacher_id) === this.userId;
  }

  clearSelection(): void {
    this.selectedAssignment = null;
    this.selectedSubmission = null;
    this.submissions = [];
    this.submitContent = '';
    this.score = '';
    this.feedback = '';
    this.pageNo = 1;
    this.submissionPage = 1;
  }

  async fetchAssignments(): Promise<void> {
    this.clearSelection();
    this.items = [];
    if (this.classIndex < 0) { return; }
    const choice = this.classes[this.classIndex];
    const query = new Map<string, string>();
    query.set('teaching_class_id', String(choice.id));
    this.items = (await HttpClient.get(`/api/courses/${choice.course_id}/assignments`, query)).data as AssignmentItem[];
  }

  async selectClass(index: number): Promise<void> {
    if (this.loading || this.busy || index < 0 || index >= this.classes.length) { return; }
    this.classIndex = index;
    this.loading = true;
    this.error = '';
    try { await this.fetchAssignments(); }
    catch (e) { this.error = this.message(e, '作业列表加载失败'); }
    finally { this.loading = false; }
  }

  // 功能：逐条查看作业的真实提交记录；学生只收到自己的记录，老师收到授权教学班记录。
  async openAssignment(item: AssignmentItem): Promise<void> {
    if (this.busy || this.loading) { return; }
    this.busy = true;
    this.selectedAssignment = null;
    this.submissions = [];
    this.selectedSubmission = null;
    this.submitContent = '';
    this.submissionPage = 1;
    try {
      this.submissions = (await HttpClient.get(`/api/assignments/${item.id}/submissions`)).data as SubmissionRow[];
      this.selectedAssignment = item;
    } catch (e) { this.showError(e, '作业提交记录加载失败'); }
    finally { this.busy = false; }
  }

  canSubmit(): boolean {
    if (this.isTeacher() || this.selectedAssignment === null) { return false; }
    const latest = this.submissions.reduce((previous: SubmissionRow | null, row: SubmissionRow) =>
      previous === null || row.submit_round > previous.submit_round ? row : previous, null);
    return (latest === null || latest.submit_status === 1) &&
      (this.selectedAssignment.allow_late === 1 || Date.parse(this.selectedAssignment.deadline) >= Date.now());
  }

  async submit(): Promise<void> {
    if (this.busy || this.loading || this.selectedAssignment === null || !this.canSubmit()) { return; }
    if (this.submitContent.trim().length === 0 || this.submitContent.length > 30000) {
      promptAction.showToast({ message: '请填写提交内容，不超过 30000 字' }); return;
    }
    this.busy = true;
    try {
      const body: Record<string, string> = { 'content': this.submitContent.trim() };
      await HttpClient.post(`/api/assignments/${this.selectedAssignment.id}/submissions`, body);
      this.submitContent = '';
      this.submissions = (await HttpClient.get(`/api/assignments/${this.selectedAssignment.id}/submissions`)).data as SubmissionRow[];
      promptAction.showToast({ message: '作业已提交' });
    } catch (e) { this.showError(e, '作业提交或刷新失败，请刷新记录确认结果后再操作'); }
    finally { this.busy = false; }
  }

  selectSubmission(row: SubmissionRow): void {
    if (this.busy) { return; }
    this.selectedSubmission = row;
    this.score = row.score === undefined || row.score === null ? '' : String(row.score);
    this.feedback = row.feedback ?? '';
  }

  // 功能：评分先存为待发布；退回必须给出理由，发布必须已评分，禁止重复并发操作。
  async gradeSubmission(action: string): Promise<void> {
    if (this.busy || this.loading || !this.isTeacher() || this.selectedSubmission === null ||
      this.selectedAssignment === null) { return; }
    const row = this.selectedSubmission;
    if ((action === 'publish' && row.submit_status !== 2) ||
      (action !== 'publish' && row.submit_status !== 0 && row.submit_status !== 2)) { return; }
    let invalid = action === 'grade' ? scoreInputError(this.score, Number(this.selectedAssignment.max_score)) : '';
    if (action === 'return' && this.feedback.trim().length === 0) { invalid = '退回作业请填写反馈原因'; }
    if (this.feedback.length > 10000) { invalid = '反馈最多 10000 字'; }
    if (invalid.length > 0) { promptAction.showToast({ message: invalid }); return; }
    this.busy = true;
    try {
      const body: Record<string, Object> = { 'action': action, 'feedback': this.feedback.trim() };
      if (action === 'grade') { body['score'] = Number(this.score); }
      await HttpClient.put(`/api/submissions/${row.id}/grade`, body);
      this.selectedSubmission = null;
      this.submissions = (await HttpClient.get(`/api/assignments/${this.selectedAssignment.id}/submissions`)).data as SubmissionRow[];
      promptAction.showToast({ message: action === 'grade' ? '评分已保存，请确认后发布' : action === 'return' ? '已退回作业' : '作业成绩已发布' });
    } catch (e) { this.showError(e, '处理或刷新失败，请刷新记录确认结果后再操作'); }
    finally { this.busy = false; }
  }

  pickDate(): void {
    if (this.busy || this.loading) { return; }
    this.getUIContext().showDatePickerDialog({
      start: new Date(), end: new Date(2100, 11, 31), selected: new Date(`${this.deadlineDate}T12:00:00`),
      onAccept: (value: DatePickerResult) => {
        if (value.year !== undefined && value.month !== undefined && value.day !== undefined) {
          this.deadlineDate = teachingDate(new Date(value.year, value.month, value.day));
        }
      }
    });
  }

  pickTime(): void {
    if (this.busy || this.loading) { return; }
    this.getUIContext().showTimePickerDialog({ useMilitaryTime: true,
      selected: new Date(`${this.deadlineDate}T${this.deadlineTime}:00`),
      onAccept: (value: TimePickerResult) => {
        if (value.hour !== undefined && value.minute !== undefined) {
          this.deadlineTime = teachingTime(value.hour, value.minute);
        }
      }
    });
  }

  async createAssignment(): Promise<void> {
    if (this.busy || this.loading || !this.isTeacher()) { return; }
    if (this.title.trim().length === 0 || this.title.trim().length > 128 || this.content.trim().length === 0 || this.content.length > 30000) {
      promptAction.showToast({ message: '标题须为 1–128 字，作业说明须为 1–30000 字' }); return;
    }
    const invalid = scoreInputError(this.maxScore, 9999);
    if (invalid.length > 0 || Number(this.maxScore) <= 0) {
      promptAction.showToast({ message: invalid || '作业满分必须大于 0' }); return;
    }
    let deadline = '';
    try { deadline = assignmentDeadline(this.deadlineDate, this.deadlineTime, Date.now()); }
    catch (e) { this.showError(e, '截止时间不合法'); return; }
    const choice = this.classes[this.classIndex];
    this.busy = true;
    try {
      const body: Record<string, Object> = { 'teaching_class_id': String(choice.id),
        'assignment_title': this.title.trim(), 'content': this.content.trim(), 'deadline': deadline,
        'max_score': Number(this.maxScore), 'allow_late': this.allowLate ? 1 : 0, 'publish_status': 1 };
      await HttpClient.post(`/api/courses/${choice.course_id}/assignments`, body);
      this.title = ''; this.content = '';
      await this.fetchAssignments();
      promptAction.showToast({ message: '作业已发布' });
    } catch (e) { this.showError(e, '发布或刷新失败，请刷新列表确认结果后再操作'); }
    finally { this.busy = false; }
  }

  message(e: Object, fallback: string): string { return e instanceof ApiException || e instanceof Error ? e.message : fallback; }
  showError(e: Object, fallback: string): void { promptAction.showToast({ message: this.message(e, fallback) }); }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('课程作业').fontSize(24).fontWeight(FontWeight.Bold).width('100%')
        if (this.semesters.length > 0) {
          Select(this.semesters.map((item: SemesterItem): SelectOption => ({ value: item.semester_name })))
            .selected(this.semesterIndex).value(this.semesters[this.semesterIndex]?.semester_name ?? '选择学期')
            .enabled(!this.busy && !this.loading).width('100%')
            .onSelect((index: number) => { this.switchSemester(index); })
        }
        if (this.classes.length > 0) {
          Select(this.classes.map((item: TeachingClassChoice): SelectOption => ({ value: classChoiceLabel(item) })))
            .selected(this.classIndex).value(this.classIndex >= 0 ? classChoiceLabel(this.classes[this.classIndex]) : '选择教学班')
            .enabled(!this.busy && !this.loading).width('100%')
            .onSelect((index: number) => { this.selectClass(index); })
          Button('刷新作业').enabled(!this.busy && !this.loading).onClick(() => { this.selectClass(this.classIndex); })
        }
        if (this.loading || this.busy) { Text('正在处理，请稍候…').fontColor('#666666') }
        if (this.error.length > 0) {
          Text(this.error).fontColor('#D9534F')
          Button('重试').enabled(!this.busy && !this.loading).onClick(() => { this.initialize(); })
        } else if (!this.loading && this.classes.length === 0) {
          Text('本学期暂无相关教学班。学生请先在选课管理中完成选课，教师请确认已分配授课教学班。').fontColor('#666666')
        } else if (!this.loading && this.items.length === 0) { Text('该教学班暂无作业').fontColor('#666666') }
        ForEach(this.items.slice((this.pageNo - 1) * this.pageSize, this.pageNo * this.pageSize), (item: AssignmentItem) => {
          Column({ space: 6 }) {
            Text(item.assignment_title).fontSize(18).fontWeight(FontWeight.Bold)
            Text(`满分 ${item.max_score} · 截止 ${formatDateTime(item.deadline)}`).fontSize(13)
            Text(item.allow_late === 1 ? '允许迟交' : '截止后不可提交').fontSize(12).fontColor('#666666')
            Text(item.content ?? '').width('100%')
            Button(this.isTeacher() ? '查看提交与批改' : '查看提交记录 / 提交作业')
              .enabled(!this.busy && !this.loading).onClick(() => { this.openAssignment(item); })
          }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
        }, (item: AssignmentItem) => String(item.id))
        if (this.items.length > this.pageSize) {
          Row({ space: 12 }) {
            Button('上一页').enabled(this.pageNo > 1 && !this.busy).onClick(() => { this.pageNo--; })
            Text(`${this.pageNo} / ${Math.ceil(this.items.length / this.pageSize)}`)
            Button('下一页').enabled(this.pageNo * this.pageSize < this.items.length && !this.busy).onClick(() => { this.pageNo++; })
          }
        }
        if (this.selectedAssignment !== null) {
          Column({ space: 10 }) {
            Text(`提交记录：${this.selectedAssignment.assignment_title}`).fontSize(18).fontWeight(FontWeight.Bold)
            Text(this.isTeacher() ? '包含历史提交轮次，不等于未交名单。' : '成绩由教师发布后可见；退回后可重新提交。').fontSize(12).fontColor('#666666')
            if (this.submissions.length === 0) { Text('暂无提交记录') }
            ForEach(this.submissions.slice((this.submissionPage - 1) * this.pageSize, this.submissionPage * this.pageSize), (row: SubmissionRow) => {
              Column({ space: 6 }) {
                Text(`${row.real_name ?? '学生'} ${row.user_no ?? ''} · 第 ${row.submit_round} 次`).fontWeight(FontWeight.Bold)
                Text(submissionStateText(row.submit_status)).fontColor('#002FA7')
                Text(formatDateTime(row.submit_time)).fontSize(12)
                Text(row.content ?? '').width('100%')
                if (row.score !== undefined && row.score !== null) { Text(`得分：${row.score}`) }
                if (row.feedback) { Text(`教师反馈：${row.feedback}`) }
                if (this.isTeacher() && (row.submit_status === 0 || row.submit_status === 2)) {
                  Button('批改这份提交').enabled(!this.busy).onClick(() => { this.selectSubmission(row); })
                }
              }.padding(10).width('100%').backgroundColor('#F2F4F8').borderRadius(8)
            }, (row: SubmissionRow) => String(row.id))
            if (this.submissions.length > this.pageSize) {
              Row({ space: 10 }) {
                Button('上一页').enabled(this.submissionPage > 1 && !this.busy).onClick(() => { this.submissionPage--; })
                Text(`${this.submissionPage} / ${Math.ceil(this.submissions.length / this.pageSize)}`)
                Button('下一页').enabled(this.submissionPage * this.pageSize < this.submissions.length && !this.busy).onClick(() => { this.submissionPage++; })
              }
            }
            if (this.canSubmit()) {
              TextArea({ placeholder: '填写本次作业内容', text: this.submitContent }).height(120).enabled(!this.busy)
                .onChange((value: string) => { this.submitContent = value; })
              Button('确认提交作业').enabled(!this.busy).onClick(() => { this.submit(); })
            }
            if (this.isTeacher() && this.selectedSubmission !== null) {
              Text(`批改 ${this.selectedSubmission.real_name ?? '所选学生'} 的第 ${this.selectedSubmission.submit_round} 次提交`).fontWeight(FontWeight.Bold)
              TextInput({ placeholder: `得分（0–${this.selectedAssignment.max_score}）`, text: this.score })
                .type(InputType.NUMBER_DECIMAL).enabled(!this.busy).onChange((value: string) => { this.score = value; })
              TextArea({ placeholder: '反馈 / 退回原因', text: this.feedback }).height(90).enabled(!this.busy)
                .onChange((value: string) => { this.feedback = value; })
              Row({ space: 8 }) {
                Button('保存评分').enabled(!this.busy).onClick(() => { this.gradeSubmission('grade'); })
                Button('退回重做').enabled(!this.busy).onClick(() => { this.gradeSubmission('return'); })
              }
              if (this.selectedSubmission.submit_status === 2) {
                Button('发布已保存的成绩').enabled(!this.busy).onClick(() => { this.gradeSubmission('publish'); })
              }
            }
          }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
        }
        if (this.isTeacher()) {
          Column({ space: 10 }) {
            Text('发布新作业').fontSize(18).fontWeight(FontWeight.Bold)
            TextInput({ placeholder: '作业标题', text: this.title }).maxLength(128).enabled(!this.busy)
              .onChange((value: string) => { this.title = value; })
            TextArea({ placeholder: '作业说明（必填）', text: this.content }).height(110).enabled(!this.busy)
              .onChange((value: string) => { this.content = value; })
            Button(`截止日期：${this.deadlineDate}`).enabled(!this.busy).onClick(() => { this.pickDate(); })
            Button(`截止时间：${this.deadlineTime}`).enabled(!this.busy).onClick(() => { this.pickTime(); })
            TextInput({ placeholder: '作业满分', text: this.maxScore }).type(InputType.NUMBER_DECIMAL).enabled(!this.busy)
              .onChange((value: string) => { this.maxScore = value; })
            Row({ space: 10 }) {
              Text('允许迟交')
              Toggle({ type: ToggleType.Switch, isOn: this.allowLate }).enabled(!this.busy)
                .onChange((value: boolean) => { this.allowLate = value; })
            }
            Button('确认发布到所选教学班').width('100%').enabled(!this.busy && !this.loading)
              .onClick(() => { this.createAssignment(); })
          }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
        }
      }.padding(20).width('100%')
    }.width('100%').height('100%').backgroundColor('#F2F4F8')
  }
}
