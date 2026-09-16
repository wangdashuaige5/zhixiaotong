// 通用分页栏：记录总数来自后端，加载期间禁止翻页，避免旧响应覆盖新列表。
@Component
export struct PaginationBar {
  @Prop pageNo: number = 1;
  @Prop total: number = 0;
  @Prop pageSize: number = 20;
  @Prop loading: boolean = false;
  onChange: (page: number) => void = () => {};

  build() {
    Row({ space: 12 }) {
      Button('上一页').height(32).fontSize(12)
        .enabled(!this.loading && this.pageNo > 1)
        .onClick(() => this.onChange(this.pageNo - 1))
      Text(`第 ${this.pageNo} 页 · 共 ${this.total} 条`).fontSize(12).layoutWeight(1).textAlign(TextAlign.Center)
      Button('下一页').height(32).fontSize(12)
        .enabled(!this.loading && this.pageNo * this.pageSize < this.total)
        .onClick(() => this.onChange(this.pageNo + 1))
    }.width('100%').padding({ top: 6, bottom: 6 })
  }
}
