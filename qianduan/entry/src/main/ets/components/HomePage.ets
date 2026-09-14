import { promptAction, router } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { AppConstants } from '../common/Constants';
import { AppTheme } from '../common/Theme';
import { formatDateTime } from '../common/Utils';
import { CampusApi } from '../services/Api';
import { TimetableItem, TodayCard, UserInfo } from '../model/Models';

class MenuItem {
  label: string;
  page: string;

  constructor(label: string, page: string) {
    this.label = label;
    this.page = page;
  }
}

@Component
export struct HomePage {
  @State userName: string = '';
  @State roleText: string = '';
  @State today: TodayCard | null = null;
  @State loading: boolean = true;
  @State error: string = '';
  @State menuItems: MenuItem[] = [];
  @State isStudent: boolean = false;
  @State isTeacher: boolean = false;
  @State isCounselor: boolean = false;
  @State isDean: boolean = false;
  @State isAdmin: boolean = false;
  @State dormStudentId: string = '';
  @State dormLocation: string = '';
  @State dormCheckResult: string = '1';
  @State dormCheckTime: string = '';


  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      let me = await CampusApi.me();
      this.userName = me.real_name.length > 0 ? me.real_name : me.user_name;
      this.roleText = me.roles.map((role) => role.role_code).join('、');
      let roleCodes = me.roles.map((role) => role.role_code);
      this.isStudent = roleCodes.indexOf('STUDENT') >= 0;
      this.isTeacher = roleCodes.indexOf('TEACHER') >= 0;
      this.isCounselor = roleCodes.indexOf('COUNSELOR') >= 0;
      this.isDean = roleCodes.indexOf('DEAN') >= 0;
      this.isAdmin = roleCodes.indexOf('ADMIN') >= 0;
      this.menuItems = this.buildMenu();
      try {
        this.today = await CampusApi.today();
      } catch (e) {
        this.today = null;
      }
    } catch (e) {
      let message = '加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
    } finally {
      this.loading = false;
    }
  }

  buildMenu(): MenuItem[] {
    if (this.isStudent) {
      return [
        new MenuItem('课表', AppConstants.PAGE_TIMETABLE),
        new MenuItem('选课', AppConstants.PAGE_COURSES),
        new MenuItem('作业', AppConstants.PAGE_ASSIGNMENTS),
        new MenuItem('成绩', AppConstants.PAGE_GRADES),
        new MenuItem('请假', AppConstants.PAGE_LEAVE),
        new MenuItem('校园卡', AppConstants.PAGE_CARD),
        new MenuItem('图书', AppConstants.PAGE_LIBRARY),
        new MenuItem('通知', AppConstants.PAGE_NOTICES),
        new MenuItem('课堂签到', AppConstants.PAGE_ATTENDANCE)
      ];
    }
    if (this.isTeacher) {
      return [
        new MenuItem('课表', AppConstants.PAGE_TIMETABLE),
        new MenuItem('作业', AppConstants.PAGE_ASSIGNMENTS),
        new MenuItem('通知', AppConstants.PAGE_NOTICES),
        new MenuItem('发起签到', AppConstants.PAGE_ATTENDANCE)
      ];
    }
    if (this.isCounselor || this.isDean) {
      return [
        new MenuItem('待审批', AppConstants.PAGE_APPROVALS),
        new MenuItem('通知', AppConstants.PAGE_NOTICES),
        new MenuItem('校园卡', AppConstants.PAGE_CARD)
      ];
    }
    if (this.isAdmin) {
      return [
        new MenuItem('管理后台', AppConstants.PAGE_ADMIN),
        new MenuItem('通知', AppConstants.PAGE_NOTICES),
        new MenuItem('校园卡', AppConstants.PAGE_CARD)
      ];
    }
    return [
      new MenuItem('通知', AppConstants.PAGE_NOTICES),
      new MenuItem('校园卡', AppConstants.PAGE_CARD)
    ];
  }

  go(page: string): void {
    router.pushUrl({ url: page });
  }

  async logout(): Promise<void> {
    try {
      await CampusApi.logout();
    } catch (e) {
      // 退出接口失败也清理本地状态
    }
    router.replaceUrl({ url: AppConstants.PAGE_LOGIN });
  }

  async submitDormCheck(): Promise<void> {
    if (this.dormStudentId.length === 0 || this.dormLocation.length === 0 || this.dormCheckTime.length === 0) {
      promptAction.showToast({ message: '请填写学生、宿舍、检查结果和检查时间' });
      return;
    }
    try {
      let body: Record<string, Object> = {
        'student_id': this.dormStudentId,
        'dorm_location': this.dormLocation,
        'check_result': parseInt(this.dormCheckResult),
        'check_time': this.dormCheckTime
      };
      await CampusApi.dormCheck(body);
      promptAction.showToast({ message: '查寝记录已保存' });
      this.dormStudentId = '';
      this.dormLocation = '';
      this.dormCheckTime = '';
    } catch (e) {
      let message = '查寝登记失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      promptAction.showToast({ message: message });
    }
  }

  todayText(): string {
    let d = new Date();
    let m = d.getMonth() + 1 < 10 ? `0${d.getMonth() + 1}` : `${d.getMonth() + 1}`;
    let day = d.getDate() < 10 ? `0${d.getDate()}` : `${d.getDate()}`;
    return `${d.getFullYear()}-${m}-${day}`;
  }

  gridRows(): string {
    let count = Math.ceil(this.menuItems.length / 3);
    let parts: string[] = [];
    for (let i = 0; i < count; i++) {
      parts.push('1fr');
    }
    return parts.join(' ');
  }

  gridHeight(): number {
    return Math.ceil(this.menuItems.length / 3) * 84;
  }


  build() {
    Scroll() {
      Column({ space: 16 }) {
        Swiper() {
          Image($r('app.media.banner1'))
            .width('100%')
            .height(140)
            .objectFit(ImageFit.Cover)
            .borderRadius(AppTheme.RADIUS_CARD)
          Image($r('app.media.banner2'))
            .width('100%')
            .height(140)
            .objectFit(ImageFit.Cover)
            .borderRadius(AppTheme.RADIUS_CARD)
          Image($r('app.media.banner3'))
            .width('100%')
            .height(140)
            .objectFit(ImageFit.Cover)
            .borderRadius(AppTheme.RADIUS_CARD)
          Image($r('app.media.banner4'))
            .width('100%')
            .height(140)
            .objectFit(ImageFit.Cover)
            .borderRadius(AppTheme.RADIUS_CARD)
          Image($r('app.media.banner5'))
            .width('100%')
            .height(140)
            .objectFit(ImageFit.Cover)
            .borderRadius(AppTheme.RADIUS_CARD)
          Image($r('app.media.banner6'))
            .width('100%')
            .height(140)
            .objectFit(ImageFit.Cover)
            .borderRadius(AppTheme.RADIUS_CARD)
        }
        .loop(true)
        .autoPlay(true)
        .interval(3000)
        .indicator(true)
        .width('100%')
        .height(140)

        Row() {
          Column({ space: 4 }) {
            Text(this.userName.length > 0 ? `你好，${this.userName}` : '智校通')
              .fontSize(AppTheme.FONT_TITLE)
              .fontWeight(FontWeight.Bold)
            Text(this.roleText.length > 0 ? `身份：${this.roleText}` : this.loading ? '加载中...' : '欢迎使用')
              .fontSize(AppTheme.FONT_CAPTION)
              .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('退出')
            .height(34)
            .fontSize(AppTheme.FONT_CAPTION)
            .onClick(() => {
              this.logout();
            })
        }
        .width('100%')

        if (this.today !== null) {
          Column({ space: 10 }) {
            Row() {
              Text(`今日课程 ${this.todayText()}`)
                .fontSize(AppTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
              Blank()
              Text(`未读 ${this.today.unread_messages}`)
                .fontSize(AppTheme.FONT_CAPTION)
                .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
            }
            .width('100%')

            if (this.today.timetables.length === 0) {
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
          .padding(16)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_CARD)
          .backgroundColor(AppTheme.COLOR_CARD)
        }

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
          .padding(AppTheme.SPACE_ITEM)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_ITEM)
          .backgroundColor(AppTheme.COLOR_CARD)
        }

        Grid() {
          ForEach(this.menuItems, (item: MenuItem) => {
            GridItem() {
              Column({ space: 6 }) {
                Text(item.label)
                  .fontSize(AppTheme.FONT_SECTION)
                  .fontColor(AppTheme.COLOR_PRIMARY)
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height('100%')
              .borderRadius(AppTheme.RADIUS_ITEM)
              .backgroundColor(AppTheme.COLOR_CARD)
              .border({ width: 1, color: AppTheme.COLOR_BORDER })
              .onClick(() => {
                this.go(item.page);
              })
            }
          }, (item: MenuItem) => item.page)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsTemplate(this.gridRows())
        .height(this.gridHeight())
        .width('100%')

        if (this.isCounselor) {
          Column({ space: 10 }) {
            Text('查寝登记')
              .fontSize(AppTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            TextInput({ placeholder: '学生ID', text: this.dormStudentId })
              .height(40)
              .backgroundColor(AppTheme.COLOR_CARD)
              .borderRadius(AppTheme.RADIUS_BUTTON)
              .onChange((value: string) => {
                this.dormStudentId = value;
              })
            TextInput({ placeholder: '宿舍位置', text: this.dormLocation })
              .height(40)
              .backgroundColor(AppTheme.COLOR_CARD)
              .borderRadius(AppTheme.RADIUS_BUTTON)
              .onChange((value: string) => {
                this.dormLocation = value;
              })
            TextInput({ placeholder: '检查结果 1正常 2晚归 3未归 4已请假', text: this.dormCheckResult })
              .height(40)
              .backgroundColor(AppTheme.COLOR_CARD)
              .borderRadius(AppTheme.RADIUS_BUTTON)
              .onChange((value: string) => {
                this.dormCheckResult = value;
              })
            TextInput({ placeholder: '检查时间 2026-09-14T22:00:00+08:00', text: this.dormCheckTime })
              .height(40)
              .backgroundColor(AppTheme.COLOR_CARD)
              .borderRadius(AppTheme.RADIUS_BUTTON)
              .onChange((value: string) => {
                this.dormCheckTime = value;
              })
            Button('保存查寝记录')
              .width('100%')
              .height(40)
              .backgroundColor(AppTheme.COLOR_PRIMARY)
              .onClick(() => {
                this.submitDormCheck();
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
