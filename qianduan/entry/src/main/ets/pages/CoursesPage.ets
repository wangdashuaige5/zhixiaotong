import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { enrollStatusText, randomRequestKey } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { CourseOption, EnrollmentItem } from '../model/Models';

interface EnrollmentBatch {
  id: string;
  batch_name: string;
  batch_status: number;
  start_time: string;
  end_time: string;
}
class BatchOption {
  value: string;
  constructor(value: string) { this.value = value; }
}

@Entry
@Component
struct CoursesPage {
  @State batches: EnrollmentBatch[] = [];
  @State batchOptions: BatchOption[] = [];
  @State selectedBatchIndex: number = 0;
  @State batchId: string = '';
  @State enrollments: EnrollmentItem[] = [];
  @State options: CourseOption[] = [];
  @State keyword: string = '';
  @State optionsPage: number = 1;
  @State optionsTotal: number = 0;
  @State recordsPage: number = 1;
  @State recordsTotal: number = 0;
  @State loading: boolean = false;
  @State optionsLoading: boolean = false;
  @State busy: boolean = false;
  @State error: string = '';
  @State optionsError: string = '';
  private requestKeys: Map<string, string> = new Map<string, string>();

  aboutToAppear(): void { this.loadData(); }

  // 功能：只显示当前账号范围内、处于开放时间的真实批次，不再写死批次ID。
  isOpen(batch: EnrollmentBatch): boolean {
    const now = Date.now();
    return batch.batch_status === 1 && Date.parse(batch.start_time) <= now && now < Date.parse(batch.end_time);
  }

  async loadData(): Promise<void> {
    if (this.loading || this.busy || this.optionsLoading) { return; }
    this.loading = true;
    this.error = '';
    try {
      const all = await CampusApi.enrollmentBatches() as EnrollmentBatch[];
      this.batches = all.filter((batch: EnrollmentBatch) => this.isOpen(batch));
      this.batchOptions = this.batches.map((batch: EnrollmentBatch) => new BatchOption(batch.batch_name));
      const kept = this.batches.findIndex((batch: EnrollmentBatch) => batch.id === this.batchId);
      this.selectedBatchIndex = kept >= 0 ? kept : 0;
      this.batchId = this.batches.length > 0 ? this.batches[this.selectedBatchIndex].id : '';
      this.optionsPage = 1;
      await this.loadMyCourses();
      await this.loadOptions();
    } catch (e) {
      this.error = e instanceof ApiException ? e.message : '选课数据加载失败';
      this.options = [];
      this.enrollments = [];
    } finally { this.loading = false; }
  }

  async loadMyCourses(): Promise<void> {
    const page = await CampusApi.myEnrollments(undefined, this.recordsPage);
    this.enrollments = page.items;
    this.recordsTotal = Number(page.total);
  }

  async loadOptions(): Promise<void> {
    this.options = [];
    this.optionsTotal = 0;
    this.optionsError = '';
    if (this.batchId.length === 0) { return; }
    this.optionsLoading = true;
    try {
      const page = await CampusApi.enrollmentOptions(this.batchId, this.keyword.trim(), this.optionsPage);
      this.options = page.items;
      this.optionsTotal = Number(page.total);
    } catch (e) {
      this.optionsError = e instanceof ApiException ? e.message : '可选课程加载失败';
    } finally { this.optionsLoading = false; }
  }

  async selectBatch(index: number): Promise<void> {
    if (this.loading || this.busy || this.optionsLoading || index < 0 || index >= this.batches.length) { return; }
    this.selectedBatchIndex = index;
    this.batchId = this.batches[index].id;
    this.optionsPage = 1;
    await this.loadOptions();
  }

  async changeOptionsPage(offset: number): Promise<void> {
    const page = this.optionsPage + offset;
    if (this.loading || this.busy || this.optionsLoading || page < 1 || page > Math.max(1, Math.ceil(this.optionsTotal / 20))) { return; }
    this.optionsPage = page;
    await this.loadOptions();
  }

  async changeRecordsPage(offset: number): Promise<void> {
    const page = this.recordsPage + offset;
    if (this.loading || this.busy || this.optionsLoading || page < 1 || page > Math.max(1, Math.ceil(this.recordsTotal / 20))) { return; }
    this.busy = true;
    this.recordsPage = page;
    try { await this.loadMyCourses(); }
    catch (e) { this.enrollments = []; this.showError(e, '记录加载失败'); }
    finally { this.busy = false; }
  }

  async choose(item: CourseOption): Promise<void> {
    if (this.loading || this.busy || this.optionsLoading) { return; }
    this.busy = true;
    // 网络结果不确定时重用幂等键，避免点重试时发出一笔不同的选课申请。
    let key = this.requestKeys.get(item.id);
    if (key === undefined) { key = randomRequestKey('enroll'); this.requestKeys.set(item.id, key); }
    try {
      const result = await CampusApi.submitEnrollment(item.id, key);
      this.requestKeys.delete(item.id);
      const data = result as Record<string, Object>;
      promptAction.showToast({ message: `提交成功：${data['result_note'] ?? ''}` });
      this.recordsPage = 1;
      await this.loadMyCourses();
      await this.loadOptions();
    } catch (e) { this.showError(e, '选课提交失败'); }
    finally { this.busy = false; }
  }

  async confirmDrop(item: EnrollmentItem): Promise<void> {
    if (this.loading || this.busy || this.optionsLoading) { return; }
    this.busy = true;
    try {
      const answer = await promptAction.showDialog({ title: '确认退选', message: `确定退选「${item.course_name} · ${item.class_name}」吗？`,
        buttons: [{ text: '取消', color: '#666666' }, { text: '确认退选', color: '#D9534F' }] });
      if (answer.index !== 1) { return; }
      await CampusApi.dropEnrollment(item.id);
      promptAction.showToast({ message: '退选已提交' });
      this.recordsPage = 1;
      await this.loadMyCourses();
      await this.loadOptions();
    } catch (e) { this.showError(e, '退选失败'); }
    finally { this.busy = false; }
  }

  showError(e: Object, fallback: string): void {
    promptAction.showToast({ message: e instanceof ApiException ? e.message : fallback });
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('选课与我的课程').fontSize(22).fontWeight(FontWeight.Bold).width('100%')
        Button('刷新批次与课程').enabled(!this.loading && !this.busy && !this.optionsLoading).onClick(() => this.loadData())
        if (this.error.length > 0) { Text(this.error).fontColor('#D9534F') }
        if (this.loading) { LoadingProgress().width(36).height(36) }
        if (this.batches.length > 0) {
          Text('当前开放选课批次').fontSize(16).width('100%')
          Select(this.batchOptions).selected(this.selectedBatchIndex)
            .value(this.batches[this.selectedBatchIndex].batch_name).width('100%')
            .enabled(!this.loading && !this.busy && !this.optionsLoading)
            .onSelect((index: number) => this.selectBatch(index))
          Row({ space: 8 }) {
            TextInput({ placeholder: '课程名称', text: this.keyword }).layoutWeight(1)
              .enabled(!this.loading && !this.busy && !this.optionsLoading).onChange((value: string) => { this.keyword = value; })
            Button('查询').enabled(!this.loading && !this.busy && !this.optionsLoading)
              .onClick(() => { this.optionsPage = 1; this.loadOptions(); })
          }.width('100%')
          if (this.optionsError.length > 0) { Text(this.optionsError).fontColor('#D9534F') }
          if (this.optionsLoading) { Text('课程加载中…').fontColor('#666666') }
          else if (this.options.length === 0) { Text('该批次没有符合条件的课程').fontColor('#666666') }
          ForEach(this.options, (item: CourseOption) => {
            Row({ space: 10 }) {
              Column({ space: 4 }) {
                Text(item.course_name).fontSize(16).fontWeight(FontWeight.Medium)
                Text(`${item.class_name} · ${item.teacher_name}`).fontSize(13)
                Text(`已选 ${item.enrolled_count}/${item.capacity}`).fontSize(12).fontColor('#666666')
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Button('选课').enabled(!this.loading && !this.busy && !this.optionsLoading).onClick(() => this.choose(item))
            }.padding(12).width('100%').borderRadius(10).backgroundColor('#FFFFFF')
          }, (item: CourseOption) => item.id)
          Row({ space: 12 }) {
            Button('上一页').enabled(!this.loading && !this.busy && !this.optionsLoading && this.optionsPage > 1)
              .onClick(() => this.changeOptionsPage(-1))
            Text(`${this.optionsPage} / ${Math.max(1, Math.ceil(this.optionsTotal / 20))}`)
            Button('下一页').enabled(!this.loading && !this.busy && !this.optionsLoading && this.optionsPage * 20 < this.optionsTotal)
              .onClick(() => this.changeOptionsPage(1))
          }
        } else if (!this.loading && !this.error) {
          Text('当前没有面向你的开放选课批次，请等待开放或联系管理员配置。').fontColor('#666666')
        }
        Text('我的选课').fontSize(18).fontWeight(FontWeight.Bold).width('100%')
        if (!this.loading && this.enrollments.length === 0) { Text('暂无选课记录，选课成功后才会显示课表并获得对应课堂签到资格。').fontColor('#666666') }
        ForEach(this.enrollments, (item: EnrollmentItem) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(item.course_name).fontSize(16)
              Text(`${item.class_name} · ${enrollStatusText(item.enroll_status)}`).fontSize(13)
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            if (item.enroll_status === 1) {
              Button('退选').enabled(!this.loading && !this.busy && !this.optionsLoading).onClick(() => this.confirmDrop(item))
            }
          }.padding(12).width('100%').borderRadius(10).backgroundColor('#FFFFFF')
        }, (item: EnrollmentItem) => item.id)
        Row({ space: 12 }) {
          Button('上一页').enabled(!this.loading && !this.busy && !this.optionsLoading && this.recordsPage > 1)
            .onClick(() => this.changeRecordsPage(-1))
          Text(`${this.recordsPage} / ${Math.max(1, Math.ceil(this.recordsTotal / 20))}`)
          Button('下一页').enabled(!this.loading && !this.busy && !this.optionsLoading && this.recordsPage * 20 < this.recordsTotal)
            .onClick(() => this.changeRecordsPage(1))
        }
      }.padding(20).width('100%')
    }.width('100%').height('100%').backgroundColor('#F2F4F8')
  }
}
