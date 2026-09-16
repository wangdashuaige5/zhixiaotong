import { promptAction, router } from '@kit.ArkUI';
import { ApiException, HttpClient } from '../common/Http';
import { AppConstants } from '../common/Constants';
import { CampusApi } from '../services/Api';
import { UserInfo } from '../model/Models';

@Component
export struct ProfilePage {
  @State user: UserInfo | null = null;
  @State email: string = '';
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State error: string = '';
  @State loading: boolean = false;
  @State busy: boolean = false;
  @State editor: string = '';

  aboutToAppear(): void { this.loadData(); }
  aboutToDisappear(): void { this.clearPasswords(); this.editor = ''; }
  // 功能：统一各角色布局，展示中文身份，不暴露内部角色编码。
  roleName(code: string): string {
    const names: Record<string, string> = { 'STUDENT': '学生', 'TEACHER': '任课教师', 'COUNSELOR': '辅导员',
      'SECRETARY': '教学秘书', 'DEAN': '院系负责人', 'ADMIN': '管理员' };
    return names[code] ?? '其他角色';
  }
  roleText(): string { return this.user?.roles.map(role => this.roleName(role.role_code)).join(' · ') || '校园用户'; }
  numberLabel(): string { return this.user?.roles.some(role => role.role_code === 'STUDENT') ? '学号' : '工号'; }
  avatarText(): string { return this.user?.real_name?.substring(0, 1) || '智'; }
  clearPasswords(): void { this.oldPassword = ''; this.newPassword = ''; this.confirmPassword = ''; }
  async loadData(): Promise<void> {
    if (this.loading || this.busy) { return; }
    this.loading = true; this.error = '';
    try { this.user = await CampusApi.me(); this.email = this.user.email ?? ''; }
    catch (e) { this.user = null; this.error = this.errorMessage(e, '个人资料加载失败，请重试'); }
    finally { this.loading = false; }
  }
  toggleEditor(section: string): void {
    if (this.busy) { return; }
    this.clearPasswords(); this.email = this.user?.email ?? '';
    this.editor = this.editor === section ? '' : section;
  }
  async updateEmail(): Promise<void> {
    if (this.busy || this.user === null) { return; }
    const email = this.email.trim();
    if (email.length > 128 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      promptAction.showToast({message: '请输入正确的邮箱地址'}); return;
    }
    this.busy = true;
    try {
      const body: Record<string, string> = { 'email': email };
      this.user = await CampusApi.updateProfile(body); this.email = this.user.email ?? ''; this.editor = '';
      promptAction.showToast({message: '联系邮箱已更新'});
    } catch (e) { this.showError(e, '更新失败，请稍后重试'); }
    finally { this.busy = false; }
  }
  async changePassword(): Promise<void> {
    if (this.busy) { return; }
    if (!this.oldPassword || this.newPassword.length < 10 || this.newPassword.length > 128 ||
      !/[A-Za-z]/.test(this.newPassword) || !/[0-9]/.test(this.newPassword)) {
      promptAction.showToast({message: '请填写原密码，新密码须为10～128位且包含字母和数字'}); return;
    }
    if (this.newPassword !== this.confirmPassword) { promptAction.showToast({message: '两次新密码不一致'}); return; }
    this.busy = true;
    try {
      await CampusApi.changePassword(this.oldPassword, this.newPassword);
      this.clearPasswords(); HttpClient.clearTokens();
      promptAction.showToast({message: '密码已更新，请重新登录'});
      await router.replaceUrl({url: AppConstants.PAGE_LOGIN});
    } catch (e) { this.showError(e, '修改密码失败'); }
    finally { this.busy = false; }
  }
  async logout(): Promise<void> {
    if (this.busy) { return; }
    this.busy = true;
    try {
      const answer = await promptAction.showDialog({title: '退出登录', message: '确定退出当前账号吗？',
        buttons: [{text: '取消', color: '#64748B'}, {text: '退出', color: '#C53F50'}]});
      if (answer.index !== 1) { return; }
      try { await CampusApi.logout(); } catch (e) { HttpClient.clearTokens(); }
      this.clearPasswords(); this.user = null;
      await router.replaceUrl({url: AppConstants.PAGE_LOGIN});
    } catch (e) { this.showError(e, '退出失败，请重试'); }
    finally { this.busy = false; }
  }
  showError(e: Object, fallback: string): void { promptAction.showToast({message: this.errorMessage(e, fallback)}); }
  errorMessage(e: Object, fallback: string): string { return e instanceof ApiException ? e.message : fallback; }

  @Builder
  infoRow(label: string, value: string) {
    Row({space: 16}) {
      Text(label).fontSize(14).fontColor('#64748B').width(58)
      Text(value || '未填写').fontSize(15).fontColor('#25334D').layoutWeight(1).textAlign(TextAlign.End)
    }.width('100%').padding({top: 14, bottom: 14})
  }
  build() {
    Scroll() {
      Column({space: 20}) {
        Row() {
          Text('个人中心').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#17243F').layoutWeight(1)
          Button('刷新').type(ButtonType.Normal).fontSize(13).fontColor('#516488').backgroundColor('#E9EFF8')
            .borderRadius(12).height(32).enabled(!this.loading && !this.busy).onClick(() => this.loadData())
        }.width('100%')
        if (this.loading) { LoadingProgress().width(36).height(36) }
        if (this.error.length > 0) {
          Text(this.error).width('100%').padding(18).borderRadius(16).fontColor('#B43E50').backgroundColor('#FFF0F2')
        }
        if (this.user !== null) {
          // 功能：身份卡片集中展示头像、姓名、角色及账号状态。
          Column({space: 18}) {
            Row({space: 16}) {
              Text(this.avatarText()).width(64).height(64).textAlign(TextAlign.Center).fontSize(29)
                .fontWeight(FontWeight.Bold).fontColor('#FFFFFF').backgroundColor('#4869A8').borderRadius(22)
              Column({space: 7}) {
                Text(this.user.real_name).fontSize(23).fontWeight(FontWeight.Bold).fontColor('#FFFFFF').width('100%')
                Text(this.roleText()).fontSize(13).fontColor('#D6E4FF').width('100%')
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            }.width('100%')
            Divider().color('#48618E')
            Row() {
              Text('智校通 · 校园身份').fontSize(12).fontColor('#D6E4FF').layoutWeight(1)
              Text(this.user.user_status === 1 ? '账号正常' : '账号状态待确认').fontSize(12).fontColor('#FFFFFF')
            }.width('100%')
          }.padding(22).width('100%').borderRadius(22).backgroundColor('#294576')
          Column({space: 0}) {
            Text('基本资料').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#17243F').width('100%').margin({bottom: 6})
            this.infoRow('登录账号', this.user.user_name)
            Divider().color('#F0F3F8')
            this.infoRow(this.numberLabel(), this.user.user_no ?? '')
            Divider().color('#F0F3F8')
            this.infoRow('联系邮箱', this.user.email ?? '')
          }.padding(20).width('100%').borderRadius(20).backgroundColor('#FFFFFF')
          // 功能：编辑表单按需展开，主页不常驻密码输入框。
          Column({space: 0}) {
            Text('账号设置').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#17243F').width('100%').margin({bottom: 8})
            Row({space: 12}) {
              Text('@').fontSize(20).fontColor('#4169AC').width(36).height(36).textAlign(TextAlign.Center).backgroundColor('#EDF3FC').borderRadius(10)
              Column({space: 4}) {
                Text('联系邮箱').fontSize(15).fontColor('#25334D').width('100%')
                Text('管理账号的联系信息').fontSize(12).fontColor('#8290A5').width('100%')
              }.layoutWeight(1)
              Text(this.editor === 'email' ? '收起' : '修改 ›').fontSize(13).fontColor('#64748B')
            }.width('100%').padding({top: 14, bottom: 14}).enabled(!this.busy).onClick(() => this.toggleEditor('email'))
            if (this.editor === 'email') {
              Column({space: 12}) {
                TextInput({placeholder: '请输入联系邮箱', text: this.email}).type(InputType.Email).height(46).backgroundColor('#F3F6FB')
                  .enabled(!this.busy).onChange((value: string) => { this.email = value; })
                Button(this.busy ? '保存中…' : '保存邮箱').width('100%').height(44).backgroundColor('#3C65A8')
                  .enabled(!this.busy).onClick(() => this.updateEmail())
              }.padding({bottom: 16}).width('100%')
            }
            Divider().color('#F0F3F8')
            Row({space: 12}) {
              Text('安').fontSize(16).fontColor('#487B71').width(36).height(36).textAlign(TextAlign.Center).backgroundColor('#ECF7F3').borderRadius(10)
              Column({space: 4}) {
                Text('密码与安全').fontSize(15).fontColor('#25334D').width('100%')
                Text('修改密码后需要重新登录').fontSize(12).fontColor('#8290A5').width('100%')
              }.layoutWeight(1)
              Text(this.editor === 'password' ? '收起' : '管理 ›').fontSize(13).fontColor('#64748B')
            }.width('100%').padding({top: 14, bottom: 14}).enabled(!this.busy).onClick(() => this.toggleEditor('password'))
            if (this.editor === 'password') {
              Column({space: 12}) {
                TextInput({placeholder: '当前密码', text: this.oldPassword}).type(InputType.Password).height(46).backgroundColor('#F3F6FB')
                  .enabled(!this.busy).onChange((value: string) => { this.oldPassword = value; })
                TextInput({placeholder: '新密码：至少10位，含字母和数字', text: this.newPassword}).type(InputType.Password).height(46).backgroundColor('#F3F6FB')
                  .enabled(!this.busy).onChange((value: string) => { this.newPassword = value; })
                TextInput({placeholder: '再次输入新密码', text: this.confirmPassword}).type(InputType.Password).height(46).backgroundColor('#F3F6FB')
                  .enabled(!this.busy).onChange((value: string) => { this.confirmPassword = value; })
                Button('确认修改密码').width('100%').height(44).backgroundColor('#3C65A8').enabled(!this.busy).onClick(() => this.changePassword())
              }.padding({bottom: 12}).width('100%')
            }
          }.padding(20).width('100%').borderRadius(20).backgroundColor('#FFFFFF')
        }
        Button('退出当前账号').width('100%').height(48).fontSize(15).fontColor('#B84B5C').backgroundColor('#FFFFFF')
          .borderRadius(16).enabled(!this.busy).onClick(() => this.logout())
        Text('智校通  ·  连接学习与校园生活').fontSize(12).fontColor('#9AA6B8').margin({bottom: 14})
      }.padding({left: 20, right: 20, top: 24, bottom: 24}).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%').backgroundColor('#F3F6FB').align(Alignment.Top)
  }
}
