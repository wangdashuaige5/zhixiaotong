import { promptAction, router } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { AppConstants } from '../common/Constants';
import { AppTheme } from '../common/Theme';
import { formatDateTime } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { TimetableItem, TodayCard } from '../model/Models';
@Component
export struct CampusPage {
  @State today: TodayCard | null = null;
  @State loading: boolean = true;
  @State error: string = '';

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.today = await CampusApi.today();
    } catch (e) {
      let message = '校园信息加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  go(page: string): void {
    router.pushUrl({ url: page });
  }

  build() {
    Scroll() {
      Column({ space: AppTheme.SPACE_SECTION }) {
        Text('校园')
          .fontSize(AppTheme.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.COLOR_TEXT_PRIMARY)
          .width('100%')

        Column({ space: 10 }) {
          Text('校园服务')
            .fontSize(AppTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          Grid() {
            GridItem() {
              Column({ space: 6 }) {
                Text('课表').fontSize(AppTheme.FONT_SECTION).fontColor(AppTheme.COLOR_PRIMARY)
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height('100%')
              .borderRadius(AppTheme.RADIUS_ITEM)
              .backgroundColor(AppTheme.COLOR_CARD)
              .border({ width: 1, color: AppTheme.COLOR_BORDER })
              .onClick(() => this.go(AppConstants.PAGE_TIMETABLE))
            }
            GridItem() {
              Column({ space: 6 }) {
                Text('选课').fontSize(AppTheme.FONT_SECTION).fontColor(AppTheme.COLOR_PRIMARY)
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height('100%')
              .borderRadius(AppTheme.RADIUS_ITEM)
              .backgroundColor(AppTheme.COLOR_CARD)
              .border({ width: 1, color: AppTheme.COLOR_BORDER })
              .onClick(() => this.go(AppConstants.PAGE_COURSES))
            }
            GridItem() {
              Column({ space: 6 }) {
                Text('成绩').fontSize(AppTheme.FONT_SECTION).fontColor(AppTheme.COLOR_PRIMARY)
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height('100%')
              .borderRadius(AppTheme.RADIUS_ITEM)
              .backgroundColor(AppTheme.COLOR_CARD)
              .border({ width: 1, color: AppTheme.COLOR_BORDER })
              .onClick(() => this.go(AppConstants.PAGE_GRADES))
            }
            GridItem() {
              Column({ space: 6 }) {
                Text('请假').fontSize(AppTheme.FONT_SECTION).fontColor(AppTheme.COLOR_PRIMARY)
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height('100%')
              .borderRadius(AppTheme.RADIUS_ITEM)
              .backgroundColor(AppTheme.COLOR_CARD)
              .border({ width: 1, color: AppTheme.COLOR_BORDER })
              .onClick(() => this.go(AppConstants.PAGE_LEAVE))
            }
            GridItem() {
              Column({ space: 6 }) {
                Text('校园卡').fontSize(AppTheme.FONT_SECTION).fontColor(AppTheme.COLOR_PRIMARY)
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height('100%')
              .borderRadius(AppTheme.RADIUS_ITEM)
              .backgroundColor(AppTheme.COLOR_CARD)
              .border({ width: 1, color: AppTheme.COLOR_BORDER })
              .onClick(() => this.go(AppConstants.PAGE_CARD))
            }
            GridItem() {
              Column({ space: 6 }) {
                Text('图书').fontSize(AppTheme.FONT_SECTION).fontColor(AppTheme.COLOR_PRIMARY)
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height('100%')
              .borderRadius(AppTheme.RADIUS_ITEM)
              .backgroundColor(AppTheme.COLOR_CARD)
              .border({ width: 1, color: AppTheme.COLOR_BORDER })
              .onClick(() => this.go(AppConstants.PAGE_LIBRARY))
            }
          }
          .columnsTemplate('1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .height(180)
          .width('100%')
        }
        .padding(AppTheme.SPACE_SECTION)
        .width('100%')
        .borderRadius(AppTheme.RADIUS_CARD)
        .backgroundColor(AppTheme.COLOR_CARD)

        Column({ space: 10 }) {
          Row() {
            Text('今日课程')
              .fontSize(AppTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
            Blank()
            if (this.today !== null) {
              Text(`未读 ${this.today.unread_messages}`)
                .fontSize(AppTheme.FONT_CAPTION)
                .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
            }
          }
          .width('100%')

          if (this.error.length > 0) {
            Column({ space: 10 }) {
              Text(this.error)
                .fontSize(AppTheme.FONT_BODY)
                .fontColor(AppTheme.COLOR_DANGER)
              Button('重新加载')
                .height(36)
                .fontSize(AppTheme.FONT_BODY)
                .onClick(() => {
                  this.loadData();
                })
            }
            .width('100%')
          } else if (this.loading) {
            Text('加载中...')
              .fontSize(AppTheme.FONT_BODY)
              .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
          } else if (this.today === null || this.today.timetables.length === 0) {
            Text('今天没有课程安排')
              .fontSize(AppTheme.FONT_BODY)
              .fontColor(AppTheme.COLOR_TEXT_TERTIARY)
          } else {
            ForEach(this.today.timetables, (item: TimetableItem) => {
              Row({ space: 10 }) {
                Text(item.course_name)
                  .fontSize(AppTheme.FONT_BODY)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                Text(item.room_name)
                  .fontSize(AppTheme.FONT_CAPTION)
                  .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
                Text(`${formatDateTime(item.start_time)}`)
                  .fontSize(AppTheme.FONT_CAPTION)
                  .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
              }
              .width('100%')
            }, (item: TimetableItem) => item.id)
          }
        }
        .padding(AppTheme.SPACE_SECTION)
        .width('100%')
        .borderRadius(AppTheme.RADIUS_CARD)
        .backgroundColor(AppTheme.COLOR_CARD)
      }
      .padding(AppTheme.SPACE_PAGE)
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
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
