import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { formatDateTime, randomRequestKey } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { BookItem, BookLoanItem } from '../model/Models';

@Entry
@Component
struct LibraryPage {
  @State keyword: string = '';
  @State books: BookItem[] = [];
  @State loans: BookLoanItem[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      let bookPage = await CampusApi.books(this.keyword.trim());
      this.books = bookPage.items;
      let loanPage = await CampusApi.loans();
      this.loans = loanPage.items;
    } catch (e) {
      let message = '图书数据加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  async reserve(bookId: string): Promise<void> {
    try {
      let result = await CampusApi.reserveBook(bookId, randomRequestKey('book'));
      let data = result as Record<string, Object>;
      promptAction.showToast({ message: `预约状态：${data['reserve_status'] ?? ''}` });
    } catch (e) {
      this.showError(e, '预约失败');
    }
  }

  async renew(id: string): Promise<void> {
    try {
      await CampusApi.renewLoan(id);
      promptAction.showToast({ message: '续借成功' });
      await this.loadData();
    } catch (e) {
      this.showError(e, '续借失败');
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
      Text('图书服务')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Row({ space: 8 }) {
        TextInput({ placeholder: '书名 / 作者', text: this.keyword })
          .layoutWeight(1)
          .height(42)
          .onChange((value: string) => {
            this.keyword = value;
          })
        Button('检索')
          .height(42)
          .onClick(() => {
            this.loadData();
          })
      }
      .width('100%')

      Text('检索结果')
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
      } else if (this.books.length === 0) {
        Text('暂无图书').fontSize(14).fontColor('#999999')
      } else {
        ForEach(this.books, (item: BookItem) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(item.book_name)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
              Text(`${item.author ?? ''} · 可借 ${item.available_count}`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Button('预约')
              .height(32)
              .fontSize(12)
              .onClick(() => {
                this.reserve(item.id);
              })
          }
          .padding(12)
          .width('100%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
        }, (item: BookItem) => item.id)
      }

      Text('我的借阅')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      if (this.loans.length === 0) {
        Text('暂无借阅').fontSize(14).fontColor('#999999')
      } else {
        ForEach(this.loans, (item: BookLoanItem) => {
          Column({ space: 6 }) {
            Row() {
              Text(item.book_name)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text(`续借${item.renew_count}次`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .width('100%')
            Text(`副本 ${item.copy_no} · 应还 ${formatDateTime(item.due_time)}`)
              .fontSize(13)
              .fontColor('#666666')
            if (item.loan_status === 0) {
              Button('续借')
                .height(30)
                .fontSize(12)
                .onClick(() => {
                  this.renew(item.id);
                })
            }
          }
          .padding(12)
          .width('100%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
        }, (item: BookLoanItem) => item.id)
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
