import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { enrollStatusText, randomRequestKey } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { CourseOption, EnrollmentItem } from '../model/Models';

@Entry
@Component
struct CoursesPage {
  @State enrollments: EnrollmentItem[] = [];
  @State options: CourseOption[] = [];
  @State batchId: string = '5';
  @State keyword: string = '';
  @State loading: boolean = true;
  @State error: string = '';

  async loadMyCourses(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      let page = await CampusApi.myEnrollments();
      this.enrollments = page.items;
    } catch (e) {
      let message = '选课记录加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  async loadOptions(): Promise<void> {
    if (this.batchId.trim().length === 0) {
      promptAction.showToast({ message: '请输入选课批次ID' });
      return;
    }
    try {
      let page = await CampusApi.enrollmentOptions(this.batchId.trim(), this.keyword.trim());
      this.options = page.items;
    } catch (e) {
      this.showError(e, '可选课程加载失败');
    }
  }

  async choose(item: CourseOption): Promise<void> {
    try {
      let result = await CampusApi.submitEnrollment(item.id, randomRequestKey('enroll'));
      let data = result as Record<string, Object>;
      promptAction.showToast({ message: `提交成功：${data['result_note'] ?? ''}` });
      await this.loadMyCourses();
    } catch (e) {
      this.showError(e, '选课提交失败');
    }
  }

  async drop(id: string): Promise<void> {
    try {
      await CampusApi.dropEnrollment(id);
      promptAction.showToast({ message: '退选已提交' });
      await this.loadMyCourses();
    } catch (e) {
      this.showError(e, '退选失败');
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
      Text('选课与我的课程')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Row({ space: 8 }) {
        TextInput({ placeholder: '批次ID', text: this.batchId })
          .layoutWeight(1)
          .height(42)
          .onChange((value: string) => {
            this.batchId = value;
          })
        TextInput({ placeholder: '课程关键词', text: this.keyword })
          .layoutWeight(1)
          .height(42)
          .onChange((value: string) => {
            this.keyword = value;
          })
        Button('查询')
          .height(42)
          .onClick(() => {
            this.loadOptions();
          })
      }
      .width('100%')

      if (this.options.length > 0) {
        Text('可选课程')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        ForEach(this.options, (item: CourseOption) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(item.course_name).fontSize(15).fontWeight(FontWeight.Medium)
              Text(`${item.teacher_name} · 已选${item.enrolled_count}/${item.capacity}`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Button('选课')
              .height(32)
              .fontSize(12)
              .onClick(() => {
                this.choose(item);
              })
          }
          .padding(12)
          .width('100%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
        }, (item: CourseOption) => item.id)
      }

      Text('我的选课')
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
              this.loadMyCourses();
            })
        }
        .padding(12)
        .width('100%')
        .borderRadius(12)
        .backgroundColor('#FFFFFF')
      } else if (this.loading) {
        Text('加载中...').fontSize(14).fontColor('#666666')
      } else if (this.enrollments.length === 0) {
        Text('暂无选课记录').fontSize(14).fontColor('#999999')
      } else {
        ForEach(this.enrollments, (item: EnrollmentItem) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(item.course_name).fontSize(15).fontWeight(FontWeight.Medium)
              Text(`${item.class_name} · ${enrollStatusText(item.enroll_status)}`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            if (item.enroll_status === 1) {
              Button('退选')
                .height(32)
                .fontSize(12)
                .onClick(() => {
                  this.drop(item.id);
                })
            }
          }
          .padding(12)
          .width('100%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
        }, (item: EnrollmentItem) => item.id)
      }
      }
      .padding(20)
      .width('100%')
      .backgroundColor('#F2F4F8')
      .onAppear(() => {
        this.loadMyCourses();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F4F8')
    .align(Alignment.Top)
  }
}
