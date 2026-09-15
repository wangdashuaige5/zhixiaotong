import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { formatDateTime, leaveStatusText } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { LeaveItem } from '../model/Models';
import { LeaveTimeDialog } from '../components/LeaveTimeDialog';

@Entry
@Component
struct LeavePage {
  @State items: LeaveItem[] = [];
  @State leaveType: string = '事假';
  @State reason: string = '';
  @State loading: boolean = true;
  @State error: string = '';
  @State startDate: Date = new Date(Date.now() + 86400000);
  @State startHour: number = 8;
  @State startMinute: number = 0;
  @State endDate: Date = new Date(Date.now() + 86400000);
  @State endHour: number = 18;
  @State endMinute: number = 0;

  @State submitting: boolean = false;
  private timeController?: CustomDialogController;

  // 功能：开始/结束两行菜单分别打开日期时间表单。
  openTimeForm(isStart: boolean): void {
    let date = isStart ? this.startDate : this.endDate;
    let selected = new Date(date.getFullYear(), date.getMonth(), date.getDate(),
      isStart ? this.startHour : this.endHour, isStart ? this.startMinute : this.endMinute);
    this.timeController = new CustomDialogController({
      builder: LeaveTimeDialog({ title: isStart ? '选择开始时间' : '选择结束时间',
        initialValue: selected, onConfirm: (value: Date) => {
          if (isStart) {
            this.startDate = value;
            this.startHour = value.getHours();
            this.startMinute = value.getMinutes();
          } else {
            this.endDate = value;
            this.endHour = value.getHours();
            this.endMinute = value.getMinutes();
          }
        } }),
      autoCancel: false
    });
    this.timeController.open();
  }

  displayTime(isStart: boolean): string {
    return this.buildIso(isStart ? this.startDate : this.endDate,
      isStart ? this.startHour : this.endHour, isStart ? this.startMinute : this.endMinute)
      .replace('T', ' ').substring(0, 16);
  }

  aboutToDisappear(): void { this.timeController?.close(); }

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      let page = await CampusApi.myLeaves();
      this.items = page.items;
    } catch (e) {
      let message = '请假记录加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  buildIso(date: Date, hour: number, minute: number): string {
    return `${date.getFullYear()}-${this.pad(date.getMonth() + 1)}-${this.pad(date.getDate())}T${this.pad(hour)}:${this.pad(minute)}:00+08:00`;
  }

  async submit(): Promise<void> {
    if (this.submitting) { return; }
    if (this.leaveType.trim().length === 0) {
      promptAction.showToast({ message: '请填写请假类型' });
      return;
    }
    if (new Date(this.buildIso(this.endDate, this.endHour, this.endMinute)).getTime() <=
      new Date(this.buildIso(this.startDate, this.startHour, this.startMinute)).getTime()) {
      promptAction.showToast({ message: '结束时间必须晚于开始时间' });
      return;
    }
    if (this.reason.trim().length === 0) {
      promptAction.showToast({ message: '请填写请假原因' });
      return;
    }
    this.submitting = true;
    try {
      let body: Record<string, Object> = {
        'leave_type': this.leaveType,
        'start_time': this.buildIso(this.startDate, this.startHour, this.startMinute),
        'end_time': this.buildIso(this.endDate, this.endHour, this.endMinute),
        'leave_reason': this.reason.trim(),
        'action': 'submit',
        'file_ids': []
      };
      await CampusApi.createLeave(body);
      promptAction.showToast({ message: '请假申请已提交' });
      this.reason = '';
      await this.loadData();
    } catch (e) {
      this.showError(e, '请假提交失败');
    } finally {
      this.submitting = false;
    }
  }

  async withdraw(id: string): Promise<void> {
    try {
      await CampusApi.withdrawLeave(id);
      promptAction.showToast({ message: '已撤回' });
      await this.loadData();
    } catch (e) {
      this.showError(e, '撤回失败');
    }
  }

  async close(id: string): Promise<void> {
    try {
      await CampusApi.closeLeave(id);
      promptAction.showToast({ message: '销假成功' });
      await this.loadData();
    } catch (e) {
      this.showError(e, '销假失败');
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
      Column({ space: 12 }) {
        Text('请假与销假')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Text('类型').width(50)
            TextInput({ placeholder: '事假', text: this.leaveType })
              .layoutWeight(1)
              .height(40)
              .onChange((value: string) => {
                this.leaveType = value;
              })
          }
          .width('100%')

          // 功能：收起常驻日期滚轮，展示两行可点击菜单。
          Row({ space: 8 }) {
            Text('开始时间').width(76).fontSize(15)
            Text(this.displayTime(true)).layoutWeight(1).fontSize(14).textAlign(TextAlign.End)
            Text('›').fontSize(26).fontColor('#666666')
          }.width('100%').height(58).padding({ left: 10, right: 10 })
            .backgroundColor('#F5F7FB').borderRadius(8)
            .onClick(() => this.openTimeForm(true)).accessibilityText('选择请假开始时间')
          Row({ space: 8 }) {
            Text('结束时间').width(76).fontSize(15)
            Text(this.displayTime(false)).layoutWeight(1).fontSize(14).textAlign(TextAlign.End)
            Text('›').fontSize(26).fontColor('#666666')
          }.width('100%').height(58).padding({ left: 10, right: 10 })
            .backgroundColor('#F5F7FB').borderRadius(8)
            .onClick(() => this.openTimeForm(false)).accessibilityText('选择请假结束时间')

          TextInput({ placeholder: '请假原因', text: this.reason })
            .height(72)
            .onChange((value: string) => {
              this.reason = value;
            })
          Button(this.submitting ? '提交中…' : '提交请假申请')
            .enabled(!this.submitting)
            .width('100%')
            .height(42)
            .onClick(() => {
              this.submit();
            })
        }
        .padding(14)
        .width('100%')
        .borderRadius(12)
        .backgroundColor('#FFFFFF')

        Text('我的请假')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        if (this.error.length > 0) {
          Column({ space: 10 }) {
            Text(this.error)
              .fontSize(14)
              .fontColor('#D9534F')
            Button('重新加载')
              .height(36)
              .onClick(() => {
                this.loadData();
              })
          }
          .padding(12)
          .width('100%')
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
        } else if (this.loading) {
          Text('加载中...').fontSize(14).fontColor('#666666')
        } else if (this.items.length === 0) {
          Text('暂无请假记录').fontSize(14).fontColor('#999999')
        } else {
          ForEach(this.items, (item: LeaveItem) => {
            Column({ space: 6 }) {
              Row() {
                Text(item.leave_type)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                Text(leaveStatusText(item.leave_status))
                  .fontSize(13)
                  .fontColor('#002FA7')
              }
              .width('100%')
              Text(`${formatDateTime(item.start_time)} 至 ${formatDateTime(item.end_time)} · ${item.leave_days}天`)
                .fontSize(13)
                .fontColor('#666666')
              Text(item.leave_reason)
                .fontSize(13)
                .fontColor('#666666')
              if (item.leave_status === 1 || item.leave_status === 2) {
                Button('撤回')
                  .height(30)
                  .fontSize(12)
                  .onClick(() => {
                    this.withdraw(item.id);
                  })
              }
              if (item.leave_status === 3) {
                Button('销假')
                  .height(30)
                  .fontSize(12)
                  .onClick(() => {
                    this.close(item.id);
                  })
              }
            }
            .padding(12)
            .width('100%')
            .borderRadius(10)
            .backgroundColor('#FFFFFF')
          }, (item: LeaveItem) => item.id)
        }
      }
      .padding(20)
      .width('100%')
      .backgroundColor('#F2F4F8')
      .onAppear(() => {
        this.loadData();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F4F8')
    .align(Alignment.Top)
  }
}
