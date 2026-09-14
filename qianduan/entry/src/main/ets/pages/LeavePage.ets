import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { formatDateTime, leaveStatusText } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { LeaveItem } from '../model/Models';

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
    if (this.reason.trim().length === 0) {
      promptAction.showToast({ message: '请填写请假原因' });
      return;
    }
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

          Text('开始日期')
            .fontSize(13)
            .fontColor('#1F1F1F')
            .width('100%')
          DatePicker({
            start: new Date('2026-09-01'),
            end: new Date('2027-01-11'),
            selected: this.startDate
          })
            .onChange((value) => {
              let y = value.year === undefined ? this.startDate.getFullYear() : value.year;
              let m = value.month === undefined ? this.startDate.getMonth() : value.month;
              let d = value.day === undefined ? this.startDate.getDate() : value.day;
              this.startDate = new Date(y, m, d);
            })

          Text('开始时间')
            .fontSize(13)
            .fontColor('#1F1F1F')
            .width('100%')
          TimePicker({ selected: this.startDate })
            .onChange((value) => {
              this.startHour = value.hour === undefined ? this.startHour : value.hour;
              this.startMinute = value.minute === undefined ? this.startMinute : value.minute;
            })

          Text('结束日期')
            .fontSize(13)
            .fontColor('#1F1F1F')
            .width('100%')
          DatePicker({
            start: new Date('2026-09-01'),
            end: new Date('2027-01-11'),
            selected: this.endDate
          })
            .onChange((value) => {
              let y = value.year === undefined ? this.endDate.getFullYear() : value.year;
              let m = value.month === undefined ? this.endDate.getMonth() : value.month;
              let d = value.day === undefined ? this.endDate.getDate() : value.day;
              this.endDate = new Date(y, m, d);
            })

          Text('结束时间')
            .fontSize(13)
            .fontColor('#1F1F1F')
            .width('100%')
          TimePicker({ selected: this.endDate })
            .onChange((value) => {
              this.endHour = value.hour === undefined ? this.endHour : value.hour;
              this.endMinute = value.minute === undefined ? this.endMinute : value.minute;
            })

          Text(`开始：${this.buildIso(this.startDate, this.startHour, this.startMinute)}`)
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
          Text(`结束：${this.buildIso(this.endDate, this.endHour, this.endMinute)}`)
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')

          TextInput({ placeholder: '请假原因', text: this.reason })
            .height(72)
            .onChange((value: string) => {
              this.reason = value;
            })
          Button('提交请假申请')
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
