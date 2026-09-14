import { router } from '@kit.ArkUI';
import { AppConstants } from '../common/Constants';
import { AppTheme } from '../common/Theme';

@Entry
@Component
struct SplashPage {
  private timer: number = -1;

  aboutToAppear(): void {
    this.timer = setTimeout(() => {
     this.goLogin();
    }, 3000);
  }

  goLogin(): void {
    if (this.timer >= 0) {
      clearTimeout(this.timer);
      this.timer = -1;
    }
    router.replaceUrl({ url: AppConstants.PAGE_LOGIN });
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Image($r('app.media.xiaoyuan')) // 图片可以放在AppScope全局media或entry/media
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
      Column() {
        Text('燕山大学校园服务平台')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height('60%')
      .justifyContent(FlexAlign.Center)
      Column() {
        Blank().layoutWeight(1.2)
        Image($r('app.media.yanshandaxue'))
          .width(250)
          .objectFit(ImageFit.Contain)
        Blank().layoutWeight(0.5)
      }
      .width('100%')
      .height('100%')
      Button('跳过')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor(AppTheme.COLOR_PRIMARY_DARK)
        .borderRadius(AppTheme.RADIUS_BUTTON)
        .margin({ top: 24, right: 20 })
        .onClick(() => {
          this.goLogin();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.COLOR_PRIMARY)
  }
}
