import { promptAction } from '@kit.ArkUI';
import { ApiException, HttpClient } from '../common/Http';
import { CampusApi } from '../services/Api';
import { MessageItem } from '../model/Models';
@Component
export struct MessagesPage {
  @State items: MessageItem[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      let page = await CampusApi.messages();
      this.items = page.items;
    } catch (e) {
      let message = '消息加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  async read(id: string): Promise<void> {
    try {
      await HttpClient.post(`/api/messages/${id}/read`, undefined);
      promptAction.showToast({ message: '已标记为已读' });
      await this.loadData();
    } catch (e) {
      this.showError(e, '标记失败');
    }
  }

  isUnread(readTime?: string | null): boolean {
    return readTime === undefined || readTime === null || readTime.length === 0;
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
        Text('消息中心')
        .fontSize(22)
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
        Text('暂无消息').fontSize(14).fontColor('#999999')
      } else {
        ForEach(this.items, (item: MessageItem) => {
          Row({ space: 10 }) {
            Column({ space: 5 }) {
              Text(item.message_title ?? '站内消息')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
              Text(item.content ?? '')
                .fontSize(12)
                .fontColor('#666666')
                .maxLines(2)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (this.isUnread(item.read_time)) {
              Text('未读')
                .fontSize(11)
                .fontColor('#D9534F')
            }
            Button('已读')
              .height(30)
              .fontSize(12)
              .onClick(() => {
                this.read(item.id);
              })
          }
          .padding(12)
          .width('100%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
        }, (item: MessageItem) => item.id)
      }
      }
      .padding(20)
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
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
