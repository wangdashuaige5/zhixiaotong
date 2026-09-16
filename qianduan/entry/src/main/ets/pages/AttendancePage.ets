import { promptAction, router } from '@kit.ArkUI';
import { AppConstants } from '../common/Constants';
import { scanBarcode, scanCore, detectBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiException, HttpClient } from '../common/Http';
import { CampusApi } from '../services/Api';
import { SemesterItem, TimetableItem } from '../model/Models';
import { AttendanceQrPayload, parseAttendanceQr } from '../common/AttendanceQr';

interface AttendanceTaskResult {
  id: string;
  sign_code: string;
  start_time: string;
  end_time: string;
  task_status: number;
  reused?: boolean;
}
interface TrustedDevice { id: string; }
interface SignResult { sign_status: number; }

@Entry
@Component
struct AttendancePage {
  @State deviceId: string = '';
  @State devicePassword: string = '';
  @State timetableId: string = '';
  @State courses: TimetableItem[] = [];
  @State coursesLoading: boolean = false;
  @State coursesError: string = '';
  @State loadedDate: string = '';
  @State createdCourse: string = '';
  private courseRequest: number = 0;
  @State classDate: string = '';
  @State startTime: string = '';
  @State endTime: string = '';
  @State isStudent: boolean = false;
  @State isTeacher: boolean = false;
  @State loading: boolean = true;
  @State busy: boolean = false;
  @State error: string = '';
  @State qrValue: string = '';
  @State createdTask: AttendanceTaskResult | null = null;
  @State scanned: AttendanceQrPayload | null = null;
  @State signMessage: string = '';
  private roleUserId: string = '';

  aboutToAppear(): void {
    this.loadRole();
  }
  aboutToDisappear(): void {
    // 功能：离开页面后忽略未完成的课表请求。
    this.courseRequest++;
    this.devicePassword = '';
  }

  async loadRole(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      let me = await CampusApi.me();
      if (this.roleUserId !== me.id) {
        this.roleUserId = me.id;
        this.clearPublishedCode();
        this.loadedDate = '';
        this.scanned = null;
        this.signMessage = '';
      }
      let roles = me.roles.map((role) => role.role_code);
      this.isStudent = roles.indexOf('STUDENT') >= 0;
      this.isTeacher = roles.indexOf('TEACHER') >= 0;
      this.deviceId = AppStorage.get<string>('attendance_device_id') ?? '';
      if (this.isTeacher) {
        if (this.classDate.length === 0) {
          const today = new Date(Date.now() + 8 * 60 * 60 * 1000);
          this.classDate = today.toISOString().substring(0, 10);
        }
        // 从签到名单返回时保留本页仍有效的二维码，不将明文签到码持久化。
        if (this.loadedDate !== this.classDate || this.coursesLoading || this.coursesError.length > 0) {
          await this.loadCourses();
        }
      } else {
        this.clearPublishedCode();
        this.courses = [];
        this.timetableId = '';
      }
    } catch (e) {
      this.error = e instanceof ApiException ? e.message : '身份加载失败';
    } finally { this.loading = false; }
  }

  // 功能：调用已有设备接口绑定本次登录设备，不能使用写死的其他用户设备 ID。
  async trustDevice(): Promise<void> {
    if (this.busy) { return; }
    const code = AppStorage.get<string>('login_device_code') ?? '';
    if (code.length === 0) {
      promptAction.showToast({ message: '缺少本次登录设备标识，请退出后重新登录' });
      return;
    }
    if (this.devicePassword.length === 0) {
      promptAction.showToast({ message: '请输入当前账号密码以确认设备' });
      return;
    }
    this.busy = true;
    try {
      const body: Record<string, string> = { 'device_code': code, 'device_name': '智校通签到设备',
        'device_type': 'phone', 'password': this.devicePassword };
      const response = await HttpClient.post('/api/devices', body);
      const device = response.data as TrustedDevice;
      this.deviceId = device.id;
      AppStorage.setOrCreate('attendance_device_id', this.deviceId);
      promptAction.showToast({ message: '本次登录设备已确认，可以扫码签到' });
    } catch (e) {
      this.showError(e, '设备确认失败');
    } finally {
      this.devicePassword = '';
      this.busy = false;
    }
  }

  // 功能：系统扫码页支持相机与相册，不申请无关的存储或相机权限。
  async scanCamera(): Promise<void> {
    if (this.busy) { return; }
    if (!canIUse('SystemCapability.Multimedia.Scan.ScanBarcode')) {
      promptAction.showToast({ message: '当前设备不支持扫码，请使用支持 Scan Kit 的鸿蒙手机' });
      return;
    }
    this.busy = true;
    this.scanned = null;
    this.signMessage = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) { throw new Error('无法打开扫码页面，请重新进入'); }
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE], enableMultiMode: false, enableAlbum: true
      };
      const result = await scanBarcode.startScanForResult(context, options);
      this.acceptCode(result.originalValue);
    } catch (e) {
      if ((e as BusinessError).code !== 1000500002) {
        this.showError(e, '无法打开扫码，请在支持扫码的鸿蒙真机上重试');
      }
    } finally { this.busy = false; }
  }

  // 功能：独立的相册截图入口，只读取用户本次选择的图片，不上传图片。
  async scanAlbum(): Promise<void> {
    if (this.busy) { return; }
    if (!canIUse('SystemCapability.Multimedia.Scan.ScanBarcode')) {
      promptAction.showToast({ message: '当前设备不支持图片识码，请使用支持 Scan Kit 的鸿蒙手机' });
      return;
    }
    this.busy = true;
    this.scanned = null;
    this.signMessage = '';
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const selected = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1
      });
      if (selected.photoUris.length === 0) { return; }
      const results = await detectBarcode.decode({ uri: selected.photoUris[0] }, {
        scanTypes: [scanCore.ScanType.QR_CODE], enableMultiMode: true
      });
      let valid: AttendanceQrPayload[] = [];
      for (let i = 0; i < results.length; i++) {
        try {
          const code = parseAttendanceQr(results[i].originalValue);
          if (!valid.some((item: AttendanceQrPayload) =>
            item.task_id === code.task_id && item.sign_code === code.sign_code)) {
            valid.push(code);
          }
        } catch (e) { /* 忽略截图中其他非签到二维码，绝不打开其网址。 */ }
      }
      if (valid.length === 0) { throw new Error('图片中未识别到智校通签到码，请选择清晰截图'); }
      if (valid.length > 1) { throw new Error('图片含多个签到码，请裁剪到一个后重试'); }
      this.acceptCode(JSON.stringify(valid[0]));
    } catch (e) {
      this.showError(e, '截图识别失败，请换一张清晰图片');
    } finally { this.busy = false; }
  }

  acceptCode(raw: string): void {
    const code = parseAttendanceQr(raw);
    this.scanned = code;
    promptAction.showToast({ message: '已识别签到任务，请核对后确认签到' });
  }

  // 功能：学生确认后提交原签到接口；签到成功、迟到、重复签到均以服务端结果为准。
  async studentSign(): Promise<void> {
    if (this.busy || this.scanned === null) { return; }
    if (this.deviceId.length === 0) {
      promptAction.showToast({ message: '请先确认本次登录设备' });
      return;
    }
    const code = this.scanned;
    this.busy = true;
    try {
      const body: Record<string, string> = { 'sign_code': code.sign_code, 'device_id': this.deviceId };
      const response = await HttpClient.post(`/api/attendance/tasks/${code.task_id}/sign`, body);
      const result = response.data as SignResult;
      this.signMessage = result.sign_status === 2 ? '签到已记录（迟到）' : '签到已记录';
      this.scanned = null;
      promptAction.showToast({ message: this.signMessage });
    } catch (e) {
      // 信任被撤销后可重新验证设备；不绕过服务端的设备/选课/时间校验。
      if (e instanceof ApiException && e.message.indexOf('设备') >= 0) {
        this.deviceId = '';
        AppStorage.setOrCreate('attendance_device_id', '');
      }
      this.showError(e, '签到失败');
    } finally { this.busy = false; }
  }

  // 功能：与后端一致，以学期开始日期所在周的周一计算周次，不夹到首尾周。
  semesterWeek(semester: SemesterItem, date: string): number {
    const start = new Date(`${semester.start_date}T00:00:00Z`);
    const day = new Date(`${date}T00:00:00Z`);
    const monday = start.getTime() - ((start.getUTCDay() + 6) % 7) * 86400000;
    return Math.floor((day.getTime() - monday) / (7 * 86400000)) + 1;
  }

  courseMatches(item: TimetableItem, week: number, day: number): boolean {
    return item.week_day === day && week >= item.start_week && week <= item.end_week &&
      (item.week_mode === 1 || (item.week_mode === 2 && week % 2 === 1) ||
        (item.week_mode === 3 && week % 2 === 0));
  }

  clearPublishedCode(): void {
    this.qrValue = '';
    this.createdTask = null;
    this.createdCourse = '';
  }

  // 功能：复用课表页的接口，按日期对应学期/周次/星期/单双周加载真实排课。
  async loadCourses(): Promise<void> {
    if (this.busy) { return; }
    const request = ++this.courseRequest;
    const date = this.classDate;
    this.timetableId = '';
    this.courses = [];
    this.loadedDate = '';
    this.coursesError = '';
    this.clearPublishedCode();
    this.coursesLoading = true;
    try {
      const parsed = new Date(`${date}T00:00:00Z`);
      if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !Number.isFinite(parsed.getTime()) ||
        parsed.toISOString().substring(0, 10) !== date) {
        throw new Error('请选择有效的上课日期');
      }
      const semesters = await CampusApi.semesters();
      const day = parsed.getUTCDay() === 0 ? 7 : parsed.getUTCDay();
      let list: TimetableItem[] = [];
      let matched = false;
      for (const semester of semesters) {
        if (request !== this.courseRequest) { return; }
        const week = this.semesterWeek(semester, date);
        if (week < 1 || week > semester.week_count || !Number.isFinite(week)) { continue; }
        matched = true;
        const items = await CampusApi.timetables(semester.id, week);
        for (const item of items) {
          if (this.courseMatches(item, week, day) && !list.some((row: TimetableItem) => row.id === item.id)) {
            list.push(item);
          }
        }
      }
      if (request !== this.courseRequest || date !== this.classDate) { return; }
      this.courses = list;
      this.loadedDate = date;
      if (!matched) { this.coursesError = '所选日期不在已配置的学期教学周内，请重新选择日期'; }
    } catch (e) {
      if (request === this.courseRequest) {
        this.coursesError = e instanceof Error ? e.message : '课表加载失败，请重试';
      }
    } finally {
      if (request === this.courseRequest) { this.coursesLoading = false; }
    }
  }

  courseLabel(item: TimetableItem): string {
    return `${item.course_name} · ${item.class_name || '未提供教学班'}\n` +
      `第${item.start_period}—${item.end_period}节 ${item.start_time.substring(0, 5)}—${item.end_time.substring(0, 5)} · ${item.room_name || '未提供教室'}`;
  }

  // 功能：必须点选接口返回的排课；使用 timetable.id，绝不使用 course_id 或 teaching_class_id。
  selectCourse(id: string): void {
    if (this.busy || this.coursesLoading || this.loadedDate !== this.classDate) { return; }
    const course = this.courses.find((item: TimetableItem) => item.id === id);
    if (course === undefined) { return; }
    this.timetableId = course.id;
    this.startTime = course.start_time.substring(0, 5);
    this.endTime = course.end_time.substring(0, 5);
    this.clearPublishedCode();
  }

  async createTask(): Promise<void> {
    if (this.busy) { return; }
    const course = this.courses.find((item: TimetableItem) => item.id === this.timetableId);
    if (this.coursesLoading || this.coursesError.length > 0 || this.loadedDate !== this.classDate ||
      course === undefined || !/^[1-9][0-9]*$/.test(course.id)) {
      promptAction.showToast({ message: '请先选择日期，并从当天课表中选择签到课程' });
      return;
    }
    if (this.startTime.length === 0 || this.endTime.length === 0) {
      promptAction.showToast({ message: '请选择开始时间和截止时间' });
      return;
    }
    // 功能：时间来自所选课程/用户选择，仅校验先后关系，不与当前时间比较。
    const startIso = this.signDateTime(this.startTime);
    const endIso = this.signDateTime(this.endTime);
    const start = new Date(startIso).getTime();
    const end = new Date(endIso).getTime();
    if (!Number.isFinite(start) || !Number.isFinite(end) || end <= start) {
      promptAction.showToast({ message: '截止时间须晚于开始时间，请重新选择' });
      return;
    }
    if (end - start >= 4 * 60 * 60 * 1000) {
      promptAction.showToast({ message: '签到时长须小于4小时，请重新选择' });
      return;
    }
    this.busy = true;
    try {
      const body: Record<string, string> = { 'timetable_id': course.id,
        'class_date': this.classDate, 'start_time': startIso, 'end_time': endIso };
      const response = await HttpClient.post('/api/attendance/tasks', body);
      const task = response.data as AttendanceTaskResult;
      const payload: AttendanceQrPayload = { type: 'zhixiaotong.attendance', version: 1,
        task_id: task.id, sign_code: task.sign_code, start_time: task.start_time, end_time: task.end_time };
      const raw = JSON.stringify(payload);
      parseAttendanceQr(raw);
      this.createdTask = task;
      this.createdCourse = `${this.classDate}\n${this.courseLabel(course)}`;
      this.qrValue = raw;
      promptAction.showToast({ message: task.reused ? '已复用当天任务并更新二维码，签到记录保留' : '签到已开放，二维码已生成' });
    } catch (e) {
      this.showError(e, '创建签到失败');
    } finally { this.busy = false; }
  }

  teacherStatus(): string {
    if (this.createdTask === null) { return ''; }
    return this.createdTask.task_status === 2 ? '教师已结束签到' : '签到开放中（手动结束）';
  }

  async closeTask(): Promise<void> {
    if (this.busy || this.createdTask === null) { return; }
    this.busy = true;
    try {
      const answer = await promptAction.showDialog({ title: '结束本次签到', message: '结束后未签到学生不能再提交，已有记录保留。',
        buttons: [{text: '取消', color: '#666666'}, {text: '结束签到', color: '#D9534F'}] });
      if (answer.index !== 1) { return; }
      await HttpClient.post(`/api/attendance/tasks/${this.createdTask.id}/close`);
      this.createdTask.task_status = 2;
      this.qrValue = '';
      promptAction.showToast({ message: '签到已结束，已有记录保留' });
    } catch (e) { this.showError(e, '结束签到失败'); }
    finally { this.busy = false; }
  }

  padTime(value: number): string { return value < 10 ? `0${value}` : `${value}`; }

  signDateTime(time: string): string { return `${this.classDate}T${time}:00+08:00`; }

  // 功能：选择上课日期；只有点确定才回填，不修改已选开始/截止时分。
  pickClassDate(): void {
    if (this.busy) { return; }
    const selected = this.classDate.length > 0 ? new Date(`${this.classDate}T12:00:00`) : new Date();
    this.getUIContext().showDatePickerDialog({
      start: new Date(new Date().getFullYear() - 1, 0, 1),
      end: new Date(new Date().getFullYear() + 5, 11, 31),
      selected: selected,
      onAccept: (value: DatePickerResult) => {
        const year = value.year ?? selected.getFullYear();
        const month = value.month ?? selected.getMonth();
        const day = value.day ?? selected.getDate();
        this.classDate = `${year}-${this.padTime(month + 1)}-${this.padTime(day)}`;
        this.loadCourses();
      }
    });
  }

  // 功能：开始和截止分别选择时/分，使用24小时制，取消不改变已有值。
  pickSignTime(isStart: boolean): void {
    if (this.busy) { return; }
    const current = isStart ? this.startTime : this.endTime;
    const selected = new Date(2000, 0, 1, isStart ? 8 : 9, 0, 0);
    if (current.length > 0) {
      const parts = current.split(':');
      selected.setHours(parseInt(parts[0]), parseInt(parts[1]), 0, 0);
    }
    this.getUIContext().showTimePickerDialog({
      selected: selected,
      useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        const hour = value.hour ?? selected.getHours();
        const minute = value.minute ?? selected.getMinutes();
        const time = `${this.padTime(hour)}:${this.padTime(minute)}`;
        if (isStart) { this.startTime = time; } else { this.endTime = time; }
      }
    });
  }

  showError(e: Object, fallback: string): void {
    let message = fallback;
    if (e instanceof ApiException || e instanceof Error) { message = e.message; }
    promptAction.showToast({ message: message });
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('课堂二维码签到').fontSize(22).fontWeight(FontWeight.Bold).width('100%')
        if (this.error.length > 0) {
          Text(this.error).fontColor('#D9534F')
          Button('重新加载').onClick(() => this.loadRole())
        } else if (this.loading) {
          LoadingProgress().width(40).height(40)
        } else {
          // 多角色账号可同时看到教师和学生区域，避免 else-if 隐藏功能。
          if (this.isStudent) {
            Column({ space: 12 }) {
              Text('学生签到').fontSize(18).fontWeight(FontWeight.Bold)
              if (this.deviceId.length === 0) {
                Text('首次签到请确认本次登录设备').fontSize(14)
                TextInput({ placeholder: '当前账号密码', text: this.devicePassword })
                  .type(InputType.Password).height(44).enabled(!this.busy)
                  .onChange((value: string) => { this.devicePassword = value; })
                Button('确认本次登录设备').enabled(!this.busy).onClick(() => this.trustDevice())
              } else {
                Text('本次登录设备已确认').fontSize(13).fontColor('#2E7D32')
              }
              Button('相机扫码').width('100%').height(46)
                .enabled(!this.busy && this.deviceId.length > 0).onClick(() => this.scanCamera())
              Button('从相册识别截图').width('100%').height(46)
                .enabled(!this.busy && this.deviceId.length > 0).onClick(() => this.scanAlbum())
              Text('支持相机或相册截图。教师开放后可以签到，教师手动结束后停止接收。')
                .fontSize(12).fontColor('#666666')
              if (this.scanned !== null) {
                Text(`已识别任务：${this.scanned.task_id}`).fontSize(16)
                Text(`课程安排：${this.scanned.start_time} 至 ${this.scanned.end_time}`).fontSize(12)
                Button('确认签到').width('100%').enabled(!this.busy).onClick(() => this.studentSign())
                Button('取消本次扫描').enabled(!this.busy).onClick(() => { this.scanned = null; })
              }
              if (this.signMessage.length > 0) { Text(this.signMessage).fontColor('#2E7D32') }
            }.padding(16).width('100%').borderRadius(14).backgroundColor('#FFFFFF')
          }
          if (this.isTeacher) {
            Column({ space: 12 }) {
              Text('教师发起签到').fontSize(18).fontWeight(FontWeight.Bold)
              // 功能：三行可点击选择项代替手动输入日期时间字符串。
              Row({ space: 8 }) {
                Text('上课日期').fontSize(15).width(80)
                Text(this.classDate || '请选择日期').layoutWeight(1).textAlign(TextAlign.End).fontSize(15)
                Text('›').fontSize(26).fontColor('#666666')
              }.width('100%').height(56).padding(12).backgroundColor('#F5F7FB').borderRadius(8)
                .enabled(!this.busy).accessibilityText('选择上课日期').onClick(() => this.pickClassDate())
              Text('选择当天课表中的课程').fontSize(15).width('100%')
              if (this.coursesLoading) {
                LoadingProgress().width(32).height(32)
                Text('正在加载当天课表…').fontSize(13)
              } else if (this.coursesError.length > 0) {
                Text(this.coursesError).fontSize(13).fontColor('#D9534F')
              } else if (this.courses.length === 0) {
                Text('当天没有可选排课，请更换日期；如课表也没有课程，请联系管理员配置排课。')
                  .fontSize(13).fontColor('#666666')
              } else {
                ForEach(this.courses, (item: TimetableItem) => {
                  Column({ space: 4 }) {
                    Text(`${this.timetableId === item.id ? '● 已选择' : '○ 点击选择'}  ${this.courseLabel(item)}`)
                      .fontSize(14).width('100%')
                    Text(`排课编号：${item.id}`).fontSize(12).fontColor('#666666').width('100%')
                  }.width('100%').padding(12).borderRadius(8)
                    .backgroundColor(this.timetableId === item.id ? '#E5EAF6' : '#F5F7FB')
                    .enabled(!this.busy).onClick(() => this.selectCourse(item.id))
                }, (item: TimetableItem) => item.id)
              }
              Button('刷新当天课表').enabled(!this.busy && !this.coursesLoading)
                .onClick(() => this.loadCourses())
              Row({ space: 8 }) {
                Text('开始时间').fontSize(15).width(80)
                Text(this.startTime || '请选择时间').layoutWeight(1).textAlign(TextAlign.End).fontSize(15)
                Text('›').fontSize(26).fontColor('#666666')
              }.width('100%').height(56).padding(12).backgroundColor('#F5F7FB').borderRadius(8)
                .enabled(!this.busy).accessibilityText('选择签到开始时间').onClick(() => this.pickSignTime(true))
              Row({ space: 8 }) {
                Text('截止时间').fontSize(15).width(80)
                Text(this.endTime || '请选择时间').layoutWeight(1).textAlign(TextAlign.End).fontSize(15)
                Text('›').fontSize(26).fontColor('#666666')
              }.width('100%').height(56).padding(12).backgroundColor('#F5F7FB').borderRadius(8)
                .enabled(!this.busy).accessibilityText('选择签到截止时间').onClick(() => this.pickSignTime(false))
              Text('课程时间不与当前时间比较；同一天且截止晚于开始，时长小于4小时。发布即开放，结束需手动操作。重新发布会使旧二维码失效，但保留签到记录。')
                .fontSize(12).fontColor('#666666')
              Button(this.busy ? '处理中…' : '发布 / 重新生成签到码')
                .width('100%').height(44)
                .enabled(!this.busy && !this.coursesLoading && this.coursesError.length === 0 &&
                  this.timetableId.length > 0 && this.loadedDate === this.classDate)
                .onClick(() => this.createTask())
              if (this.createdTask !== null) {
                Text(this.createdCourse).fontSize(14)
                Text(`任务 ${this.createdTask.id} · ${this.teacherStatus()}`).fontSize(16)
                Button('查看签到记录').onClick(() => {
                  if (this.createdTask !== null) {
                    router.pushUrl({ url: AppConstants.PAGE_ATTENDANCE_RECORDS, params: { task_id: this.createdTask.id } });
                  }
                })
                if (this.createdTask.task_status !== 2 && this.qrValue.length > 0) {
                  // 白色留边提高相机与截图识别率；不使用外部二维码网站。
                  Column() {
                    QRCode(this.qrValue).width(240).height(240).color('#000000').backgroundColor('#FFFFFF')
                  }.padding(20).backgroundColor('#FFFFFF').border({ width: 1, color: '#E6E8EE' })
                  Button('结束本次签到').enabled(!this.busy).backgroundColor('#D9534F').onClick(() => this.closeTask())
                }
                Text(`课程安排：${this.createdTask.start_time} 至 ${this.createdTask.end_time}`).fontSize(12)
                Text('不依据手机当前时间隐藏二维码。请在签到完成后点击“结束本次签到”。')
                  .fontSize(12).fontColor('#666666')
              }
            }.padding(16).width('100%').borderRadius(14).backgroundColor('#FFFFFF')
          }
          if (!this.isStudent && !this.isTeacher) {
            Text('当前账号无课堂考勤操作权限').fontColor('#999999')
          }
        }
      }.padding(16).width('100%')
    }.width('100%').height('100%').backgroundColor('#F2F4F8')
  }
}
