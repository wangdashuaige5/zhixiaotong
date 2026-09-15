import { router } from '@kit.ArkUI';
import { AppConstants } from '../common/Constants';
import { AppTheme } from '../common/Theme';
import { CampusApi } from '../services/Api';
import { MessagesPage } from './MessagesPage';

// 首页聚合消息与校园通知；业务菜单、今日课程和查寝登记统一移至校园页。
@Component
export struct HomePage {
  @State userName: string = '';
  async loadUser(): Promise<void> {
    try {
      let me = await CampusApi.me();
      this.userName = me.real_name || me.user_name;
    } catch (e) {
      this.userName = '';
    }
  }

  build() {
    Column({ space: 10 }) {
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
        Text(this.userName.length > 0 ? `你好，${this.userName}` : '智校通')
          .fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('校园通知').height(36)
          .onClick(() => router.pushUrl({ url: AppConstants.PAGE_NOTICES }))
      }.width('100%').padding({ left: 20, right: 20 })
      // 直接复用消息列表和已读接口，不再保留重复的消息 Tab。
      MessagesPage().layoutWeight(1)
    }
    .width('100%').height('100%').padding({ top: 12 })
    .backgroundColor(AppTheme.COLOR_BACKGROUND)
    .onAppear(() => this.loadUser())
  }
}
