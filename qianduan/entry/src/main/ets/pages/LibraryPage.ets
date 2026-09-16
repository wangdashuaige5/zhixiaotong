import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { formatDateTime, randomRequestKey } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { BookItem, BookLoanItem, BookReservationItem } from '../model/Models';
import { PaginationBar } from '../components/PaginationBar';

@Entry
@Component
struct LibraryPage {
  @State keyword: string = '';
  @State appliedKeyword: string = '';
  @State books: BookItem[] = [];
  @State loans: BookLoanItem[] = [];
  @State reservations: BookReservationItem[] = [];
  @State bookPage: number = 1;
  @State loanPage: number = 1;
  @State reservationPage: number = 1;
  @State bookTotal: number = 0;
  @State loanTotal: number = 0;
  @State reservationTotal: number = 0;
  @State loading: boolean = false;
  @State busy: boolean = false;
  @State error: string = '';

  // 三类列表独立分页；仅全部加载成功后更新，失败不残留上一页数据。
  async loadData(): Promise<void> {
    if (this.loading) { return; }
    this.loading = true;
    this.error = '';
    this.books = []; this.loans = []; this.reservations = [];
    this.bookTotal = 0; this.loanTotal = 0; this.reservationTotal = 0;
    try {
      let books = await CampusApi.books(this.appliedKeyword, this.bookPage);
      let loans = await CampusApi.loans(this.loanPage);
      let reservations = await CampusApi.reservations(this.reservationPage);
      this.books = books.items; this.bookTotal = Number(books.total);
      this.loans = loans.items; this.loanTotal = Number(loans.total);
      this.reservations = reservations.items; this.reservationTotal = Number(reservations.total);
    } catch (e) {
      this.error = e instanceof ApiException ? e.message : '图书数据加载失败，请重试';
    } finally { this.loading = false; }
  }

  search(): void {
    if (this.loading || this.busy) { return; }
    this.appliedKeyword = this.keyword.trim(); this.bookPage = 1;
    this.loadData();
  }

  changePage(section: string, page: number): void {
    if (this.loading || this.busy || page < 1) { return; }
    if (section === 'books') { this.bookPage = page; }
    else if (section === 'loans') { this.loanPage = page; }
    else { this.reservationPage = page; }
    this.loadData();
  }

  reservationStatus(status: number): string {
    switch (status) {
      case 0: return '排队中';
      case 1: return '可领取';
      case 2: return '已领取';
      case 3: return '已取消';
      case 4: return '已过期';
      default: return '未知状态';
    }
  }

  // 预约、取消和续借只调用已有本人业务接口；忙碌锁防止连续点击。
  async reserve(bookId: string): Promise<void> {
    if (this.busy || this.loading) { return; }
    this.busy = true;
    try {
      await CampusApi.reserveBook(bookId, randomRequestKey('book'));
      promptAction.showToast({ message: '预约已提交，请在我的预约查看领取状态' });
      this.reservationPage = 1;
      await this.loadData();
    } catch (e) { this.showError(e, '预约失败'); }
    finally { this.busy = false; }
  }

  async cancelReservation(id: string): Promise<void> {
    if (this.busy || this.loading) { return; }
    this.busy = true;
    try {
      await CampusApi.cancelReservation(id);
      promptAction.showToast({ message: '预约已取消' });
      await this.loadData();
    } catch (e) { this.showError(e, '取消预约失败'); }
    finally { this.busy = false; }
  }

  async renew(id: string): Promise<void> {
    if (this.busy || this.loading) { return; }
    this.busy = true;
    try {
      await CampusApi.renewLoan(id);
      promptAction.showToast({ message: '续借成功' });
      await this.loadData();
    } catch (e) { this.showError(e, '续借失败'); }
    finally { this.busy = false; }
  }

  showError(e: Object, fallback: string): void {
    promptAction.showToast({ message: e instanceof ApiException ? e.message : fallback });
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('图书服务').fontSize(22).fontWeight(FontWeight.Bold).width('100%')
        Row({ space: 8 }) {
          TextInput({ placeholder: '书名 / 作者', text: this.keyword }).layoutWeight(1).height(42)
            .onChange((value: string) => { this.keyword = value; })
          Button('检索').height(42).enabled(!this.loading && !this.busy).onClick(() => this.search())
        }.width('100%')
        if (this.error.length > 0) {
          Text(this.error).fontSize(14).fontColor('#D9534F')
          Button('重新加载').enabled(!this.loading && !this.busy).onClick(() => this.loadData())
        }
        if (this.loading) { Text('加载中…').fontSize(14).fontColor('#666666') }
        Text('检索结果').fontSize(16).fontWeight(FontWeight.Bold).width('100%')
        if (!this.loading && this.error.length === 0 && this.books.length === 0) {
          Text('暂无匹配图书').fontSize(14).fontColor('#999999')
        }
        ForEach(this.books, (item: BookItem) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(item.book_name).fontSize(15).fontWeight(FontWeight.Medium)
              Text(`${item.author ?? ''} · 可借 ${item.available_count}`).fontSize(12).fontColor('#666666')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Button('预约').height(32).fontSize(12).enabled(!this.busy && !this.loading)
              .onClick(() => this.reserve(item.id))
          }.padding(12).width('100%').borderRadius(10).backgroundColor('#FFFFFF')
        }, (item: BookItem) => item.id)
        PaginationBar({ pageNo: this.bookPage, total: this.bookTotal, loading: this.loading || this.busy,
          onChange: (page: number) => this.changePage('books', page) })

        Text('我的预约').fontSize(16).fontWeight(FontWeight.Bold).width('100%')
        if (!this.loading && this.error.length === 0 && this.reservations.length === 0) {
          Text('暂无预约').fontSize(14).fontColor('#999999')
        }
        ForEach(this.reservations, (item: BookReservationItem) => {
          Column({ space: 6 }) {
            Text(`${item.book_name} · ${this.reservationStatus(item.reserve_status)}`).fontSize(15)
            Text(`预约时间 ${formatDateTime(item.reserve_time)}`).fontSize(12).fontColor('#666666')
            if (item.reserve_status === 1 && item.expire_time) {
              Text(`请在 ${formatDateTime(item.expire_time)} 前到馆领取`).fontSize(13).fontColor('#002FA7')
            }
            if (item.reserve_status === 0 || item.reserve_status === 1) {
              Button('取消预约').height(30).fontSize(12).enabled(!this.busy && !this.loading)
                .onClick(() => this.cancelReservation(item.id))
            }
          }.padding(12).width('100%').borderRadius(10).backgroundColor('#FFFFFF')
        }, (item: BookReservationItem) => item.id)
        PaginationBar({ pageNo: this.reservationPage, total: this.reservationTotal, loading: this.loading || this.busy,
          onChange: (page: number) => this.changePage('reservations', page) })

        Text('我的借阅').fontSize(16).fontWeight(FontWeight.Bold).width('100%')
        if (!this.loading && this.error.length === 0 && this.loans.length === 0) {
          Text('暂无借阅').fontSize(14).fontColor('#999999')
        }
        ForEach(this.loans, (item: BookLoanItem) => {
          Column({ space: 6 }) {
            Text(`${item.book_name} · 续借 ${item.renew_count} 次`).fontSize(15)
            Text(`副本 ${item.copy_no} · 应还 ${formatDateTime(item.due_time)}`).fontSize(13).fontColor('#666666')
            if (item.loan_status === 0) {
              Button('续借').height(30).fontSize(12).enabled(!this.busy && !this.loading)
                .onClick(() => this.renew(item.id))
            }
          }.padding(12).width('100%').borderRadius(10).backgroundColor('#FFFFFF')
        }, (item: BookLoanItem) => item.id)
        PaginationBar({ pageNo: this.loanPage, total: this.loanTotal, loading: this.loading || this.busy,
          onChange: (page: number) => this.changePage('loans', page) })
      }.padding(20).width('100%').backgroundColor('#F2F4F8').onAppear(() => this.loadData())
    }.width('100%').height('100%').backgroundColor('#F2F4F8').align(Alignment.Top)
  }
}
