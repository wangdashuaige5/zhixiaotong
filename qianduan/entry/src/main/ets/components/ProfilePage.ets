import { promptAction, router } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { AppConstants } from '../common/Constants';
import { CampusApi } from '../services/Api';
import { UserInfo } from '../model/Models';
import { AppTheme } from '../common/Theme';
@Component
export struct ProfilePage {
  @State user: UserInfo | null = null;
  @State email: string = '';
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State error: string = '';

  async loadData(): Promise<void> {
    try {
      this.user = await CampusApi.me();
      this.email = this.user.email ?? '';
      this.error = '';
    } catch (e) {
      let message = this.errorMessage(e, '个人资料加载失败');
      this.error = message;
      promptAction.showToast({ message: message });
    }
  }

  async updateEmail(): Promise<void> {
    try {
      let body: Record<string, string> = {
        'email': this.email.trim()
      };
      await CampusApi.updateProfile(body);
      promptAction.showToast({ message: '邮箱已更新' });
      await this.loadData();
    } catch (e) {
      this.showError(e, '更新失败');
    }
  }

  async changePassword(): Promise<void> {
    if (this.oldPassword.length === 0 || this.newPassword.length < 10) {
      promptAction.showToast({ message: '请填写原密码，且新密码至少10位' });
      return;
    }
    try {
      await CampusApi.changePassword(this.oldPassword, this.newPassword);
      promptAction.showToast({ message: '密码已修改，请重新登录' });
      router.replaceUrl({ url: AppConstants.PAGE_LOGIN });
    } catch (e) {
      this.showError(e, '修改密码失败');
    }
  }

  async logout(): Promise<void> {
    try {
      await CampusApi.logout();
    } catch (e) {
      // 忽略退出接口错误
    }
    router.replaceUrl({ url: AppConstants.PAGE_LOGIN });
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
      Text('个人中心')
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
      }

      if (this.user !== null) {
        Column({ space: 8 }) {
          Text(this.user.real_name)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.COLOR_PRIMARY)
          Text(`账号 ${this.user.user_name}`)
            .fontSize(AppTheme.FONT_BODY)
            .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
          Text(`学工号 ${this.user.user_no ?? '--'}`)
            .fontSize(AppTheme.FONT_CAPTION)
            .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
          Text(`角色 ${this.user.roles.map((role) => role.role_code).join('、')}`)
            .fontSize(AppTheme.FONT_CAPTION)
            .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
        }
        .padding(AppTheme.SPACE_SECTION)
        .width('100%')
        .borderRadius(AppTheme.RADIUS_CARD)
        .backgroundColor(AppTheme.COLOR_CARD)
      }

      Column({ space: 10 }) {
        Text('邮箱')
          .fontSize(AppTheme.FONT_SECTION)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        Row({ space: 8 }) {
          TextInput({ placeholder: '邮箱', text: this.email })
            .layoutWeight(1)
            .height(42)
            .backgroundColor(AppTheme.COLOR_CARD)
            .borderRadius(AppTheme.RADIUS_BUTTON)
            .onChange((value: string) => {
              this.email = value;
            })
          Button('保存')
            .height(42)
            .backgroundColor(AppTheme.COLOR_PRIMARY)
            .onClick(() => {
              this.updateEmail();
            })
        }
        .width('100%')
      }
      .padding(AppTheme.SPACE_SECTION)
      .width('100%')
      .borderRadius(AppTheme.RADIUS_CARD)
      .backgroundColor(AppTheme.COLOR_CARD)

      Column({ space: 10 }) {
        Text('修改密码')
          .fontSize(AppTheme.FONT_SECTION)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        TextInput({ placeholder: '原密码', text: this.oldPassword })
          .type(InputType.Password)
          .height(42)
          .backgroundColor(AppTheme.COLOR_CARD)
          .borderRadius(AppTheme.RADIUS_BUTTON)
          .onChange((value: string) => {
            this.oldPassword = value;
          })
        TextInput({ placeholder: '新密码（至少10位，含字母和数字）', text: this.newPassword })
          .type(InputType.Password)
          .height(42)
          .backgroundColor(AppTheme.COLOR_CARD)
          .borderRadius(AppTheme.RADIUS_BUTTON)
          .onChange((value: string) => {
            this.newPassword = value;
          })
        Button('修改密码')
          .width('100%')
          .height(42)
          .backgroundColor(AppTheme.COLOR_PRIMARY)
          .onClick(() => {
            this.changePassword();
          })
      }
      .padding(AppTheme.SPACE_SECTION)
      .width('100%')
      .borderRadius(AppTheme.RADIUS_CARD)
      .backgroundColor(AppTheme.COLOR_CARD)

      Button('退出登录')
        .width('100%')
        .height(42)
        .fontColor(AppTheme.COLOR_DANGER)
        .backgroundColor(AppTheme.COLOR_CARD)
        .onClick(() => {
          this.logout();
        })
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
