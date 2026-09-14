import { promptAction } from '@kit.ArkUI';
import { ApiException, HttpClient } from '../common/Http';
import { CampusApi } from '../services/Api';

@Entry
@Component
struct AttendancePage {
  @State taskId: string = '';
  @State signCode: string = '';
  @State deviceId: string = '6';
  @State timetableId: string = '';
  @State classDate: string = '';
  @State startTime: string = '';
  @State endTime: string = '';
  @State isStudent: boolean = false;
  @State isTeacher: boolean = false;
  @State loading: boolean = true;

  async loadRole(): Promise<void> {
    this.loading = true;
    try {
      let me = await CampusApi.me();
      let roleCodes = me.roles.map((role) => role.role_code);
      this.isStudent = roleCodes.indexOf('STUDENT') >= 0;
      this.isTeacher = roleCodes.indexOf('TEACHER') >= 0;
    } catch (e) {
      this.showError(e, '身份加载失败');
    } finally {
      this.loading = false;
    }
  }

  async studentSign(): Promise<void> {
    if (this.taskId.length === 0 || this.signCode.length === 0 || this.deviceId.length === 0) {
      promptAction.showToast({ message: '请填写签到任务、签到码和设备ID' });
      return;
    }
    try {
      let body: Record<string, string> = {
        'sign_code': this.signCode,
        'device_id': this.deviceId
      };
      await HttpClient.post(`/api/attendance/tasks/${this.taskId}/sign`, body);
      promptAction.showToast({ message: '签到成功' });
    } catch (e) {
      this.showError(e, '签到失败');
    }
  }

  async createTask(): Promise<void> {
    if (this.timetableId.length === 0 || this.classDate.length === 0 ||
      this.startTime.length === 0 || this.endTime.length === 0) {
      promptAction.showToast({ message: '请填写排课、日期和签到时间窗' });
      return;
    }
    try {
      let body: Record<string, string> = {
        'timetable_id': this.timetableId,
        'class_date': this.classDate,
        'start_time': this.startTime,
        'end_time': this.endTime
      };
      let result = await HttpClient.post('/api/attendance/tasks', body);
      let data = result.data as Record<string, Object>;
      promptAction.showToast({ message: `签到任务已创建，签到码：${data['sign_code'] ?? ''}` });
    } catch (e) {
      this.showError(e, '创建签到失败');
    }
  }

  showError(e: Object, defaultMessage: string): void {
    let message = defaultMessage;
    if (e instanceof ApiException) {
      message = e.message;
    }
    promptAction.showToast({ message: message });
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('课堂考勤')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        if (this.loading) {
          Text('加载中...').fontSize(14).fontColor('#666666')
        } else if (this.isStudent) {
          Column({ space: 8 }) {
            Text('学生签到')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            TextInput({ placeholder: '签到任务ID', text: this.taskId })
              .height(40)
              .onChange((value: string) => {
                this.taskId = value;
              })
            TextInput({ placeholder: '签到码', text: this.signCode })
              .height(40)
              .onChange((value: string) => {
                this.signCode = value;
              })
            TextInput({ placeholder: '设备ID', text: this.deviceId })
              .height(40)
              .onChange((value: string) => {
                this.deviceId = value;
              })
            Button('提交签到')
              .width('100%')
              .height(40)
              .onClick(() => {
                this.studentSign();
              })
          }
          .padding(14)
          .width('100%')
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
        } else if (this.isTeacher) {
          Column({ space: 8 }) {
            Text('教师发起签到')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            TextInput({ placeholder: '排课ID', text: this.timetableId })
              .height(40)
              .onChange((value: string) => {
                this.timetableId = value;
              })
            TextInput({ placeholder: '日期 2026-09-11', text: this.classDate })
              .height(40)
              .onChange((value: string) => {
                this.classDate = value;
              })
            TextInput({ placeholder: '开始 2026-09-11T08:00:00+08:00', text: this.startTime })
              .height(40)
              .onChange((value: string) => {
                this.startTime = value;
              })
            TextInput({ placeholder: '结束 2026-09-11T09:00:00+08:00', text: this.endTime })
              .height(40)
              .onChange((value: string) => {
                this.endTime = value;
              })
            Button('发起签到')
              .width('100%')
              .height(40)
              .onClick(() => {
                this.createTask();
              })
          }
          .padding(14)
          .width('100%')
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
        } else {
          Text('当前账号无课堂考勤操作权限')
            .fontSize(14)
            .fontColor('#999999')
        }
      }
      .padding(20)
      .width('100%')
      .backgroundColor('#F2F4F8')
      .onAppear(() => {
        this.loadRole();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F4F8')
    .align(Alignment.Top)
  }
}
