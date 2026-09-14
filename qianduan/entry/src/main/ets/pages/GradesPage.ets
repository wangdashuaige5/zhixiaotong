import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { examFlagText, formatDate } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { GradeItem } from '../model/Models';

@Entry
@Component
struct GradesPage {
  @State items: GradeItem[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      let page = await CampusApi.myGrades();
      this.items = page.items;
    } catch (e) {
      let message = '成绩加载失败';
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
      Text('我的成绩')
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
        Text('暂无已发布成绩').fontSize(14).fontColor('#999999')
      } else {
        ForEach(this.items, (item: GradeItem) => {
          Column({ space: 6 }) {
            Row() {
              Text(item.course_name)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
              Text(`${item.total_score ?? '--'} 分`)
                .fontSize(18)
                .fontColor('#002FA7')
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')

            Text(`学分 ${item.credit} · ${examFlagText(item.exam_flag)}`)
              .fontSize(13)
              .fontColor('#666666')
            if (item.publish_time !== undefined) {
              Text(`发布时间 ${formatDate(item.publish_time)}`)
                .fontSize(12)
                .fontColor('#999999')
            }
          }
          .padding(14)
          .width('100%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
        }, (item: GradeItem) => item.id)
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
