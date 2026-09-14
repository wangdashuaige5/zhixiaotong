import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { formatDateTime } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { AssignmentItem } from '../model/Models';
import { AppTheme } from '../common/Theme';

@Entry
@Component
struct AssignmentsPage {
  @State courseId: string = '5';
  @State teachingClassId: string = '5';
  @State items: AssignmentItem[] = [];
  @State loading: boolean = true;
  @State isTeacher: boolean = false;
  @State error: string = '';
  @State submitContent: string = '';
  @State title: string = '';
  @State deadline: string = '';
  @State maxScore: string = '100';
  @State content: string = '';

  async loadRole(): Promise<void> {
    try {
      let me = await CampusApi.me();
      let roleCodes = me.roles.map((role) => role.role_code);
      this.isTeacher = roleCodes.indexOf('TEACHER') >= 0;
    } catch (e) {
      // 身份加载失败时保持只读
    }
  }

  async loadAssignments(): Promise<void> {
    if (this.courseId.length === 0 || this.teachingClassId.length === 0) {
      promptAction.showToast({ message: '请填写课程ID和教学班ID' });
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      this.items = await CampusApi.assignments(this.courseId, this.teachingClassId);
    } catch (e) {
      let message = this.errorMessage(e, '作业列表加载失败');
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  async submit(assignmentId: string): Promise<void> {
    if (this.submitContent.trim().length === 0) {
      promptAction.showToast({ message: '请填写提交内容' });
      return;
    }
    try {
      await CampusApi.submitAssignment(assignmentId, this.submitContent.trim());
      promptAction.showToast({ message: '作业已提交' });
      this.submitContent = '';
    } catch (e) {
      this.showError(e, '作业提交失败');
    }
  }

  async createAssignment(): Promise<void> {
    if (this.courseId.length === 0 || this.teachingClassId.length === 0 ||
      this.title.trim().length === 0 || this.deadline.length === 0) {
      promptAction.showToast({ message: '请填写课程、教学班、作业标题和截止时间' });
      return;
    }
    try {
      let body: Record<string, Object> = {
        'teaching_class_id': this.teachingClassId,
        'assignment_title': this.title.trim(),
        'content': this.content,
        'deadline': this.deadline,
        'max_score': this.maxScore,
        'allow_late': 0,
        'publish_status': 1
      };
      await CampusApi.createAssignment(this.courseId, body);
      promptAction.showToast({ message: '作业已发布' });
      this.title = '';
      this.content = '';
      this.deadline = '';
      await this.loadAssignments();
    } catch (e) {
      this.showError(e, '作业发布失败');
    }
  }

  showError(e: Object, defaultMessage: string): void {
    let message = this.errorMessage(e, defaultMessage);
    promptAction.showToast({ message: message });
  }

  errorMessage(e: Object, defaultMessage: string): string {
    let message = defaultMessage;
    if (e instanceof ApiException) {
      message = e.message;
    }
    return message;
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
      Text('作业')
        .fontSize(AppTheme.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Column({ space: 10 }) {
        Row({ space: 8 }) {
          TextInput({ placeholder: '课程ID', text: this.courseId })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(AppTheme.COLOR_CARD)
            .borderRadius(AppTheme.RADIUS_BUTTON)
            .onChange((value: string) => {
              this.courseId = value;
            })
          TextInput({ placeholder: '教学班ID', text: this.teachingClassId })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(AppTheme.COLOR_CARD)
            .borderRadius(AppTheme.RADIUS_BUTTON)
            .onChange((value: string) => {
              this.teachingClassId = value;
            })
          Button('查询')
            .height(40)
            .backgroundColor(AppTheme.COLOR_PRIMARY)
            .onClick(() => {
              this.loadAssignments();
            })
        }
        .width('100%')
      }
      .padding(AppTheme.SPACE_SECTION)
      .width('100%')
      .borderRadius(AppTheme.RADIUS_CARD)
      .backgroundColor(AppTheme.COLOR_CARD)

      Text('作业列表')
        .fontSize(AppTheme.FONT_SECTION)
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
              this.loadAssignments();
            })
        }
        .padding(AppTheme.SPACE_ITEM)
        .width('100%')
        .borderRadius(AppTheme.RADIUS_CARD)
        .backgroundColor(AppTheme.COLOR_CARD)
      } else if (this.loading) {
        Text('加载中...').fontSize(14).fontColor('#666666')
      } else if (this.items.length === 0) {
        Text('暂无作业').fontSize(14).fontColor('#999999')
      } else {
        ForEach(this.items, (item: AssignmentItem) => {
          Column({ space: 6 }) {
            Row() {
              Text(item.assignment_title)
                .fontSize(AppTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text(`${item.max_score}分`)
                .fontSize(AppTheme.FONT_CAPTION)
                .fontColor(AppTheme.COLOR_PRIMARY)
            }
            .width('100%')
            Text(`截止 ${formatDateTime(item.deadline)}`)
              .fontSize(AppTheme.FONT_CAPTION)
              .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
            Text(item.content ?? '')
              .fontSize(13)
              .fontColor('#1F1F1F')
              .maxLines(3)
            TextInput({ placeholder: '提交内容', text: this.submitContent })
              .height(56)
              .onChange((value: string) => {
                this.submitContent = value;
              })
            Button('提交作业')
              .height(32)
              .fontSize(12)
              .onClick(() => {
                this.submit(item.id);
              })
          }
          .padding(12)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_ITEM)
          .backgroundColor(AppTheme.COLOR_CARD)
        }, (item: AssignmentItem) => item.id)
      }

      if (this.isTeacher) {
        Column({ space: 10 }) {
          Text('发布作业')
            .fontSize(AppTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          TextInput({ placeholder: '作业标题', text: this.title })
            .height(40)
            .backgroundColor(AppTheme.COLOR_CARD)
            .borderRadius(AppTheme.RADIUS_BUTTON)
            .onChange((value: string) => {
              this.title = value;
            })
          TextInput({ placeholder: '截止时间 2026-09-20T23:59:00+08:00', text: this.deadline })
            .height(40)
            .backgroundColor(AppTheme.COLOR_CARD)
            .borderRadius(AppTheme.RADIUS_BUTTON)
            .onChange((value: string) => {
              this.deadline = value;
            })
          TextInput({ placeholder: '作业说明', text: this.content })
            .height(64)
            .backgroundColor(AppTheme.COLOR_CARD)
            .borderRadius(AppTheme.RADIUS_BUTTON)
            .onChange((value: string) => {
              this.content = value;
            })
          TextInput({ placeholder: '满分', text: this.maxScore })
            .height(40)
            .backgroundColor(AppTheme.COLOR_CARD)
            .borderRadius(AppTheme.RADIUS_BUTTON)
            .onChange((value: string) => {
              this.maxScore = value;
            })
          Button('发布作业')
            .width('100%')
            .height(40)
            .backgroundColor(AppTheme.COLOR_PRIMARY)
            .onClick(() => {
              this.createAssignment();
            })
        }
        .padding(AppTheme.SPACE_SECTION)
        .width('100%')
        .borderRadius(AppTheme.RADIUS_CARD)
        .backgroundColor(AppTheme.COLOR_CARD)
      }
      }
      .padding(AppTheme.SPACE_PAGE)
      .width('100%')
      .backgroundColor(AppTheme.COLOR_BACKGROUND)
      .onAppear(() => {
        this.loadRole();
        this.loadAssignments();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.COLOR_BACKGROUND)
    .align(Alignment.Top)
  }
}
