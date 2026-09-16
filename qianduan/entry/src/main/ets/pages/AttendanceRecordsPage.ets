import { router, promptAction } from '@kit.ArkUI';
import { ApiException, HttpClient } from '../common/Http';
import { formatDateTime } from '../common/Utils';

interface AttendanceRoute { task_id?: string; }
interface AttendanceRecordRow {
  id: string;
  task_id: string;
  student_id: string;
  real_name?: string;
  user_no?: string;
  sign_status: number;
  sign_time?: string;
}

@Entry
@Component
struct AttendanceRecordsPage {
  @State taskId: string = '';
  @State items: AttendanceRecordRow[] = [];
  @State pageNo: number = 1;
  @State loading: boolean = false;
  @State error: string = '';
  private readonly pageSize: number = 20;

  aboutToAppear(): void {
    const params = router.getParams() as AttendanceRoute;
    const id = params?.task_id;
    if (typeof id !== 'string' || !/^[1-9]\d*$/.test(id)) {
      this.error = '缺少有效签到任务，请返回课堂考勤，从已发布任务进入记录页'; return;
    }
    this.taskId = id;
    this.loadRecords();
  }

  // 功能：仅展示服务端已存在的签到记录，刷新不写业务数据，不把记录缺失误判为缺勤。
  async loadRecords(): Promise<void> {
    if (this.loading || this.taskId.length === 0) { return; }
    this.loading = true; this.error = '';
    try {
      this.items = (await HttpClient.get(`/api/attendance/tasks/${this.taskId}/records`)).data as AttendanceRecordRow[];
      this.pageNo = Math.max(1, Math.min(this.pageNo, Math.ceil(this.items.length / this.pageSize)));
    } catch (e) {
      this.error = e instanceof ApiException || e instanceof Error ? e.message : '签到记录加载失败';
      promptAction.showToast({ message: this.error });
    } finally { this.loading = false; }
  }

  stateText(state: number): string { return ['待签', '已签到', '迟到', '请假', '缺勤'][state] ?? '未知状态'; }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('签到记录').fontSize(24).fontWeight(FontWeight.Bold).width('100%')
        Text('以下为本任务已有记录。系统未生成记录的学生不会出现在这里，本页不是完整缺勤统计。').fontSize(13).fontColor('#666666')
        Button(this.loading ? '正在刷新…' : '刷新签到记录').enabled(!this.loading && this.taskId.length > 0)
          .onClick(() => { this.loadRecords(); })
        if (this.error.length > 0) { Text(this.error).fontColor('#D9534F') }
        if (!this.loading && this.error.length === 0 && this.items.length === 0) { Text('暂时没有签到记录') }
        if (this.items.length > 0) { Text(`已有记录 ${this.items.length} 条`).width('100%') }
        ForEach(this.items.slice((this.pageNo - 1) * this.pageSize, this.pageNo * this.pageSize), (row: AttendanceRecordRow) => {
          Column({ space: 8 }) {
            Text(`${row.real_name ?? '学生'} ${row.user_no ?? ''}`).fontSize(18).fontWeight(FontWeight.Bold)
            Text(this.stateText(row.sign_status)).fontColor(row.sign_status === 2 || row.sign_status === 4 ? '#D9534F' : '#002FA7')
            Text(`签到时间：${row.sign_time ? formatDateTime(row.sign_time) : '尚无签到时间'}`).fontSize(13)
          }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
        }, (row: AttendanceRecordRow) => String(row.id))
        if (this.items.length > this.pageSize) {
          Row({ space: 10 }) {
            Button('上一页').enabled(!this.loading && this.pageNo > 1).onClick(() => { this.pageNo--; })
            Text(`${this.pageNo} / ${Math.ceil(this.items.length / this.pageSize)}`)
            Button('下一页').enabled(!this.loading && this.pageNo * this.pageSize < this.items.length).onClick(() => { this.pageNo++; })
          }
        }
      }.padding(20).width('100%')
    }.width('100%').height('100%').backgroundColor('#F2F4F8')
  }
}
