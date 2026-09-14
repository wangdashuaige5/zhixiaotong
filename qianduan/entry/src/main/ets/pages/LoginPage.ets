import { promptAction, router } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { AppConstants } from '../common/Constants';
import { AppTheme } from '../common/Theme';
import { CampusApi } from '../services/Api';

@Entry
@Component
struct LoginPage {
  @State userName: string = 'student_demo';
  @State password: string = 'Demo@123456';
  @State deviceCode: string = 'demo-phone';
  @State loading: boolean = false;
  @State error: string = '';

  async login(): Promise<void> {
    if (this.userName.trim().length === 0 || this.password.length === 0) {
      this.error = '请输入账号和密码';
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      await CampusApi.login(this.userName.trim(), this.password, this.deviceCode);
      router.replaceUrl({ url: AppConstants.PAGE_MAIN });
    } catch (e) {
      let message = '登录失败';
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
      Stack() {
        Image($r('app.media.xiaoyuan'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(12)
          .colorBlend('#00000060')
        Column({ space: 16 }) {
          Column({ space: 20 }) {
            Row({ space: 20 }) {
              Image($r('app.media.logo1'))
                .width('15%')
              Text('智校通')
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.COLOR_PRIMARY)
            }

            Text('智慧校园综合服务平台')
              .fontSize(AppTheme.FONT_BODY)
              .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
          }
          .width('100%')
          .margin({ top: 28, bottom: 22 })

          Column({ space: 14 }) {
            TextInput({ placeholder: '账号', text: this.userName })
              .height(48)
              .backgroundColor(AppTheme.COLOR_CARD)
              .borderRadius(AppTheme.RADIUS_BUTTON)
              .onChange((value: string) => {
                this.userName = value;
              })

            TextInput({ placeholder: '密码', text: this.password })
              .type(InputType.Password)
              .height(48)
              .backgroundColor(AppTheme.COLOR_CARD)
              .borderRadius(AppTheme.RADIUS_BUTTON)
              .onChange((value: string) => {
                this.password = value;
              })

            if (this.error.length > 0) {
              Text(this.error)
                .fontSize(AppTheme.FONT_CAPTION)
                .fontColor(AppTheme.COLOR_DANGER)
                .width('100%')
            }

            Button(this.loading ? '登录中...' : '登录')
              .width('100%')
              .height(48)
              .fontSize(AppTheme.FONT_BODY)
              .backgroundColor(AppTheme.COLOR_PRIMARY)
              .enabled(!this.loading)
              .onClick(() => {
                this.login();
              })

          }
          .padding(20)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_CARD)
          .backgroundColor('#66FFFFFF')
        }
        .padding(AppTheme.SPACE_PAGE)
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)

      }.align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.COLOR_BACKGROUND)
    .align(Alignment.Top)
  }
}
