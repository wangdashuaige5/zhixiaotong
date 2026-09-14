import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { formatDateTime } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { ExamItem } from '../model/Models';
import { AppTheme } from '../common/Theme';

@Entry
@Component
struct ExamsPage {
  @State items: ExamItem[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      let page = await CampusApi.exams();
      this.items = page.items;
    } catch (e) {
      let message = '考试安排加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
      Text('考试安排')
        .fontSize(AppTheme.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      if (this.error.length > 0) {
        Column({ space: 10 }) {
          Text(this.error)
            .fontSize(AppTheme.FONT_BODY)
            .fontColor(AppTheme.COLOR_DANGER)
          Button('重新加载')
            .height(36)
            .onClick(() => {
              this.loadData();
            })
        }
        .padding(AppTheme.SPACE_ITEM)
        .width('100%')
        .borderRadius(AppTheme.RADIUS_CARD)
        .backgroundColor(AppTheme.COLOR_CARD)
      } else if (this.loading) {
        Text('加载中...').fontSize(14).fontColor('#666666')
      } else if (this.items.length === 0) {
        Text('暂无考试安排').fontSize(AppTheme.FONT_BODY).fontColor(AppTheme.COLOR_TEXT_TERTIARY)
      } else {
        ForEach(this.items, (item: ExamItem) => {
          Column({ space: 6 }) {
            Text(item.course_name)
              .fontSize(AppTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.COLOR_PRIMARY)
            Text(`${item.room_name}`)
              .fontSize(AppTheme.FONT_CAPTION)
              .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
            Text(`${formatDateTime(item.start_time)} - ${formatDateTime(item.end_time)}`)
              .fontSize(AppTheme.FONT_CAPTION)
              .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
          }
          .padding(AppTheme.SPACE_ITEM)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_ITEM)
          .backgroundColor(AppTheme.COLOR_CARD)
        }, (item: ExamItem) => item.id)
      }
      }
      .padding(AppTheme.SPACE_PAGE)
      .width('100%')
      .backgroundColor(AppTheme.COLOR_BACKGROUND)
      .onAppear(() => {
        this.loadData();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.COLOR_BACKGROUND)
    .align(Alignment.Top)
  }
}
