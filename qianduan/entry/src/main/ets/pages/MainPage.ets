import { AppTheme } from '../common/Theme';
import { HomePage } from '../components/HomePage';
import { CampusPage } from '../components/CampusPage';
import { ProfilePage } from '../components/ProfilePage';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;

  build() {
    // 校园页对所有角色可见，内部按角色显示功能，避免管理员/辅导员迁移后找不到入口。
    Tabs({ barPosition: BarPosition.Start, index: this.currentIndex }) {
      TabContent() { HomePage() }.tabBar('首页')
      TabContent() { CampusPage() }.tabBar('校园')
      TabContent() { ProfilePage() }.tabBar('我的')
    }
    .vertical(false).barMode(BarMode.Fixed).animationDuration(300)
    .onChange((index: number) => { this.currentIndex = index; })
    .width('100%').height('100%').backgroundColor(AppTheme.COLOR_BACKGROUND)
  }
}
