import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { AppTheme } from '../common/Theme';
import { CampusApi } from '../services/Api';

@Entry
@Component
struct ApprovalsPage {
  @State items: Object[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  @State opinion: string = '';

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.items = await CampusApi.pendingLeaves();
    } catch (e) {
      let message = '待审批列表加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  async decide(item: Object, decision: number): Promise<void> {
    try {
      let data = item as Record<string, Object>;
      let body: Record<string, Object> = {
        'apply_round': data['apply_round'] as number,
        'node_order': data['node_order'] as number,
        'decision': decision,
        'opinion': this.opinion.trim()
      };
      await CampusApi.approveLeave(data['id'] as string, body);
      promptAction.showToast({ message: decision === 1 ? '已通过' : '已驳回' });
      this.opinion = '';
      await this.loadData();
    } catch (e) {
      this.showError(e, '审批失败');
    }
  }

  showError(e: Object, defaultMessage: string): void {
    let message = defaultMessage;
    if (e instanceof ApiException) {
      message = e.message;
    }
    promptAction.showToast({ message: message });
  }

  cellValue(item: Object, key: string): string {
    let record = item as Record<string, Object>;
    let value = record[key];
    if (value === undefined || value === null) {
      return '';
    }
    if (typeof value === 'string') {
      return value;
    }
    return JSON.stringify(value);
  }

  build() {
    Scroll() {
      Column({ space: AppTheme.SPACE_SECTION }) {
        Text('待审批')
          .fontSize(AppTheme.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Column({ space: 10 }) {
          Text('审批意见')
            .fontSize(AppTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          TextInput({ placeholder: '审批意见', text: this.opinion })
            .height(44)
            .backgroundColor(AppTheme.COLOR_CARD)
            .borderRadius(AppTheme.RADIUS_BUTTON)
            .onChange((value: string) => {
              this.opinion = value;
            })
        }
        .padding(AppTheme.SPACE_SECTION)
        .width('100%')
        .borderRadius(AppTheme.RADIUS_CARD)
        .backgroundColor(AppTheme.COLOR_CARD)

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
          Text('加载中...')
            .fontSize(AppTheme.FONT_BODY)
            .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
        } else if (this.items.length === 0) {
          Text('暂无待审批事项')
            .fontSize(AppTheme.FONT_BODY)
            .fontColor(AppTheme.COLOR_TEXT_TERTIARY)
        } else {
          Column({ space: 0 }) {
            Row() {
              Text('ID').layoutWeight(1).fontSize(10).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('学生').layoutWeight(1).fontSize(10).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('类型').layoutWeight(1).fontSize(10).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('开始').layoutWeight(1.5).fontSize(10).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('结束').layoutWeight(1.5).fontSize(10).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
              Text('操作').layoutWeight(1).fontSize(10).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 2, right: 2 })
            .backgroundColor(AppTheme.COLOR_PRIMARY_LIGHT)

            ForEach(this.items, (item: Object, rowIndex: number) => {
              Row() {
                Text(this.cellValue(item, 'id')).layoutWeight(1).fontSize(10).textAlign(TextAlign.Center)
                Text(this.cellValue(item, 'student_id')).layoutWeight(1).fontSize(10).textAlign(TextAlign.Center)
                Text(this.cellValue(item, 'leave_type')).layoutWeight(1).fontSize(10).textAlign(TextAlign.Center)
                Text(this.cellValue(item, 'start_time')).layoutWeight(1.5).fontSize(10).textAlign(TextAlign.Center)
                Text(this.cellValue(item, 'end_time')).layoutWeight(1.5).fontSize(10).textAlign(TextAlign.Center)
                Row({ space: 4 }) {
                  Button('通过')
                    .height(28)
                    .fontSize(10)
                    .backgroundColor(AppTheme.COLOR_PRIMARY)
                    .onClick(() => {
                      this.decide(item, 1);
                    })
                  Button('驳回')
                    .height(28)
                    .fontSize(10)
                    .fontColor(AppTheme.COLOR_DANGER)
                    .backgroundColor(AppTheme.COLOR_CARD)
                    .onClick(() => {
                      this.decide(item, 2);
                    })
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .padding({ top: 6, bottom: 6, left: 2, right: 2 })
              .border({ width: 0.5, color: AppTheme.COLOR_BORDER })
            }, (item: Object, rowIndex: number) => `${rowIndex}`)
          }
          .width('100%')
          .borderRadius(AppTheme.RADIUS_ITEM)
          .backgroundColor(AppTheme.COLOR_CARD)
        }

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
