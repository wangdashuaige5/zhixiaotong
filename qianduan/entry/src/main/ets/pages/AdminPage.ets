import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { AppTheme } from '../common/Theme';
import { CampusApi } from '../services/Api';
import { PaginationBar } from '../components/PaginationBar';

class AdminMenu {
  label: string;
  resource: string;

  constructor(label: string, resource: string) {
    this.label = label;
    this.resource = resource;
  }
}

@Entry
@Component
struct AdminPage {
  @State menus: AdminMenu[] = [
    new AdminMenu('学期', 'semesters'),
    new AdminMenu('课程', 'courses'),
    new AdminMenu('教学班', 'teaching-classes'),
    new AdminMenu('选课批次', 'selection-batches'),
    new AdminMenu('用户', 'users'),
    new AdminMenu('组织', 'orgs'),
    new AdminMenu('角色', 'roles'),
    new AdminMenu('权限', 'permissions'),
    new AdminMenu('教室', 'classrooms'),
    new AdminMenu('辅导员', 'counselors'),
    new AdminMenu('图书', 'books'),
    new AdminMenu('图书副本', 'book-copies'),
    new AdminMenu('考试', 'exams'),
    new AdminMenu('通知', 'notices'),
    new AdminMenu('消息', 'messages'),
    new AdminMenu('审计日志', 'audit')
  ];
  @State activeTitle: string = '';
  @State activeResource: string = '';
  @State pageNo: number = 1;
  @State total: number = 0;
  @State saving: boolean = false;
  @State rows: Object[] = [];
  @State tableColumns: string[] = [];
  @State tableKeys: string[] = [];
  @State loading: boolean = false;
  @State error: string = '';
  @State courseCode: string = '';
  @State courseName: string = '';
  @State courseType: string = '';
  @State courseCredit: string = '';
  @State courseHours: string = '';
  @State courseOrgId: string = '';
  @State bookCode: string = '';
  @State bookName: string = '';
  @State bookAuthor: string = '';
  @State bookCategory: string = '';
  @State bookPublisher: string = '';
  @State bookSummary: string = '';
  @State roomCode: string = '';
  @State roomName: string = '';
  @State campusName: string = '';
  @State buildingName: string = '';
  @State roomCapacity: string = '';
  @State counselorId: string = '';
  @State counselorClassId: string = '';
  @State counselorStart: string = '';
  @State counselorEnd: string = '';

  // 管理数据按资源独立翻页；切换菜单时回到第一页，并锁住并行切换。
  async loadResource(menu: AdminMenu, pageNo: number = 1): Promise<void> {
    if (this.loading) { return; }
    this.activeTitle = menu.label;
    this.activeResource = menu.resource; this.pageNo = pageNo; this.total = 0;
    this.loading = true;
    this.error = '';
    this.rows = [];
    this.setTableConfig(menu.resource);
    try {
      let items: Object[] = [];
      if (menu.resource === 'orgs') {
        items = await CampusApi.adminOrgs();
        this.total = items.length;
      } else if (menu.resource === 'users') {
        let page = await CampusApi.adminUsers(pageNo);
        items = page.items;
        this.total = Number(page.total);
      } else if (menu.resource === 'notices') {
        let page = await CampusApi.notices(pageNo);
        items = page.items;
        this.total = Number(page.total);
      } else if (menu.resource === 'messages') {
        let page = await CampusApi.messages(pageNo);
        items = page.items;
        this.total = Number(page.total);
      } else if (menu.resource === 'audit') {
        let page = await CampusApi.auditLogs(pageNo);
        items = page.items;
        this.total = Number(page.total);
      } else {
        let page = await CampusApi.adminData(menu.resource, pageNo);
        items = page.items;
        this.total = Number(page.total);
      }
      this.rows = items;
    } catch (e) {
      let message = '数据加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  loadActivePage(page: number): void {
    if (this.loading || this.saving || page < 1 || this.activeResource.length === 0) { return; }
    this.loadResource(new AdminMenu(this.activeTitle, this.activeResource), page);
  }

  setTableConfig(resource: string): void {
    if (resource === 'semesters') {
      this.tableColumns = ['ID', '学期名称', '开始日期', '结束日期', '周数', '当前'];
      this.tableKeys = ['id', 'semester_name', 'start_date', 'end_date', 'week_count', 'is_current'];
    } else if (resource === 'courses') {
      this.tableColumns = ['ID', '课程编码', '课程名称', '课程类型', '学分', '学时'];
      this.tableKeys = ['id', 'course_code', 'course_name', 'course_type', 'credit', 'total_hours'];
    } else if (resource === 'teaching-classes') {
      this.tableColumns = ['ID', '教学班', '课程ID', '教师ID', '容量', '已选'];
      this.tableKeys = ['id', 'class_name', 'course_id', 'teacher_id', 'capacity', 'enrolled_count'];
    } else if (resource === 'selection-batches') {
      this.tableColumns = ['ID', '批次名称', '阶段', '开始时间', '结束时间', '状态'];
      this.tableKeys = ['id', 'batch_name', 'batch_stage', 'start_time', 'end_time', 'batch_status'];
    } else if (resource === 'users') {
      this.tableColumns = ['ID', '账号', '姓名', '学工号', '组织ID', '状态'];
      this.tableKeys = ['id', 'user_name', 'real_name', 'user_no', 'org_id', 'user_status'];
    } else if (resource === 'orgs') {
      this.tableColumns = ['ID', '组织编码', '组织名称', '类型', '父级ID', '启用'];
      this.tableKeys = ['id', 'org_code', 'org_name', 'org_type', 'parent_id', 'is_enabled'];
    } else if (resource === 'roles') {
      this.tableColumns = ['ID', '角色编码', '角色名称', '范围', '启用'];
      this.tableKeys = ['id', 'role_code', 'role_name', 'scope_type', 'is_enabled'];
    } else if (resource === 'permissions') {
      this.tableColumns = ['ID', '权限编码', '权限名称', '类型', '启用'];
      this.tableKeys = ['id', 'permission_code', 'permission_name', 'permission_type', 'is_enabled'];
    } else if (resource === 'classrooms') {
      this.tableColumns = ['ID', '教室编码', '教室名称', '校区', '教学楼', '容量'];
      this.tableKeys = ['id', 'room_code', 'room_name', 'campus_name', 'building_name', 'capacity'];
    } else if (resource === 'counselors') {
      this.tableColumns = ['ID', '辅导员ID', '班级ID', '开始时间', '结束时间'];
      this.tableKeys = ['id', 'counselor_id', 'class_id', 'start_time', 'end_time'];
    } else if (resource === 'books') {
      this.tableColumns = ['ID', '图书编码', '书名', '作者', '分类'];
      this.tableKeys = ['id', 'book_code', 'book_name', 'author', 'category_code'];
    } else if (resource === 'book-copies') {
      this.tableColumns = ['ID', '图书ID', '副本号', '位置', '状态'];
      this.tableKeys = ['id', 'book_id', 'copy_no', 'location', 'copy_status'];
    } else if (resource === 'exams') {
      this.tableColumns = ['ID', '教学班ID', '考试名称', '开始时间', '结束时间', '状态'];
      this.tableKeys = ['id', 'teaching_class_id', 'exam_name', 'start_time', 'end_time', 'plan_status'];
    } else if (resource === 'notices') {
      this.tableColumns = ['ID', '通知标题', '紧急度', '置顶', '回执', '生效时间'];
      this.tableKeys = ['id', 'notice_title', 'urgency_level', 'is_pinned', 'need_ack', 'start_time'];
    } else if (resource === 'messages') {
      this.tableColumns = ['ID', '消息标题', '内容', '业务类型', '业务ID'];
      this.tableKeys = ['id', 'message_title', 'content', 'biz_type', 'biz_id'];
    } else if (resource === 'audit') {
      this.tableColumns = ['ID', '操作人', '动作', '业务类型', '业务ID', '时间'];
      this.tableKeys = ['id', 'operator_id', 'action_type', 'biz_type', 'biz_id', 'operate_time'];
    } else {
      this.tableColumns = ['ID'];
      this.tableKeys = ['id'];
    }
  }

  cellValue(item: Object, key: string): string {
    let record = item as Record<string, Object>;
    let value = record[key];
    if (value === undefined || value === null) {
      return '';
    }
    if (typeof value === 'string') {
      return value;
    }
    return JSON.stringify(value);
  }

  async saveCourse(): Promise<void> {
    if (this.saving || this.loading) { return; }
    if (this.courseCode.length === 0 || this.courseName.length === 0 || this.courseType.length === 0 ||
      this.courseCredit.length === 0 || this.courseHours.length === 0 || this.courseOrgId.length === 0) {
      promptAction.showToast({ message: '请填写课程完整信息' });
      return;
    }
    if (!/^\d+$/.test(this.courseHours) || Number(this.courseHours) <= 0 ||
      !/^\d+(\.\d{1,2})?$/.test(this.courseCredit) || Number(this.courseCredit) <= 0 ||
      !/^[1-9]\d*$/.test(this.courseOrgId)) {
      promptAction.showToast({ message: '学分应为正数，学时为正整数，组织 ID 请按组织列表填写' }); return;
    }
    this.saving = true;
    try {
      let body: Record<string, Object> = {
        'confirmed': true,
        'course_code': this.courseCode,
        'course_name': this.courseName,
        'course_type': this.courseType,
        'credit': this.courseCredit,
        'total_hours': parseInt(this.courseHours),
        'org_id': this.courseOrgId,
        'is_enabled': 1
      };
      await CampusApi.adminSave('courses', body);
      promptAction.showToast({ message: '课程已保存' });
      this.courseCode = '';
      this.courseName = '';
      this.courseType = '';
      this.courseCredit = '';
      this.courseHours = '';
      await this.loadResource(new AdminMenu('课程', 'courses'));
    } catch (e) {
      this.showError(e, '课程保存失败');
    } finally { this.saving = false; }
  }

  async saveBook(): Promise<void> {
    if (this.saving || this.loading) { return; }
    if (this.bookCode.length === 0 || this.bookName.length === 0 || this.bookAuthor.length === 0 ||
      this.bookCategory.length === 0) {
      promptAction.showToast({ message: '请填写图书完整信息' });
      return;
    }
    this.saving = true;
    try {
      let body: Record<string, Object> = {
        'confirmed': true,
        'book_code': this.bookCode,
        'book_name': this.bookName,
        'author': this.bookAuthor,
        'category_code': this.bookCategory,
        'publisher': this.bookPublisher,
        'summary': this.bookSummary
      };
      await CampusApi.adminSave('books', body);
      promptAction.showToast({ message: '图书已保存' });
      this.bookCode = '';
      this.bookName = '';
      this.bookAuthor = '';
      this.bookCategory = '';
      this.bookPublisher = '';
      this.bookSummary = '';
      await this.loadResource(new AdminMenu('图书', 'books'));
    } catch (e) {
      this.showError(e, '图书保存失败');
    } finally { this.saving = false; }
  }

  async saveClassroom(): Promise<void> {
    if (this.saving || this.loading) { return; }
    if (this.roomCode.length === 0 || this.roomName.length === 0 || this.campusName.length === 0 ||
      this.buildingName.length === 0 || this.roomCapacity.length === 0) {
      promptAction.showToast({ message: '请填写教室完整信息' });
      return;
    }
    if (!/^[1-9]\d*$/.test(this.roomCapacity)) {
      promptAction.showToast({ message: '教室容量必须是正整数' }); return;
    }
    this.saving = true;
    try {
      let body: Record<string, Object> = {
        'confirmed': true,
        'room_code': this.roomCode,
        'room_name': this.roomName,
        'campus_name': this.campusName,
        'building_name': this.buildingName,
        'capacity': parseInt(this.roomCapacity),
        'is_enabled': 1
      };
      await CampusApi.adminSave('classrooms', body);
      promptAction.showToast({ message: '教室已保存' });
      this.roomCode = '';
      this.roomName = '';
      this.campusName = '';
      this.buildingName = '';
      this.roomCapacity = '';
      await this.loadResource(new AdminMenu('教室', 'classrooms'));
    } catch (e) {
      this.showError(e, '教室保存失败');
    } finally { this.saving = false; }
  }

  async saveCounselor(): Promise<void> {
    if (this.saving || this.loading) { return; }
    if (this.counselorId.length === 0 || this.counselorClassId.length === 0 || this.counselorStart.length === 0) {
      promptAction.showToast({ message: '请填写辅导员、班级和开始时间' });
      return;
    }
    let start = new Date(this.counselorStart).getTime();
    let end = this.counselorEnd.length > 0 ? new Date(this.counselorEnd).getTime() : start + 1;
    if (!/^[1-9]\d*$/.test(this.counselorId) || !/^[1-9]\d*$/.test(this.counselorClassId) ||
      !Number.isFinite(start) || !Number.isFinite(end) || end <= start) {
      promptAction.showToast({ message: '请检查用户/班级 ID 和任职起止时间' }); return;
    }
    this.saving = true;
    try {
      let body: Record<string, Object> = {
        'confirmed': true,
        'counselor_id': this.counselorId,
        'class_id': this.counselorClassId,
        'start_time': this.counselorStart
      };
      if (this.counselorEnd.length > 0) {
        body['end_time'] = this.counselorEnd;
      }
      await CampusApi.adminSave('counselors', body);
      promptAction.showToast({ message: '辅导员任职已保存' });
      this.counselorId = '';
      this.counselorClassId = '';
      this.counselorStart = '';
      this.counselorEnd = '';
      await this.loadResource(new AdminMenu('辅导员', 'counselors'));
    } catch (e) {
      this.showError(e, '辅导员保存失败');
    } finally { this.saving = false; }
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
      Column({ space: AppTheme.SPACE_SECTION }) {
        Text('管理后台')
          .fontSize(AppTheme.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Column({ space: 10 }) {
          Text('数据查看')
            .fontSize(AppTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          Grid() {
            ForEach(this.menus, (menu: AdminMenu) => {
              GridItem() {
                Text(menu.label)
                  .fontSize(AppTheme.FONT_CAPTION)
                  .fontColor(this.activeTitle === menu.label ? '#FFFFFF' : AppTheme.COLOR_PRIMARY)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .height(34)
                  .backgroundColor(this.activeTitle === menu.label ? AppTheme.COLOR_PRIMARY : AppTheme.COLOR_CARD)
                  .borderRadius(AppTheme.RADIUS_BUTTON)
                  .border({ width: 1, color: AppTheme.COLOR_BORDER })
                  .enabled(!this.loading && !this.saving)
                  .onClick(() => {
                    this.loadResource(menu);
                  })
              }
            }, (menu: AdminMenu) => menu.resource)
          }
          .columnsTemplate('1fr 1fr 1fr')
          .width('100%')
        }
        .padding(AppTheme.SPACE_SECTION)
        .width('100%')
        .borderRadius(AppTheme.RADIUS_CARD)
        .backgroundColor(AppTheme.COLOR_CARD)

        if (this.activeTitle.length > 0) {
          Column({ space: 10 }) {
            Text(this.activeTitle)
              .fontSize(AppTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .width('100%')

            if (this.loading) {
              Text('加载中...')
                .fontSize(AppTheme.FONT_BODY)
                .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
            } else if (this.error.length > 0) {
              Text(this.error)
                .fontSize(AppTheme.FONT_BODY)
                .fontColor(AppTheme.COLOR_DANGER)
              Button('重新加载').enabled(!this.loading && !this.saving).onClick(() => this.loadActivePage(this.pageNo))
            } else if (this.rows.length === 0) {
              Text('暂无数据')
                .fontSize(AppTheme.FONT_BODY)
                .fontColor(AppTheme.COLOR_TEXT_TERTIARY)
            } else {
              Column({ space: 0 }) {
                Row() {
                  ForEach(this.tableColumns, (column: string, columnIndex: number) => {
                    Text(column)
                      .layoutWeight(1)
                      .fontSize(10)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppTheme.COLOR_TEXT_PRIMARY)
                      .textAlign(TextAlign.Center)
                      .padding({ top: 8, bottom: 8, left: 2, right: 2 })
                  }, (column: string, columnIndex: number) => `${columnIndex}`)
                }
                .width('100%')
                .backgroundColor(AppTheme.COLOR_PRIMARY_LIGHT)

                ForEach(this.rows, (item: Object, rowIndex: number) => {
                  Row() {
                    ForEach(this.tableColumns, (column: string, columnIndex: number) => {
                      Text(this.cellValue(item, this.tableKeys[columnIndex]))
                        .layoutWeight(1)
                        .fontSize(10)
                        .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
                        .textAlign(TextAlign.Center)
                        .maxLines(2)
                        .padding({ top: 8, bottom: 8, left: 2, right: 2 })
                    }, (column: string, columnIndex: number) => `${columnIndex}`)
                  }
                  .width('100%')
                  .border({ width: 0.5, color: AppTheme.COLOR_BORDER })
                }, (item: Object, rowIndex: number) => `${rowIndex}`)
              }
              .width('100%')
              .borderRadius(AppTheme.RADIUS_ITEM)
              .backgroundColor(AppTheme.COLOR_CARD)
            }
            if (this.activeResource !== 'orgs') {
              PaginationBar({ pageNo: this.pageNo, total: this.total, loading: this.loading || this.saving,
                onChange: (page: number) => this.loadActivePage(page) })
            } else { Text(`全部组织 · ${this.total} 条`).fontSize(12) }
          }
          .padding(AppTheme.SPACE_SECTION)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_CARD)
          .backgroundColor(AppTheme.COLOR_CARD)
        }

        if (this.activeTitle === '课程') {
          Column({ space: 10 }) {
            Text('新增课程')
              .fontSize(AppTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            TextInput({ placeholder: '课程编码', text: this.courseCode }).height(40).onChange((value: string) => { this.courseCode = value; })
            TextInput({ placeholder: '课程名称', text: this.courseName }).height(40).onChange((value: string) => { this.courseName = value; })
            TextInput({ placeholder: '课程类型', text: this.courseType }).height(40).onChange((value: string) => { this.courseType = value; })
            TextInput({ placeholder: '学分', text: this.courseCredit }).height(40).onChange((value: string) => { this.courseCredit = value; })
            TextInput({ placeholder: '总学时', text: this.courseHours }).height(40).onChange((value: string) => { this.courseHours = value; })
            TextInput({ placeholder: '组织ID', text: this.courseOrgId }).height(40).onChange((value: string) => { this.courseOrgId = value; })
            Button(this.saving ? '保存中…' : '保存课程').enabled(!this.saving && !this.loading).width('100%').height(40).backgroundColor(AppTheme.COLOR_PRIMARY).onClick(() => { this.saveCourse(); })
          }
          .enabled(!this.saving)
          .padding(AppTheme.SPACE_SECTION)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_CARD)
          .backgroundColor(AppTheme.COLOR_CARD)
        }

        if (this.activeTitle === '图书') {
          Column({ space: 10 }) {
            Text('新增图书')
              .fontSize(AppTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            TextInput({ placeholder: '图书编码', text: this.bookCode }).height(40).onChange((value: string) => { this.bookCode = value; })
            TextInput({ placeholder: '书名', text: this.bookName }).height(40).onChange((value: string) => { this.bookName = value; })
            TextInput({ placeholder: '作者', text: this.bookAuthor }).height(40).onChange((value: string) => { this.bookAuthor = value; })
            TextInput({ placeholder: '分类', text: this.bookCategory }).height(40).onChange((value: string) => { this.bookCategory = value; })
            TextInput({ placeholder: '出版社', text: this.bookPublisher }).height(40).onChange((value: string) => { this.bookPublisher = value; })
            TextInput({ placeholder: '简介', text: this.bookSummary }).height(64).onChange((value: string) => { this.bookSummary = value; })
            Button(this.saving ? '保存中…' : '保存图书').enabled(!this.saving && !this.loading).width('100%').height(40).backgroundColor(AppTheme.COLOR_PRIMARY).onClick(() => { this.saveBook(); })
          }
          .enabled(!this.saving)
          .padding(AppTheme.SPACE_SECTION)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_CARD)
          .backgroundColor(AppTheme.COLOR_CARD)
        }

        if (this.activeTitle === '教室') {
          Column({ space: 10 }) {
            Text('新增教室')
              .fontSize(AppTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            TextInput({ placeholder: '教室编码', text: this.roomCode }).height(40).onChange((value: string) => { this.roomCode = value; })
            TextInput({ placeholder: '教室名称', text: this.roomName }).height(40).onChange((value: string) => { this.roomName = value; })
            TextInput({ placeholder: '校区', text: this.campusName }).height(40).onChange((value: string) => { this.campusName = value; })
            TextInput({ placeholder: '教学楼', text: this.buildingName }).height(40).onChange((value: string) => { this.buildingName = value; })
            TextInput({ placeholder: '容量', text: this.roomCapacity }).height(40).onChange((value: string) => { this.roomCapacity = value; })
            Button(this.saving ? '保存中…' : '保存教室').enabled(!this.saving && !this.loading).width('100%').height(40).backgroundColor(AppTheme.COLOR_PRIMARY).onClick(() => { this.saveClassroom(); })
          }
          .enabled(!this.saving)
          .padding(AppTheme.SPACE_SECTION)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_CARD)
          .backgroundColor(AppTheme.COLOR_CARD)
        }

        if (this.activeTitle === '辅导员') {
          Column({ space: 10 }) {
            Text('新增辅导员任职')
              .fontSize(AppTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            TextInput({ placeholder: '辅导员用户ID', text: this.counselorId }).height(40).onChange((value: string) => { this.counselorId = value; })
            TextInput({ placeholder: '班级ID', text: this.counselorClassId }).height(40).onChange((value: string) => { this.counselorClassId = value; })
            TextInput({ placeholder: '开始时间 2026-09-01T08:00:00+08:00', text: this.counselorStart }).height(40).onChange((value: string) => { this.counselorStart = value; })
            TextInput({ placeholder: '结束时间 可空', text: this.counselorEnd }).height(40).onChange((value: string) => { this.counselorEnd = value; })
            Button(this.saving ? '保存中…' : '保存任职').enabled(!this.saving && !this.loading).width('100%').height(40).backgroundColor(AppTheme.COLOR_PRIMARY).onClick(() => { this.saveCounselor(); })
          }
          .enabled(!this.saving)
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.COLOR_BACKGROUND)
    .align(Alignment.Top)
  }
}
