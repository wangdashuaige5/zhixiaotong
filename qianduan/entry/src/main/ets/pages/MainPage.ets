import { AppTheme } from '../common/Theme';
import { HomePage } from '../components/HomePage';
import { CampusPage } from '../components/CampusPage';
import { MessagesPage } from '../components/MessagesPage';
import { ProfilePage } from '../components/ProfilePage';
import { CampusApi } from '../services/Api';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  @State isCounselor: boolean = false;
  @State isAdmin: boolean = false;

  aboutToAppear(): void {
    this.loadRole();
  }

  async loadRole(): Promise<void> {
    try {
      let me = await CampusApi.me();
      let roleCodes = me.roles.map((role) => role.role_code);
      this.isCounselor = roleCodes.indexOf('COUNSELOR') >= 0;
      this.isAdmin = roleCodes.indexOf('ADMIN') >= 0;
    } catch (e) {
      // 加载失败时保留默认全部Tab
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.Start, index: this.currentIndex }) {
      TabContent() {
        HomePage()
      }
      .tabBar('首页')

      if (!this.isCounselor && !this.isAdmin) {
        TabContent() {
          CampusPage()
        }
        .tabBar('校园')
      }

      TabContent() {
        MessagesPage()
      }
      .tabBar('消息')

      TabContent() {
        ProfilePage()
      }
      .tabBar('我的')
    }
    .vertical(false)
    .barMode(BarMode.Fixed)
    .animationDuration(300)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.COLOR_BACKGROUND)
  }
}
