import { HttpClient } from '../common/Http';
import {
  BookItem,
  BookLoanItem,
  BookReservationItem,
  RechargeOrder,
  AssignmentItem,
  CardBalance,
  CardTransaction,
  CourseOption,
  EnrollmentItem,
  ExamItem,
  GradeItem,
  LeaveItem,
  MessageItem,
  NoticeItem,
  PageData,
  SemesterItem,
  TimetableItem,
  TodayCard,
  UserInfo
} from '../model/Models';

function dataOf<T>(result: Object): T {
  return result as T;
}

// 用户接口的权限来自 SQL 行对象，统一映射为页面使用的权限编码数组。
// 同时兼容已经规范为字符串的服务端响应；缺失或异常条目不授予任何权限。
function userOf(result: Object): UserInfo {
  let user = dataOf<UserInfo>(result);
  let raw = (result as Record<string, Object>)['permissions'];
  let codes: string[] = [];
  if (Array.isArray(raw)) {
    (raw as Object[]).forEach((entry: Object) => {
      let code: string = '';
      if (typeof entry === 'string') {
        code = entry.trim();
      } else if (entry !== null && typeof entry === 'object') {
        let value = (entry as Record<string, Object>)['permission_code'];
        if (typeof value === 'string') { code = value.trim(); }
      }
      if (code.length > 0 && !codes.includes(code)) { codes.push(code); }
    });
  }
  user.permissions = codes;
  return user;
}

function pageQuery(pageNo: number = 1, pageSize: number = 20): Map<string, string> {
  let q = new Map<string, string>();
  q.set('page_no', `${pageNo}`);
  q.set('page_size', `${pageSize}`);
  return q;
}

export class CampusApi {
  static async login(userName: string, password: string, deviceCode: string): Promise<void> {
    let body: Record<string, string> = {
      'user_name': userName,
      'password': password,
      'device_code': deviceCode
    };
    let result = await HttpClient.post('/api/auth/login', body);
    let data = result.data as Record<string, Object>;
    let accessToken = data['access_token'] as string;
    let refreshToken = data['refresh_token'] as string;
    HttpClient.setTokens(accessToken, refreshToken);
    AppStorage.setOrCreate('user_name', userName);
    // 签到设备绑定必须使用与当前登录会话相同的设备标识，不保存密码。
    AppStorage.setOrCreate('login_device_code', deviceCode);
    AppStorage.setOrCreate('attendance_device_id', '');
  }

  static async logout(): Promise<void> {
    try {
      await HttpClient.post('/api/auth/logout', undefined);
    } finally {
      HttpClient.clearTokens();
      AppStorage.setOrCreate('login_device_code', '');
      AppStorage.setOrCreate('attendance_device_id', '');
    }
  }

  static async me(): Promise<UserInfo> {
    let result = await HttpClient.get('/api/users/me');
    return userOf(result.data);
  }

  static async today(): Promise<TodayCard> {
    let result = await HttpClient.get('/api/harmony/cards/today');
    return dataOf<TodayCard>(result.data);
  }

  static async timetables(semesterId?: string, weekNo?: number): Promise<TimetableItem[]> {
    let q = new Map<string, string>();
    if (semesterId !== undefined) {
      q.set('semester_id', semesterId);
    }
    if (weekNo !== undefined) {
      q.set('week_no', `${weekNo}`);
    }
    let result = await HttpClient.get('/api/timetables', q);
    return dataOf<TimetableItem[]>(result.data);
  }

  static async assignments(courseId: string, teachingClassId: string): Promise<AssignmentItem[]> {
    let q = new Map<string, string>();
    q.set('teaching_class_id', teachingClassId);
    let result = await HttpClient.get(`/api/courses/${courseId}/assignments`, q);
    return dataOf<AssignmentItem[]>(result.data);
  }

  static async submitAssignment(assignmentId: string, content: string): Promise<Object> {
    let body: Record<string, Object> = {
      'content': content,
      'file_ids': []
    };
    let result = await HttpClient.post(`/api/assignments/${assignmentId}/submissions`, body);
    return result.data;
  }

  static async createAssignment(courseId: string, body: Record<string, Object>): Promise<Object> {
    let result = await HttpClient.post(`/api/courses/${courseId}/assignments`, body);
    return result.data;
  }

  static async exams(semesterId?: string, pageNo: number = 1, pageSize: number = 20): Promise<PageData<ExamItem>> {
    let q = pageQuery(pageNo, pageSize);
    if (semesterId !== undefined) {
      q.set('semester_id', semesterId);
    }
    let result = await HttpClient.get('/api/exams/me', q);
    return dataOf<PageData<ExamItem>>(result.data);
  }

  static async pendingLeaves(): Promise<Object[]> {
    let result = await HttpClient.get('/api/leaves/pending', pageQuery());
    return dataOf<Object[]>(result.data);
  }

  static async approveLeave(id: string, body: Record<string, Object>): Promise<Object> {
    let result = await HttpClient.post(`/api/leaves/${id}/approve`, body);
    return result.data;
  }

  static async dormCheck(body: Record<string, Object>): Promise<Object> {
    let result = await HttpClient.post('/api/dorm-checks', body);
    return result.data;
  }

  static async semesters(): Promise<SemesterItem[]> {
    let result = await HttpClient.get('/api/semesters');
    return dataOf<SemesterItem[]>(result.data);
  }

  static async enrollmentBatches(): Promise<Object[]> {
    let result = await HttpClient.get('/api/enrollments/batches');
    return dataOf<Object[]>(result.data);
  }

  static async enrollmentOptions(batchId: string, keywords?: string, pageNo: number = 1, pageSize: number = 20): Promise<PageData<CourseOption>> {
    let q = pageQuery(pageNo, pageSize);
    q.set('batch_id', batchId);
    if (keywords !== undefined && keywords.length > 0) {
      q.set('keywords', keywords);
    }
    let result = await HttpClient.get('/api/enrollments/options', q);
    return dataOf<PageData<CourseOption>>(result.data);
  }

  static async myEnrollments(semesterId?: string, pageNo: number = 1, pageSize: number = 20): Promise<PageData<EnrollmentItem>> {
    let q = pageQuery(pageNo, pageSize);
    if (semesterId !== undefined) {
      q.set('semester_id', semesterId);
    }
    let result = await HttpClient.get('/api/enrollments/me', q);
    return dataOf<PageData<EnrollmentItem>>(result.data);
  }

  static async submitEnrollment(batchCourseId: string, requestKey: string): Promise<Object> {
    let body: Record<string, string> = {
      'batch_course_id': batchCourseId,
      'request_key': requestKey
    };
    let result = await HttpClient.post('/api/enrollments', body);
    return result.data;
  }

  static async dropEnrollment(id: string): Promise<Object> {
    let result = await HttpClient.delete(`/api/enrollments/${id}`);
    return result.data;
  }

  static async myGrades(semesterId?: string, pageNo: number = 1, pageSize: number = 20): Promise<PageData<GradeItem>> {
    let q = pageQuery(pageNo, pageSize);
    if (semesterId !== undefined) {
      q.set('semester_id', semesterId);
    }
    let result = await HttpClient.get('/api/grades/me', q);
    return dataOf<PageData<GradeItem>>(result.data);
  }

  static async myLeaves(pageNo: number = 1, pageSize: number = 20): Promise<PageData<LeaveItem>> {
    let result = await HttpClient.get('/api/leaves/me', pageQuery(pageNo, pageSize));
    return dataOf<PageData<LeaveItem>>(result.data);
  }

  static async createLeave(body: Record<string, Object>): Promise<LeaveItem> {
    let result = await HttpClient.post('/api/leaves', body);
    return dataOf<LeaveItem>(result.data);
  }

  static async leaveDetail(id: string): Promise<LeaveItem> {
    let result = await HttpClient.get(`/api/leaves/${id}`);
    return dataOf<LeaveItem>(result.data);
  }

  // 草稿和退回申请通过同一编辑接口保存或重新提交；审批轮次由后端管理。
  static async updateLeave(id: string, body: Record<string, Object>): Promise<LeaveItem> {
    let result = await HttpClient.put(`/api/leaves/${id}`, body);
    return dataOf<LeaveItem>(result.data);
  }

  static async withdrawLeave(id: string): Promise<Object> {
    let result = await HttpClient.post(`/api/leaves/${id}/withdraw`, undefined);
    return result.data;
  }

  static async closeLeave(id: string): Promise<Object> {
    let result = await HttpClient.post(`/api/leaves/${id}/close`, undefined);
    return result.data;
  }

  static async cardBalance(): Promise<CardBalance> {
    let result = await HttpClient.get('/api/cards/balance');
    return dataOf<CardBalance>(result.data);
  }

  static async cardTransactions(pageNo: number = 1, pageSize: number = 20): Promise<PageData<CardTransaction>> {
    let result = await HttpClient.get('/api/cards/transactions', pageQuery(pageNo, pageSize));
    return dataOf<PageData<CardTransaction>>(result.data);
  }

  // 仅创建待支付订单；支付回调验签和入账始终由服务端负责。
  static async recharge(amount: string, requestKey: string): Promise<RechargeOrder> {
    let body: Record<string, string> = {
      'amount': amount,
      'pay_channel': 'MOCK_PAY',
      'request_key': requestKey
    };
    let result = await HttpClient.post('/api/cards/recharges', body);
    return dataOf<RechargeOrder>(result.data);
  }

  static async rechargeOrder(id: string): Promise<RechargeOrder> {
    let result = await HttpClient.get(`/api/cards/recharges/${id}`);
    return dataOf<RechargeOrder>(result.data);
  }

  static async books(keywords: string, pageNo: number = 1, pageSize: number = 20): Promise<PageData<BookItem>> {
    let q = pageQuery(pageNo, pageSize);
    if (keywords.length > 0) {
      q.set('keywords', keywords);
    }
    let result = await HttpClient.get('/api/library/books', q);
    return dataOf<PageData<BookItem>>(result.data);
  }

  static async loans(pageNo: number = 1, pageSize: number = 20): Promise<PageData<BookLoanItem>> {
    let result = await HttpClient.get('/api/library/loans/me', pageQuery(pageNo, pageSize));
    return dataOf<PageData<BookLoanItem>>(result.data);
  }

  static async reserveBook(bookId: string, requestKey: string): Promise<Object> {
    let body: Record<string, string> = {
      'book_id': bookId,
      'request_key': requestKey
    };
    let result = await HttpClient.post('/api/library/reservations', body);
    return result.data;
  }

  static async renewLoan(id: string): Promise<Object> {
    let result = await HttpClient.post(`/api/library/loans/${id}/renew`, undefined);
    return result.data;
  }

  // 预约列表和取消均限定当前登录用户，沿用后端所有权校验。
  static async reservations(pageNo: number = 1, pageSize: number = 20): Promise<PageData<BookReservationItem>> {
    let result = await HttpClient.get('/api/library/reservations/me', pageQuery(pageNo, pageSize));
    return dataOf<PageData<BookReservationItem>>(result.data);
  }

  static async cancelReservation(id: string): Promise<void> {
    await HttpClient.delete(`/api/library/reservations/${id}`);
  }

  static async notices(pageNo: number = 1, pageSize: number = 20): Promise<PageData<NoticeItem>> {
    let result = await HttpClient.get('/api/notices', pageQuery(pageNo, pageSize));
    return dataOf<PageData<NoticeItem>>(result.data);
  }

  static async noticeDetail(id: string): Promise<Object> {
    let result = await HttpClient.get(`/api/notices/${id}`);
    return result.data;
  }

  static async messages(pageNo: number = 1, pageSize: number = 20): Promise<PageData<MessageItem>> {
    let result = await HttpClient.get('/api/messages', pageQuery(pageNo, pageSize));
    return dataOf<PageData<MessageItem>>(result.data);
  }

  static async adminOrgs(): Promise<Object[]> {
    let result = await HttpClient.get('/api/admin/orgs');
    return dataOf<Object[]>(result.data);
  }

  static async adminUsers(pageNo: number = 1, pageSize: number = 20): Promise<PageData<Object>> {
    let result = await HttpClient.get('/api/admin/users', pageQuery(pageNo, pageSize));
    return dataOf<PageData<Object>>(result.data);
  }

  static async adminData(resource: string, pageNo: number = 1, pageSize: number = 20): Promise<PageData<Object>> {
    let result = await HttpClient.get(`/api/admin/data/${resource}`, pageQuery(pageNo, pageSize));
    return dataOf<PageData<Object>>(result.data);
  }

  static async adminSave(resource: string, body: Record<string, Object>): Promise<Object> {
    let result = await HttpClient.post(`/api/admin/data/${resource}`, body);
    return result.data;
  }

  static async auditLogs(pageNo: number = 1, pageSize: number = 20): Promise<PageData<Object>> {
    let result = await HttpClient.get('/api/admin/audit-logs', pageQuery(pageNo, pageSize));
    return dataOf<PageData<Object>>(result.data);
  }

  static async updateProfile(body: Record<string, string>): Promise<UserInfo> {
    let result = await HttpClient.put('/api/users/profile', body);
    return userOf(result.data);
  }

  static async changePassword(oldPassword: string, newPassword: string): Promise<void> {
    let body: Record<string, string> = {
      'old_password': oldPassword,
      'new_password': newPassword
    };
    await HttpClient.put('/api/users/password', body);
  }
}
