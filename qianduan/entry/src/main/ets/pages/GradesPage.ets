import { promptAction } from '@kit.ArkUI';
import { ApiException, HttpClient } from '../common/Http';
import { examFlagText, formatDateTime } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { GradeItem, PageData, SemesterItem } from '../model/Models';
import { TeachingClassChoice, classChoiceLabel, scoreInputError, gradeStateText } from '../common/TeachingWorkflows';

interface ClassGrade {
  id?: string;
  enrollment_id: string;
  real_name: string;
  user_no: string;
  usual_score?: string;
  final_score?: string;
  total_score?: string;
  grade_status?: number;
  exam_flag?: number;
  version?: number;
}
interface ReviewScore {
  id: string;
  real_name?: string;
  user_no?: string;
  usual_score?: string;
  final_score?: string;
  total_score?: string;
  exam_flag: number;
}
interface GradeReview {
  id: string;
  teaching_class_id: string;
  course_name?: string;
  class_name?: string;
  submitter_name?: string;
  review_round: number;
  submit_time: string;
  warning_note?: string;
  grade_snapshot: string | ReviewScore[];
}
interface GradeValue {
  usual_score?: string;
  final_score?: string;
  total_score?: string;
  exam_flag?: number;
}
interface GradeChange {
  id: string;
  course_name: string;
  class_name: string;
  student_name: string;
  user_no: string;
  applicant_name: string;
  change_reason: string;
  before_value: GradeValue;
  after_value: GradeValue;
}

@Entry
@Component
struct GradesPage {
  @State mode: string = 'student';
  @State canStudent: boolean = false;
  @State canWrite: boolean = false;
  @State canReview: boolean = false;
  @State semesters: SemesterItem[] = [];
  @State semesterIndex: number = 0;
  @State classes: TeachingClassChoice[] = [];
  @State classIndex: number = -1;
  @State items: GradeItem[] = [];
  @State roster: ClassGrade[] = [];
  @State reviews: GradeReview[] = [];
  @State changes: GradeChange[] = [];
  @State pageNo: number = 1;
  @State total: number = 0;
  @State reviewPage: number = 1;
  @State changeReviewPage: number = 1;
  @State selectedGrade: ClassGrade | null = null;
  @State selectedReview: GradeReview | null = null;
  @State reviewScores: ReviewScore[] = [];
  @State selectedChange: GradeChange | null = null;
  @State usualScore: string = '';
  @State finalScore: string = '';
  @State examFlag: number = 0;
  @State changeReason: string = '';
  @State reviewComment: string = '';
  @State loading: boolean = false;
  @State busy: boolean = false;
  @State error: string = '';
  private userId: string = '';
  private readonly pageSize: number = 20;

  aboutToAppear(): void { this.initialize(); }

  // 功能：学生查分、任课教师录入、教务秘书审核按当前账号权限分别显示。
  async initialize(): Promise<void> {
    if (this.loading || this.busy) { return; }
    this.loading = true;
    this.error = '';
    try {
      const me = await CampusApi.me();
      this.userId = String(me.id);
      this.canStudent = me.roles.some((role) => role.role_code === 'STUDENT');
      this.canWrite = me.permissions.indexOf('grade:write') >= 0;
      this.canReview = me.permissions.indexOf('grade:review') >= 0;
      this.mode = this.canWrite ? 'teacher' : this.canReview ? 'review' : 'student';
      this.semesters = (await HttpClient.get('/api/semesters')).data as SemesterItem[];
      const current = this.semesters.findIndex((row: SemesterItem) => row.is_current === 1);
      this.semesterIndex = current >= 0 ? current : 0;
      await this.fetchMode();
    } catch (e) { this.error = this.message(e, '成绩页面加载失败'); }
    finally { this.loading = false; }
  }

  clearForm(): void {
    this.selectedGrade = null; this.selectedReview = null; this.selectedChange = null;
    this.reviewScores = []; this.reviewComment = ''; this.changeReason = '';
  }

  async switchMode(mode: string): Promise<void> {
    if (this.busy || this.loading || (mode === 'student' && !this.canStudent) ||
      (mode === 'teacher' && !this.canWrite) || (mode === 'review' && !this.canReview)) { return; }
    this.mode = mode; this.pageNo = 1; this.clearForm();
    this.loading = true; this.error = '';
    try { await this.fetchMode(); }
    catch (e) { this.error = this.message(e, '成绩加载失败'); }
    finally { this.loading = false; }
  }

  async fetchMode(): Promise<void> {
    this.clearForm(); this.pageNo = 1; this.items = []; this.roster = []; this.total = 0;
    if (this.mode === 'review') { await this.fetchReviews(); return; }
    if (this.semesters.length === 0) { return; }
    if (this.mode === 'student') {
      if (this.canStudent) { await this.fetchStudent(); }
      return;
    }
    const query = new Map<string, string>();
    query.set('semester_id', String(this.semesters[this.semesterIndex].id));
    const allClasses = (await HttpClient.get('/api/teaching-classes/mine', query)).data as TeachingClassChoice[];
    this.classes = allClasses.filter((row: TeachingClassChoice) => String(row.teacher_id) === this.userId);
    this.classIndex = this.classes.length > 0 ? 0 : -1;
    if (this.classIndex >= 0) { await this.fetchRoster(); }
  }

  async changeSemester(index: number): Promise<void> {
    if (this.loading || this.busy || index < 0 || index >= this.semesters.length) { return; }
    this.semesterIndex = index; this.loading = true; this.error = '';
    try { await this.fetchMode(); }
    catch (e) { this.error = this.message(e, '学期成绩加载失败'); }
    finally { this.loading = false; }
  }

  async fetchStudent(): Promise<void> {
    const query = new Map<string, string>();
    query.set('semester_id', String(this.semesters[this.semesterIndex].id));
    query.set('page_no', String(this.pageNo)); query.set('page_size', String(this.pageSize));
    const result = (await HttpClient.get('/api/grades/me', query)).data as PageData<GradeItem>;
    this.items = result.items; this.total = Number(result.total);
  }

  async changePage(page: number): Promise<void> {
    if (this.loading || this.busy || page < 1 || (page > 1 && (page - 1) * this.pageSize >= this.total)) { return; }
    if (this.mode === 'teacher') { this.pageNo = page; this.clearForm(); return; }
    const previous = this.pageNo;
    this.loading = true; this.error = ''; this.pageNo = page;
    try { await this.fetchStudent(); }
    catch (e) { this.pageNo = previous; this.error = this.message(e, '翻页失败'); }
    finally { this.loading = false; }
  }

  async selectClass(index: number): Promise<void> {
    if (this.loading || this.busy || index < 0 || index >= this.classes.length) { return; }
    this.classIndex = index; this.pageNo = 1; this.clearForm(); this.roster = [];
    this.loading = true; this.error = '';
    try { await this.fetchRoster(); }
    catch (e) { this.error = this.message(e, '学生成绩名册加载失败'); }
    finally { this.loading = false; }
  }

  async fetchRoster(): Promise<void> {
    if (this.classIndex < 0) { return; }
    const row = this.classes[this.classIndex];
    const query = new Map<string, string>(); query.set('teaching_class_id', String(row.id));
    this.roster = (await HttpClient.get(`/api/courses/${row.course_id}/grades`, query)).data as ClassGrade[];
    this.total = this.roster.length;
  }

  editGrade(row: ClassGrade): void {
    if (this.busy || this.loading || row.grade_status === 1) { return; }
    this.selectedGrade = row;
    this.usualScore = row.usual_score === undefined || row.usual_score === null ? '' : String(row.usual_score);
    this.finalScore = row.final_score === undefined || row.final_score === null ? '' : String(row.final_score);
    this.examFlag = row.exam_flag ?? 0; this.changeReason = '';
  }

  // 功能：每次仅保存所选学生，版本号来自名册；已发布成绩只能提交更正申请，不能直接覆盖。
  async saveGrade(): Promise<void> {
    if (this.busy || this.loading || this.selectedGrade === null || this.classIndex < 0 || !this.canWrite) { return; }
    const row = this.selectedGrade;
    if (row.grade_status === 1) { return; }
    const correction = row.grade_status === 3;
    let invalid = scoreInputError(this.usualScore, 100, correction);
    if (invalid.length === 0 && this.examFlag !== 1) { invalid = scoreInputError(this.finalScore, 100, correction); }
    if (correction && (this.examFlag === 2 || this.examFlag === 3)) { invalid = '缓考或免修暂不支持直接发布更正，请按学校专项流程办理'; }
    if (correction && (this.changeReason.trim().length === 0 || this.changeReason.length > 255)) { invalid = '成绩更正理由须为 1–255 字'; }
    if (invalid.length > 0) { promptAction.showToast({ message: invalid }); return; }
    const score: Record<string, Object> = { 'enrollment_id': String(row.enrollment_id), 'exam_flag': this.examFlag,
      'version': row.version ?? 0 };
    // 空分项不伪造为 0；草稿允许不完整，提交审核由服务端再次校验完整性。
    if (this.usualScore.trim().length > 0) { score['usual_score'] = Number(this.usualScore); }
    if (this.examFlag === 1) { score['final_score'] = 0; }
    else if (this.finalScore.trim().length > 0) { score['final_score'] = Number(this.finalScore); }
    this.busy = true;
    try {
      if (correction) {
        score['change_reason'] = this.changeReason.trim();
        await HttpClient.post(`/api/grades/${row.id}/changes`, score);
      } else {
        const choice = this.classes[this.classIndex];
        const body: Record<string, Object> = { 'teaching_class_id': String(choice.id), 'items': [score] };
        await HttpClient.put(`/api/courses/${choice.course_id}/grades`, body);
      }
      this.clearForm(); await this.fetchRoster();
      promptAction.showToast({ message: correction ? '更正申请已提交，审核通过后生效' : '成绩草稿已保存' });
    } catch (e) { this.showError(e, '保存或刷新失败，请刷新名册确认结果后再操作'); }
    finally { this.busy = false; }
  }

  async confirmSubmit(): Promise<void> {
    if (this.busy || this.loading || this.classIndex < 0) { return; }
    const drafts = this.roster.filter((row: ClassGrade) => row.grade_status === 0 || row.grade_status === 2);
    if (drafts.length === 0) { promptAction.showToast({ message: '请先保存学生成绩草稿' }); return; }
    if (this.selectedGrade !== null) { promptAction.showToast({ message: '请先保存或取消当前编辑，再提交审核' }); return; }
    this.busy = true;
    try {
      const answer = await promptAction.showDialog({ title: '提交成绩审核',
        message: `将提交所选教学班已保存的 ${drafts.length} 条草稿/退回成绩，未录入学生不包含在本批次中。审核通过后向学生发布。`,
        buttons: [{ text: '取消', color: '#666666' }, { text: '确认提交', color: '#002FA7' }] });
      if (answer.index !== 1) { return; }
      const choice = this.classes[this.classIndex];
      const body: Record<string, string> = { 'teaching_class_id': String(choice.id) };
      await HttpClient.post(`/api/courses/${choice.course_id}/grades/submit`, body);
      await this.fetchRoster(); promptAction.showToast({ message: '已提交教务审核' });
    } catch (e) { this.showError(e, '提交或刷新失败，请刷新名册确认结果后再操作'); }
    finally { this.busy = false; }
  }

  async fetchReviews(): Promise<void> {
    this.reviews = []; this.changes = []; this.reviewPage = 1; this.changeReviewPage = 1;
    this.reviews = (await HttpClient.get('/api/grade-reviews/pending')).data as GradeReview[];
    this.changes = (await HttpClient.get('/api/grade-changes/pending')).data as GradeChange[];
  }

  openReview(row: GradeReview): void {
    if (this.busy || this.loading) { return; }
    try {
      const scores = typeof row.grade_snapshot === 'string' ? JSON.parse(row.grade_snapshot) as ReviewScore[] : row.grade_snapshot;
      this.clearForm(); this.selectedReview = row; this.reviewScores = scores;
    } catch (e) { this.showError(e, '审核快照无法读取，请刷新重试'); }
  }

  async openChange(row: GradeChange): Promise<void> {
    if (this.busy || this.loading) { return; }
    this.busy = true; this.clearForm();
    try { this.selectedChange = (await HttpClient.get(`/api/grade-changes/${row.id}`)).data as GradeChange; }
    catch (e) { this.showError(e, '成绩更正详情加载失败'); }
    finally { this.busy = false; }
  }

  // 功能：秘书核对成绩快照或更正前后值后明确批准/驳回；自审、越权和旧版本由后端拦截。
  async decide(decision: number): Promise<void> {
    if (this.busy || this.loading || !this.canReview || (this.selectedReview === null && this.selectedChange === null)) { return; }
    if ((decision === 2 && this.reviewComment.trim().length === 0) || this.reviewComment.length > 255) {
      promptAction.showToast({ message: '驳回请填写理由，审核意见最多 255 字' }); return;
    }
    this.busy = true;
    try {
      const answer = await promptAction.showDialog({ title: decision === 1 ? '确认审核通过' : '确认驳回',
        message: decision === 1 ? '通过后成绩将向学生发布或使更正生效，确认已核对？' : '将退回本次申请，确认继续？',
        buttons: [{ text: '取消', color: '#666666' }, { text: '确认', color: '#002FA7' }] });
      if (answer.index !== 1) { return; }
      const path = this.selectedChange !== null ? `/api/grade-changes/${this.selectedChange.id}/decision` :
        `/api/grade-reviews/${this.selectedReview!.id}`;
      const body: Record<string, Object> = { 'decision': decision, 'review_comment': this.reviewComment.trim() };
      await HttpClient.post(path, body);
      this.clearForm(); await this.fetchReviews(); promptAction.showToast({ message: '审核已处理' });
    } catch (e) { this.showError(e, '审核或刷新失败，请刷新待办确认结果后再操作'); }
    finally { this.busy = false; }
  }

  message(e: Object, fallback: string): string { return e instanceof ApiException || e instanceof Error ? e.message : fallback; }
  showError(e: Object, fallback: string): void { promptAction.showToast({ message: this.message(e, fallback) }); }

  @Builder
  ScoreFields() {
    TextInput({ placeholder: '平时分（0–100，可留空保存草稿）', text: this.usualScore }).type(InputType.NUMBER_DECIMAL).enabled(!this.busy)
      .onChange((value: string) => { this.usualScore = value; })
    Select([{ value: '正常考试' }, { value: '缺考（期末分为0）' }, { value: '缓考' }, { value: '免修' }])
      .selected(this.examFlag).value(examFlagText(this.examFlag)).enabled(!this.busy)
      .onSelect((index: number) => { this.examFlag = index; })
    if (this.examFlag !== 1) {
      TextInput({ placeholder: '期末分（0–100，可留空保存草稿）', text: this.finalScore }).type(InputType.NUMBER_DECIMAL).enabled(!this.busy)
        .onChange((value: string) => { this.finalScore = value; })
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('成绩管理').fontSize(24).fontWeight(FontWeight.Bold).width('100%')
        Row({ space: 8 }) {
          if (this.canStudent) { Button('我的成绩').enabled(!this.busy && !this.loading).onClick(() => { this.switchMode('student'); }) }
          if (this.canWrite) { Button('录入成绩').enabled(!this.busy && !this.loading).onClick(() => { this.switchMode('teacher'); }) }
          if (this.canReview) { Button('审核待办').enabled(!this.busy && !this.loading).onClick(() => { this.switchMode('review'); }) }
        }
        if (this.mode !== 'review' && this.semesters.length > 0) {
          Select(this.semesters.map((row: SemesterItem): SelectOption => ({ value: row.semester_name })))
            .selected(this.semesterIndex).value(this.semesters[this.semesterIndex]?.semester_name ?? '选择学期')
            .enabled(!this.busy && !this.loading).width('100%').onSelect((index: number) => { this.changeSemester(index); })
        }
        if (this.mode === 'teacher' && this.classes.length > 0) {
          Select(this.classes.map((row: TeachingClassChoice): SelectOption => ({ value: classChoiceLabel(row) })))
            .selected(this.classIndex).value(this.classIndex >= 0 ? classChoiceLabel(this.classes[this.classIndex]) : '选择教学班')
            .enabled(!this.busy && !this.loading).width('100%').onSelect((index: number) => { this.selectClass(index); })
          Text(`平时/期末权重：${Number(this.classes[this.classIndex]?.usual_weight ?? 0) * 100}% / ${Number(this.classes[this.classIndex]?.final_weight ?? 0) * 100}%（总分由服务端计算）`).fontSize(12)
        }
        Button('刷新').enabled(!this.busy && !this.loading)
          .onClick(() => { if (this.mode === 'teacher' && this.classIndex >= 0) { this.selectClass(this.classIndex); } else { this.switchMode(this.mode); } })
        if (this.loading || this.busy) { Text('正在处理，请稍候…').fontColor('#666666') }
        if (this.error.length > 0) {
          Text(this.error).fontColor('#D9534F')
          Button('重新加载').enabled(!this.busy && !this.loading).onClick(() => { this.initialize(); })
        }
        if (this.mode === 'student') {
          if (!this.canStudent && !this.loading) { Text('当前账号无学生查分权限') }
          if (this.canStudent && this.items.length === 0 && !this.loading) { Text('本学期暂无已发布成绩') }
          ForEach(this.items, (row: GradeItem) => {
            Column({ space: 6 }) {
              Text(row.course_name).fontSize(18).fontWeight(FontWeight.Bold)
              Text(`总分 ${row.total_score ?? '--'} · 学分 ${row.credit} · 绩点 ${row.grade_point ?? '--'}`)
              Text(`平时 ${row.usual_score ?? '--'} / 期末 ${row.final_score ?? '--'} · ${examFlagText(row.exam_flag)}`).fontSize(13)
              Text(`发布：${row.publish_time ? formatDateTime(row.publish_time) : '--'}`).fontSize(12)
            }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
          }, (row: GradeItem) => String(row.id))
        }
        if (this.mode === 'teacher') {
          if (this.classes.length === 0 && !this.loading) { Text('本学期暂无本人任教教学班，请确认课程分配') }
          if (this.classIndex >= 0 && this.roster.length === 0 && !this.loading) { Text('该教学班暂无有效选课学生') }
          ForEach(this.roster.slice((this.pageNo - 1) * this.pageSize, this.pageNo * this.pageSize), (row: ClassGrade) => {
            Column({ space: 8 }) {
              Text(`${row.real_name} · ${row.user_no}`).fontWeight(FontWeight.Bold)
              Text(`平时 ${row.usual_score ?? '--'} / 期末 ${row.final_score ?? '--'} / 总分 ${row.total_score ?? '--'}`)
              Text(`${gradeStateText(row.grade_status)} · ${examFlagText(row.exam_flag ?? 0)}`).fontColor('#002FA7')
              if (row.grade_status !== 1) {
                Button(row.grade_status === 3 ? '申请成绩更正' : '录入 / 编辑').enabled(!this.busy && !this.loading)
                  .onClick(() => { this.editGrade(row); })
              }
            }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
          }, (row: ClassGrade) => String(row.enrollment_id))
          if (this.selectedGrade !== null) {
            Column({ space: 10 }) {
              Text(`${this.selectedGrade.grade_status === 3 ? '申请更正' : '录入成绩'}：${this.selectedGrade.real_name}`).fontSize(18)
              this.ScoreFields()
              if (this.selectedGrade.grade_status === 3) {
                TextArea({ placeholder: '更正理由（必填）', text: this.changeReason }).height(90).maxLength(255).enabled(!this.busy)
                  .onChange((value: string) => { this.changeReason = value; })
              }
              Button(this.selectedGrade.grade_status === 3 ? '提交更正申请' : '保存草稿').enabled(!this.busy && !this.loading)
                .onClick(() => { this.saveGrade(); })
              Button('取消编辑').enabled(!this.busy).onClick(() => { this.clearForm(); })
            }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
          }
          if (this.roster.length > 0) {
            Text('仅已保存的草稿/退回成绩会提交审核。待审和已发布成绩不可直接编辑。').fontSize(12).fontColor('#666666')
            Button('提交本教学班成绩审核').enabled(!this.busy && !this.loading).onClick(() => { this.confirmSubmit(); })
          }
        }
        if (this.mode !== 'review' && this.total > this.pageSize) {
          Row({ space: 10 }) {
            Button('上一页').enabled(this.pageNo > 1 && !this.busy && !this.loading).onClick(() => { this.changePage(this.pageNo - 1); })
            Text(`${this.pageNo} / ${Math.ceil(this.total / this.pageSize)} · 共 ${this.total} 条`)
            Button('下一页').enabled(this.pageNo * this.pageSize < this.total && !this.busy && !this.loading).onClick(() => { this.changePage(this.pageNo + 1); })
          }
        }
        if (this.mode === 'review') {
          Text('成绩发布审核').fontSize(18).fontWeight(FontWeight.Bold)
          if (this.reviews.length === 0 && !this.loading) { Text('暂无待审核成绩批次') }
          ForEach(this.reviews.slice((this.reviewPage - 1) * this.pageSize, this.reviewPage * this.pageSize), (row: GradeReview) => {
            Column({ space: 6 }) {
              Text(`${row.course_name ?? '课程成绩'} · ${row.class_name ?? '教学班'}`).fontWeight(FontWeight.Bold)
              Text(`第 ${row.review_round} 轮 · ${row.submitter_name ?? '教师'} · ${formatDateTime(row.submit_time)}`).fontSize(12)
              Text(row.warning_note ?? '')
              Button('查看成绩快照并审核').enabled(!this.busy).onClick(() => { this.openReview(row); })
            }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
          }, (row: GradeReview) => String(row.id))
          if (this.reviews.length > this.pageSize) {
            Row({ space: 10 }) {
              Button('上一页').enabled(this.reviewPage > 1 && !this.busy).onClick(() => { this.reviewPage--; })
              Text(`${this.reviewPage} / ${Math.ceil(this.reviews.length / this.pageSize)}`)
              Button('下一页').enabled(this.reviewPage * this.pageSize < this.reviews.length && !this.busy).onClick(() => { this.reviewPage++; })
            }
          }
          Text('成绩更正审核').fontSize(18).fontWeight(FontWeight.Bold)
          if (this.changes.length === 0 && !this.loading) { Text('暂无待审核更正申请') }
          ForEach(this.changes.slice((this.changeReviewPage - 1) * this.pageSize, this.changeReviewPage * this.pageSize), (row: GradeChange) => {
            Column({ space: 6 }) {
              Text(`${row.course_name} · ${row.class_name}`).fontWeight(FontWeight.Bold)
              Text(`${row.student_name} · ${row.user_no} · 申请人 ${row.applicant_name}`)
              Text(row.change_reason)
              Button('查看更正详情并审核').enabled(!this.busy).onClick(() => { this.openChange(row); })
            }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
          }, (row: GradeChange) => String(row.id))
          if (this.changes.length > this.pageSize) {
            Row({ space: 10 }) {
              Button('上一页').enabled(this.changeReviewPage > 1 && !this.busy).onClick(() => { this.changeReviewPage--; })
              Text(`${this.changeReviewPage} / ${Math.ceil(this.changes.length / this.pageSize)}`)
              Button('下一页').enabled(this.changeReviewPage * this.pageSize < this.changes.length && !this.busy).onClick(() => { this.changeReviewPage++; })
            }
          }
          if (this.selectedReview !== null || this.selectedChange !== null) {
            Column({ space: 10 }) {
              Text('核对审核内容').fontSize(18).fontWeight(FontWeight.Bold)
              if (this.selectedReview !== null) {
                Text(`${this.selectedReview.course_name ?? '课程成绩'} · ${this.selectedReview.class_name ?? '教学班'} · 共 ${this.reviewScores.length} 条`)
                ForEach(this.reviewScores, (row: ReviewScore) => {
                  Text(`${row.real_name ?? '学生'} ${row.user_no ?? ''}：平时 ${row.usual_score ?? '--'} / 期末 ${row.final_score ?? '--'} / 总分 ${row.total_score ?? '--'} · ${examFlagText(row.exam_flag)}`).fontSize(13).width('100%')
                }, (row: ReviewScore) => String(row.id))
              }
              if (this.selectedChange !== null) {
                Text(`${this.selectedChange.course_name} · ${this.selectedChange.student_name} ${this.selectedChange.user_no}`)
                Text(`更正前：平时 ${this.selectedChange.before_value.usual_score ?? '--'} / 期末 ${this.selectedChange.before_value.final_score ?? '--'} / 总分 ${this.selectedChange.before_value.total_score ?? '--'} · ${examFlagText(this.selectedChange.before_value.exam_flag ?? 0)}`)
                Text(`更正后：平时 ${this.selectedChange.after_value.usual_score ?? '--'} / 期末 ${this.selectedChange.after_value.final_score ?? '--'} / 总分 ${this.selectedChange.after_value.total_score ?? '--'} · ${examFlagText(this.selectedChange.after_value.exam_flag ?? 0)}`)
                Text(`理由：${this.selectedChange.change_reason}`)
              }
              TextArea({ placeholder: '审核意见（驳回必填）', text: this.reviewComment }).height(90).maxLength(255).enabled(!this.busy)
                .onChange((value: string) => { this.reviewComment = value; })
              Row({ space: 10 }) {
                Button('审核通过').enabled(!this.busy).onClick(() => { this.decide(1); })
                Button('驳回').enabled(!this.busy).onClick(() => { this.decide(2); })
              }
              Button('关闭详情').enabled(!this.busy).onClick(() => { this.clearForm(); })
            }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
          }
        }
      }.padding(20).width('100%')
    }.width('100%').height('100%').backgroundColor('#F2F4F8')
  }
}
