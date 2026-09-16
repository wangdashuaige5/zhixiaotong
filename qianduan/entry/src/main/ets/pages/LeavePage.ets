import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { formatDateTime, leaveStatusText } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { LeaveItem, LeaveApprovalItem } from '../model/Models';
import { LeaveTimeDialog } from '../components/LeaveTimeDialog';
import { PaginationBar } from '../components/PaginationBar';

@Entry
@Component
struct LeavePage {
  @State items: LeaveItem[] = [];
  @State leaveType: string = '事假';
  @State reason: string = '';
  @State loading: boolean = false;
  @State error: string = '';
  @State pageNo: number = 1;
  @State total: number = 0;
  @State actionBusy: boolean = false;
  @State editingId: string = '';
  @State editingStatus: number = 0;
  @State returnOpinion: string = '';
  @State startDate: Date = new Date(Date.now() + 86400000);
  @State startHour: number = 8;
  @State startMinute: number = 0;
  @State endDate: Date = new Date(Date.now() + 86400000);
  @State endHour: number = 18;
  @State endMinute: number = 0;

  @State submitting: boolean = false;
  private timeController?: CustomDialogController;
  private scroller: Scroller = new Scroller();

  // 功能：开始/结束两行菜单分别打开日期时间表单。
  openTimeForm(isStart: boolean): void {
    if (this.submitting || this.actionBusy) { return; }
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

  // 编辑前重新读取服务端状态，避免对已进入审批的旧列表记录继续修改。
  async editLeave(id: string): Promise<void> {
    if (this.loading || this.submitting || this.actionBusy) { return; }
    this.actionBusy = true;
    try {
      let item = await CampusApi.leaveDetail(id);
      if (item.leave_status !== 0 && item.leave_status !== 5) {
        promptAction.showToast({ message: '申请状态已变化，仅草稿和退回申请可修改' });
        await this.loadData(); return;
      }
      let start = new Date(item.start_time); let end = new Date(item.end_time);
      if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
        promptAction.showToast({ message: '申请时间格式异常，请联系管理员' }); return;
      }
      this.editingId = item.id; this.editingStatus = item.leave_status;
      this.leaveType = item.leave_type; this.reason = item.leave_reason;
      this.startDate = start; this.startHour = start.getHours(); this.startMinute = start.getMinutes();
      this.endDate = end; this.endHour = end.getHours(); this.endMinute = end.getMinutes();
      this.returnOpinion = (item.approvals ?? []).filter((approval: LeaveApprovalItem) =>
        approval.apply_round === item.apply_round && approval.decision === 3)
        .map((approval: LeaveApprovalItem) => approval.opinion ?? '请按审批要求修改后重提').join('；');
      this.scroller.scrollEdge(Edge.Top);
    } catch (e) { this.showError(e, '申请详情加载失败'); }
    finally { this.actionBusy = false; }
  }

  requestEdit(id: string): void {
    if (this.reason.trim().length === 0 && this.editingId.length === 0) { this.editLeave(id); return; }
    this.getUIContext().showAlertDialog({
      title: '切换编辑申请', message: '表单里未保存的内容将被替换，是否继续？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '继续编辑', action: () => { this.editLeave(id); } }
    });
  }

  resetForm(): void {
    this.editingId = ''; this.editingStatus = 0; this.returnOpinion = '';
    this.leaveType = '事假'; this.reason = '';
    this.startDate = new Date(Date.now() + 86400000); this.endDate = new Date(Date.now() + 86400000);
    this.startHour = 8; this.startMinute = 0; this.endHour = 18; this.endMinute = 0;
  }

  // 创建申请后回到第一页；撤回/销假保留当前页，并防止旧数据混入。
  async loadData(pageNo: number = this.pageNo): Promise<void> {
    if (this.loading) { return; }
    this.loading = true;
    this.pageNo = pageNo; this.items = []; this.total = 0;
    this.error = '';
    try {
      let page = await CampusApi.myLeaves(pageNo);
      this.items = page.items;
      this.total = Number(page.total);
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

  async submit(action: string = 'submit'): Promise<void> {
    if (this.submitting || this.actionBusy || this.loading) { return; }
    if (action !== 'submit' && action !== 'draft') { return; }
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
    let duration = new Date(this.buildIso(this.endDate, this.endHour, this.endMinute)).getTime() -
      new Date(this.buildIso(this.startDate, this.startHour, this.startMinute)).getTime();
    if (this.leaveType.trim().length > 32 || this.reason.trim().length > 10000 || duration > 365 * 86400000) {
      promptAction.showToast({ message: '类型最多 32 字、原因最多 10000 字，请假不超过 365 天' }); return;
    }
    this.submitting = true;
    try {
      let body: Record<string, Object> = {
        'leave_type': this.leaveType.trim(),
        'start_time': this.buildIso(this.startDate, this.startHour, this.startMinute),
        'end_time': this.buildIso(this.endDate, this.endHour, this.endMinute),
        'leave_reason': this.reason.trim(),
        'action': action,
        'file_ids': []
      };
      let saved = this.editingId.length > 0 ? await CampusApi.updateLeave(this.editingId, body) : await CampusApi.createLeave(body);
      if (action === 'draft') {
        this.editingId = saved.id; this.editingStatus = saved.leave_status;
        promptAction.showToast({ message: '修改已保存，尚未提交审批' });
      } else {
        promptAction.showToast({ message: this.editingId.length > 0 ? '申请已重新提交审批' : '请假申请已提交' });
        this.resetForm();
      }
      await this.loadData(1);
    } catch (e) {
      this.showError(e, '请假提交失败');
    } finally {
      this.submitting = false;
    }
  }

  async withdraw(id: string): Promise<void> {
    if (this.actionBusy || this.submitting || this.loading) { return; }
    this.actionBusy = true;
    try {
      await CampusApi.withdrawLeave(id);
      promptAction.showToast({ message: '已撤回' });
      await this.loadData();
    } catch (e) {
      this.showError(e, '撤回失败');
    } finally { this.actionBusy = false; }
  }

  async close(id: string): Promise<void> {
    if (this.actionBusy || this.submitting || this.loading) { return; }
    this.actionBusy = true;
    try {
      await CampusApi.closeLeave(id);
      promptAction.showToast({ message: '销假成功' });
      await this.loadData();
    } catch (e) {
      this.showError(e, '销假失败');
    } finally { this.actionBusy = false; }
  }

  showError(e: Object, defaultMessage: string): void {
    let message = defaultMessage;
    if (e instanceof ApiException) {
      message = e.message;
    }
    promptAction.showToast({ message: message });
  }

  build() {
    Scroll(this.scroller) {
      Column({ space: 12 }) {
        Text('请假与销假')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Column({ space: 8 }) {
          Text(this.editingId.length > 0 ? `编辑申请 #${this.editingId}` : '新建请假申请')
            .fontSize(16).fontWeight(FontWeight.Bold).width('100%')
          if (this.editingStatus === 5) {
            Text(`退回意见：${this.returnOpinion || '请联系审批人确认修改要求'}`).fontSize(13).fontColor('#D9534F').width('100%')
          }
          Row({ space: 8 }) {
            Text('类型').width(50)
            TextInput({ placeholder: '事假', text: this.leaveType })
              .enabled(!this.submitting && !this.actionBusy)
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
            .enabled(!this.submitting && !this.actionBusy)
            .height(72)
            .onChange((value: string) => {
              this.reason = value;
            })
          Button(this.submitting ? '处理中…' : (this.editingId.length > 0 ? '保存并提交审批' : '提交请假申请'))
            .enabled(!this.submitting && !this.actionBusy && !this.loading)
            .width('100%')
            .height(42)
            .onClick(() => {
              this.submit();
            })
          Row({ space: 10 }) {
            Button('保存草稿').height(34).fontSize(13).enabled(!this.submitting && !this.actionBusy && !this.loading)
              .onClick(() => this.submit('draft'))
            if (this.editingId.length > 0) {
              Button('取消编辑').height(34).fontSize(13).enabled(!this.submitting && !this.actionBusy)
                .onClick(() => this.resetForm())
            }
          }
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
              if (item.leave_status === 0 || item.leave_status === 5) {
                Button(item.leave_status === 5 ? '修改退回申请' : '编辑草稿')
                  .height(32).fontSize(12).enabled(!this.actionBusy && !this.submitting && !this.loading)
                  .onClick(() => this.requestEdit(item.id))
              }
              if (item.leave_status === 1 || item.leave_status === 2) {
                Button('撤回')
                  .enabled(!this.actionBusy && !this.submitting && !this.loading)
                  .height(30)
                  .fontSize(12)
                  .onClick(() => {
                    this.withdraw(item.id);
                  })
              }
              if (item.leave_status === 3) {
                Button('销假')
                  .enabled(!this.actionBusy && !this.submitting && !this.loading)
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
        PaginationBar({ pageNo: this.pageNo, total: this.total, loading: this.loading || this.submitting || this.actionBusy,
          onChange: (page: number) => this.loadData(page) })
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
