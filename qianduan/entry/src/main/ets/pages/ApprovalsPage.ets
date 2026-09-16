import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { AppTheme } from '../common/Theme';
import { CampusApi } from '../services/Api';

@Entry
@Component
struct ApprovalsPage {
  @State items: Object[] = [];
  @State loading: boolean = false;
  @State error: string = '';
  @State opinion: string = '';
  @State busy: boolean = false;

  aboutToAppear(): void { this.loadData(); }

  async loadData(): Promise<void> {
    if (this.loading) { return; }
    this.loading = true;
    this.error = '';
    try {
      this.items = await CampusApi.pendingLeaves();
    } catch (e) {
      let message = '待审批列表加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      this.items = [];
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  async decide(item: Object, decision: number): Promise<void> {
    if (this.busy || this.loading) { return; }
    if (decision !== 1 && this.opinion.trim().length === 0) {
      promptAction.showToast({ message: '驳回或退回修改时，请填写审批意见' });
      return;
    }
    this.busy = true;
    try {
      let data = item as Record<string, Object>;
      const action = decision === 1 ? '通过' : decision === 2 ? '驳回' : '退回修改';
      const answer = await promptAction.showDialog({ title: `${action}请假申请`,
        message: `确认${action}申请 ${data['id']} 吗？\n审批意见：${this.opinion.trim() || '无'}`,
        buttons: [{ text: '取消', color: '#666666' }, { text: '确认', color: AppTheme.COLOR_PRIMARY }] });
      if (answer.index !== 1) { return; }
      let body: Record<string, Object> = {
        'apply_round': data['apply_round'] as number,
        'node_order': data['node_order'] as number,
        'decision': decision,
        'opinion': this.opinion.trim()
      };
      await CampusApi.approveLeave(data['id'] as string, body);
      promptAction.showToast({ message: decision === 1 ? '已通过' : decision === 2 ? '已驳回' : '已退回修改' });
      this.opinion = '';
      await this.loadData();
    } catch (e) {
      this.showError(e, '审批失败');
    } finally { this.busy = false; }
  }

  showError(e: Object, defaultMessage: string): void {
    let message = defaultMessage;
    if (e instanceof ApiException) {
      message = e.message;
    }
    promptAction.showToast({ message: message });
  }

  cellValue(item: Object, key: string): string {
    let record = item as Record<string, Object>;
    let value = record[key];
    if (value === undefined || value === null) {
      return '';
    }
    if (typeof value === 'string') {
      return value;
    }
    return JSON.stringify(value);
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('请假待审批').fontSize(22).fontWeight(FontWeight.Bold).width('100%')
        Button('刷新待办').enabled(!this.busy && !this.loading).onClick(() => this.loadData())
        TextArea({ placeholder: '审批意见（驳回、退回修改时必填）', text: this.opinion })
          .height(90).width('100%').enabled(!this.busy)
          .onChange((value: string) => { this.opinion = value; })
        if (this.loading) { LoadingProgress().width(36).height(36) }
        else if (this.error.length > 0) { Text(this.error).fontColor('#D9534F') }
        else if (this.items.length === 0) { Text('暂无待审批事项').fontColor('#666666') }
        ForEach(this.items, (item: Object) => {
          // 功能：一条申请一张卡片，手机上能看清身份、请假原因与审批操作。
          Column({ space: 10 }) {
            Text(`申请 ${this.cellValue(item, 'id')} · ${this.cellValue(item, 'leave_type')}`)
              .fontSize(17).fontWeight(FontWeight.Bold).width('100%')
            Text(`申请人：${this.cellValue(item, 'real_name') || this.cellValue(item, 'student_id')} ${this.cellValue(item, 'user_no')}`)
              .fontSize(15).width('100%')
            Text(`开始：${this.cellValue(item, 'start_time').replace('T', ' ').substring(0, 16)}`).fontSize(14).width('100%')
            Text(`结束：${this.cellValue(item, 'end_time').replace('T', ' ').substring(0, 16)}`).fontSize(14).width('100%')
            Text(`原因：${this.cellValue(item, 'leave_reason')}`).fontSize(14).width('100%')
            Row({ space: 8 }) {
              Button('通过').layoutWeight(1).enabled(!this.busy && !this.loading).onClick(() => this.decide(item, 1))
              Button('驳回').layoutWeight(1).backgroundColor('#D9534F').enabled(!this.busy && !this.loading).onClick(() => this.decide(item, 2))
              Button('退回修改').layoutWeight(1).enabled(!this.busy && !this.loading).onClick(() => this.decide(item, 3))
            }.width('100%')
          }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
        }, (item: Object) => this.cellValue(item, 'id'))
      }.padding(16).width('100%')
    }.width('100%').height('100%').backgroundColor('#F2F4F8')
  }
}
