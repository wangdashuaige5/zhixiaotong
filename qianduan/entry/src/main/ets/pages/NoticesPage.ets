import { promptAction } from '@kit.ArkUI';
import { ApiException, HttpClient } from '../common/Http';
import { formatDateTime } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { NoticeItem } from '../model/Models';

@Entry
@Component
struct NoticesPage {
  @State items: NoticeItem[] = [];
  @State detail: Record<string, Object> | null = null;
  @State loading: boolean = true;
  @State error: string = '';

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      let page = await CampusApi.notices();
      this.items = page.items;
    } catch (e) {
      let message = '通知加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  async openDetail(id: string): Promise<void> {
    try {
      let data = await CampusApi.noticeDetail(id);
      this.detail = data as Record<string, Object>;
    } catch (e) {
      this.showError(e, '通知详情加载失败');
    }
  }

  async ack(id: string): Promise<void> {
    try {
      await HttpClient.post(`/api/notices/${id}/ack`, undefined);
      promptAction.showToast({ message: '已确认已阅' });
    } catch (e) {
      this.showError(e, '确认失败');
    }
  }

  showError(e: Object, defaultMessage: string): void {
    let message = defaultMessage;
    if (e instanceof ApiException) {
      message = e.message;
    }
    promptAction.showToast({ message: message });
  }

  urgencyText(level: number): string {
    switch (level) {
      case 0:
        return '普通';
      case 1:
        return '重要';
      case 2:
        return '紧急';
      default:
        return '普通';
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
      Text('通知公告')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      if (this.detail !== null) {
        Column({ space: 8 }) {
          Text(this.detail['notice_title'] as string)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          Text(this.detail['content'] as string)
            .fontSize(14)
            .fontColor('#1F1F1F')
            .width('100%')
          Button('关闭详情')
            .height(32)
            .fontSize(12)
            .onClick(() => {
              this.detail = null;
            })
        }
        .padding(14)
        .width('100%')
        .borderRadius(12)
        .backgroundColor('#FFFFFF')
      }

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
        Text('暂无通知').fontSize(14).fontColor('#999999')
      } else {
        ForEach(this.items, (item: NoticeItem) => {
          Row({ space: 10 }) {
            Column({ space: 5 }) {
              Row({ space: 6 }) {
                Text(item.notice_title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                if (item.is_pinned === 1) {
                  Text('置顶')
                    .fontSize(11)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#002FA7')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                }
              }
              Text(`${this.urgencyText(item.urgency_level)} · ${formatDateTime(item.start_time)}`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button('详情')
              .height(30)
              .fontSize(12)
              .onClick(() => {
                this.openDetail(item.id);
              })
            if (item.need_ack === 1) {
              Button('已阅')
                .height(30)
                .fontSize(12)
                .onClick(() => {
                  this.ack(item.id);
                })
            }
          }
          .padding(12)
          .width('100%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
        }, (item: NoticeItem) => item.id)
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
