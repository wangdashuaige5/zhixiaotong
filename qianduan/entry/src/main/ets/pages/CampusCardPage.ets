import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { formatDateTime, randomRequestKey } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { CardBalance, CardTransaction, RechargeOrder } from '../model/Models';
import { PaginationBar } from '../components/PaginationBar';

@Entry
@Component
struct CampusCardPage {
  @State balance: CardBalance | null = null;
  @State transactions: CardTransaction[] = [];
  @State order: RechargeOrder | null = null;
  @State amount: string = '';
  @State loading: boolean = false;
  @State busy: boolean = false;
  @State error: string = '';
  @State unavailable: boolean = false;
  @State pageNo: number = 1;
  @State total: number = 0;
  private requestAmount: string = '';
  private requestKey: string = '';

  // 无权限/未绑卡属于业务状态，不提示为后端断连；加载失败清空过期余额。
  async loadData(pageNo: number = this.pageNo): Promise<void> {
    if (this.loading) { return; }
    this.loading = true; this.pageNo = pageNo; this.error = ''; this.unavailable = false;
    this.balance = null; this.transactions = []; this.total = 0;
    try {
      let balance = await CampusApi.cardBalance();
      let page = await CampusApi.cardTransactions(pageNo);
      this.balance = balance; this.transactions = page.items; this.total = Number(page.total);
    } catch (e) {
      if (e instanceof ApiException && e.code === 403) {
        this.unavailable = true;
        this.error = '当前账号没有校园卡服务权限，请使用已获授权的学生账号';
        this.order = null;
      } else if (e instanceof ApiException && e.code === 404) {
        this.unavailable = true;
        this.error = '当前账号尚未绑定校园卡，请联系学校管理员办理或绑定';
        this.order = null;
      } else { this.error = e instanceof ApiException ? e.message : '校园卡信息加载失败，请重试'; }
    } finally { this.loading = false; }
  }

  validAmount(value: string): boolean {
    return /^\d+(\.\d{1,2})?$/.test(value) && Number(value) > 0 && Number(value) <= 10000;
  }

  // 同一金额网络重试复用请求键；前端不生成支付签名，不自行改余额或模拟入账。
  async recharge(): Promise<void> {
    if (this.busy || this.loading) { return; }
    if (this.balance === null || this.balance.account_status !== 1) {
      promptAction.showToast({ message: '请先确认已绑定且正常的校园卡' }); return;
    }
    if (this.balance.integration_mode !== 'mock') {
      promptAction.showToast({ message: '学校支付接口尚未配置，暂不能创建充值订单' }); return;
    }
    let value = this.amount.trim();
    if (!this.validAmount(value)) {
      promptAction.showToast({ message: '金额应大于 0、不超过 10000，最多两位小数' }); return;
    }
    if (this.requestAmount !== value || this.requestKey.length === 0) {
      this.requestAmount = value; this.requestKey = randomRequestKey('recharge');
    }
    this.busy = true;
    try {
      this.order = await CampusApi.recharge(value, this.requestKey);
      this.amount = ''; this.requestKey = ''; this.requestAmount = '';
      promptAction.showToast({ message: '待支付订单已创建，尚未扣款或到账' });
    } catch (e) { this.showError(e, '订单创建失败，可重试查询同一请求'); }
    finally { this.busy = false; }
  }

  async refreshOrder(): Promise<void> {
    if (this.busy || this.loading || this.order === null) { return; }
    this.busy = true;
    try {
      this.order = await CampusApi.rechargeOrder(this.order.id);
      if (this.order.order_status === 2) { await this.loadData(1); }
      promptAction.showToast({ message: '订单状态已更新' });
    } catch (e) { this.showError(e, '订单查询失败，请重试'); }
    finally { this.busy = false; }
  }

  orderStatusText(status: number): string {
    switch (status) {
      case 0: return '待支付（尚未到账）';
      case 1: return '已验款，等待入账';
      case 2: return '已入账';
      case 3: return '已关闭';
      default: return '未知状态';
    }
  }

  showError(e: Object, fallback: string): void {
    promptAction.showToast({ message: e instanceof ApiException ? e.message : fallback });
  }

  transactionTypeText(type: number): string {
    switch (type) { case 1: return '充值'; case 2: return '消费'; case 3: return '退款'; default: return '未知'; }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('校园卡').fontSize(22).fontWeight(FontWeight.Bold).width('100%')
        if (this.error.length > 0) {
          Text(this.error).fontSize(14).fontColor(this.unavailable ? '#666666' : '#D9534F')
          Button('重新加载').enabled(!this.loading && !this.busy).onClick(() => this.loadData())
        }
        if (this.loading) { Text('加载中…').fontSize(14).fontColor('#666666') }
        if (this.balance !== null) {
          Column({ space: 8 }) {
            Text('当前余额').fontSize(13).fontColor('#666666')
            Text(`¥${this.balance.balance}`).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#002FA7')
            Text(`卡号 ${this.balance.card_no}`).fontSize(12).fontColor('#999999')
            Text(this.balance.account_status === 1 ? '账户正常' : '账户不可充值').fontSize(12)
          }.padding(18).width('100%').borderRadius(14).backgroundColor('#FFFFFF')
          Text(this.balance.integration_mode === 'mock' ?
            '当前为演示环境：这里只创建待支付订单，不会自动到账；实际入账须由服务端验证支付结果。' :
            '学校支付接口尚未配置，充值暂不可用。').fontSize(13).fontColor('#666666')
          Row({ space: 8 }) {
            TextInput({ placeholder: '充值金额', text: this.amount }).layoutWeight(1).height(42)
              .enabled(!this.busy).onChange((value: string) => { this.amount = value; })
            Button(this.busy ? '处理中…' : '创建待支付订单').height(42).fontSize(12)
              .enabled(!this.loading && !this.busy && this.balance.account_status === 1 && this.balance.integration_mode === 'mock')
              .onClick(() => this.recharge())
          }.width('100%')
        }
        if (this.order !== null) {
          Column({ space: 8 }) {
            Text('本次充值订单').fontSize(16).fontWeight(FontWeight.Bold)
            Text(`订单号 ${this.order.order_no}`).fontSize(13)
            Text(`金额 ¥${this.order.amount} · ${this.orderStatusText(this.order.order_status)}`).fontSize(14)
            if (this.order.expire_time) { Text(`到期时间 ${formatDateTime(this.order.expire_time)}`).fontSize(12) }
            Button('查询订单状态').height(32).enabled(!this.busy && !this.loading).onClick(() => this.refreshOrder())
          }.padding(14).width('100%').borderRadius(12).backgroundColor('#FFFFFF')
        }
        Text('账户流水').fontSize(16).fontWeight(FontWeight.Bold).width('100%')
        if (!this.loading && this.error.length === 0 && this.transactions.length === 0) {
          Text('暂无流水').fontSize(14).fontColor('#999999')
        }
        ForEach(this.transactions, (item: CardTransaction) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(this.transactionTypeText(item.transaction_type)).fontSize(15).fontWeight(FontWeight.Medium)
              Text(formatDateTime(item.transaction_time)).fontSize(12).fontColor('#999999')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text(`¥${item.amount}`).fontSize(16).fontWeight(FontWeight.Bold)
          }.padding(12).width('100%').borderRadius(10).backgroundColor('#FFFFFF')
        }, (item: CardTransaction) => item.id)
        PaginationBar({ pageNo: this.pageNo, total: this.total, loading: this.loading || this.busy,
          onChange: (page: number) => this.loadData(page) })
      }.padding(20).width('100%').backgroundColor('#F2F4F8').onAppear(() => this.loadData())
    }.width('100%').height('100%').backgroundColor('#F2F4F8').align(Alignment.Top)
  }
}
