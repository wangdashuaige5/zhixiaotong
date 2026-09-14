import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { formatDateTime, randomRequestKey } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { CardBalance, CardTransaction } from '../model/Models';

@Entry
@Component
struct CampusCardPage {
  @State balance: CardBalance | null = null;
  @State transactions: CardTransaction[] = [];
  @State amount: string = '';
  @State loading: boolean = true;
  @State error: string = '';

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.balance = await CampusApi.cardBalance();
      let page = await CampusApi.cardTransactions();
      this.transactions = page.items;
    } catch (e) {
      let message = '校园卡信息加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  async recharge(): Promise<void> {
    if (this.amount.trim().length === 0) {
      promptAction.showToast({ message: '请输入充值金额' });
      return;
    }
    try {
      let result = await CampusApi.recharge(this.amount.trim(), randomRequestKey('recharge'));
      let data = result as Record<string, Object>;
      promptAction.showToast({ message: `订单已创建：${data['order_no'] ?? ''}` });
      this.amount = '';
      await this.loadData();
    } catch (e) {
      this.showError(e, '充值失败');
    }
  }

  showError(e: Object, defaultMessage: string): void {
    let message = defaultMessage;
    if (e instanceof ApiException) {
      message = e.message;
    }
    promptAction.showToast({ message: message });
  }

  transactionTypeText(type: number): string {
    switch (type) {
      case 1:
        return '充值';
      case 2:
        return '消费';
      case 3:
        return '退款';
      default:
        return '未知';
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
      Text('校园卡')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      if (this.balance !== null) {
        Column({ space: 8 }) {
          Text('当前余额')
            .fontSize(13)
            .fontColor('#666666')
          Text(`¥${this.balance.balance}`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#002FA7')
          Text(`卡号 ${this.balance.card_no} · ${this.balance.integration_mode}`)
            .fontSize(12)
            .fontColor('#999999')
        }
        .padding(18)
        .width('100%')
        .borderRadius(14)
        .backgroundColor('#FFFFFF')
      }

      Row({ space: 8 }) {
        TextInput({ placeholder: '充值金额', text: this.amount })
          .layoutWeight(1)
          .height(42)
          .onChange((value: string) => {
            this.amount = value;
          })
        Button('充值')
          .height(42)
          .onClick(() => {
            this.recharge();
          })
      }
      .width('100%')

      Text('消费流水')
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
      } else if (this.transactions.length === 0) {
        Text('暂无流水').fontSize(14).fontColor('#999999')
      } else {
        ForEach(this.transactions, (item: CardTransaction) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(this.transactionTypeText(item.transaction_type))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
              Text(formatDateTime(item.transaction_time))
                .fontSize(12)
                .fontColor('#999999')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text(`¥${item.amount}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
          }
          .padding(12)
          .width('100%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
        }, (item: CardTransaction) => item.id)
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
