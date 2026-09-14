import { HttpClient } from '../common/Http';
import {
  BookItem,
  BookLoanItem,
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
  }

  static async logout(): Promise<void> {
    await HttpClient.post('/api/auth/logout', undefined);
    HttpClient.clearTokens();
  }

  static async me(): Promise<UserInfo> {
    let result = await HttpClient.get('/api/users/me');
    return dataOf<UserInfo>(result.data);
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

  static async exams(semesterId?: string): Promise<PageData<ExamItem>> {
    let q = pageQuery();
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

  static async enrollmentOptions(batchId: string, keywords?: string): Promise<PageData<CourseOption>> {
    let q = pageQuery();
    q.set('batch_id', batchId);
    if (keywords !== undefined && keywords.length > 0) {
      q.set('keywords', keywords);
    }
    let result = await HttpClient.get('/api/enrollments/options', q);
    return dataOf<PageData<CourseOption>>(result.data);
  }

  static async myEnrollments(semesterId?: string): Promise<PageData<EnrollmentItem>> {
    let q = pageQuery();
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

  static async myGrades(semesterId?: string): Promise<PageData<GradeItem>> {
    let q = pageQuery();
    if (semesterId !== undefined) {
      q.set('semester_id', semesterId);
    }
    let result = await HttpClient.get('/api/grades/me', q);
    return dataOf<PageData<GradeItem>>(result.data);
  }

  static async myLeaves(): Promise<PageData<LeaveItem>> {
    let result = await HttpClient.get('/api/leaves/me', pageQuery());
    return dataOf<PageData<LeaveItem>>(result.data);
  }

  static async createLeave(body: Record<string, Object>): Promise<LeaveItem> {
    let result = await HttpClient.post('/api/leaves', body);
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

  static async cardTransactions(): Promise<PageData<CardTransaction>> {
    let result = await HttpClient.get('/api/cards/transactions', pageQuery());
    return dataOf<PageData<CardTransaction>>(result.data);
  }

  static async recharge(amount: string, requestKey: string): Promise<Object> {
    let body: Record<string, string> = {
      'amount': amount,
      'pay_channel': 'MOCK_PAY',
      'request_key': requestKey
    };
    let result = await HttpClient.post('/api/cards/recharges', body);
    return result.data;
  }

  static async books(keywords: string): Promise<PageData<BookItem>> {
    let q = pageQuery();
    if (keywords.length > 0) {
      q.set('keywords', keywords);
    }
    let result = await HttpClient.get('/api/library/books', q);
    return dataOf<PageData<BookItem>>(result.data);
  }

  static async loans(): Promise<PageData<BookLoanItem>> {
    let result = await HttpClient.get('/api/library/loans/me', pageQuery());
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

  static async notices(): Promise<PageData<NoticeItem>> {
    let result = await HttpClient.get('/api/notices', pageQuery());
    return dataOf<PageData<NoticeItem>>(result.data);
  }

  static async noticeDetail(id: string): Promise<Object> {
    let result = await HttpClient.get(`/api/notices/${id}`);
    return result.data;
  }

  static async messages(): Promise<PageData<MessageItem>> {
    let result = await HttpClient.get('/api/messages', pageQuery());
    return dataOf<PageData<MessageItem>>(result.data);
  }

  static async adminOrgs(): Promise<Object[]> {
    let result = await HttpClient.get('/api/admin/orgs');
    return dataOf<Object[]>(result.data);
  }

  static async adminUsers(pageNo: number = 1): Promise<PageData<Object>> {
    let result = await HttpClient.get('/api/admin/users', pageQuery(pageNo, 20));
    return dataOf<PageData<Object>>(result.data);
  }

  static async adminData(resource: string): Promise<PageData<Object>> {
    let result = await HttpClient.get(`/api/admin/data/${resource}`, pageQuery());
    return dataOf<PageData<Object>>(result.data);
  }

  static async adminSave(resource: string, body: Record<string, Object>): Promise<Object> {
    let result = await HttpClient.post(`/api/admin/data/${resource}`, body);
    return result.data;
  }

  static async auditLogs(): Promise<PageData<Object>> {
    let result = await HttpClient.get('/api/admin/audit-logs', pageQuery());
    return dataOf<PageData<Object>>(result.data);
  }

  static async updateProfile(body: Record<string, string>): Promise<UserInfo> {
    let result = await HttpClient.put('/api/users/profile', body);
    return dataOf<UserInfo>(result.data);
  }

  static async changePassword(oldPassword: string, newPassword: string): Promise<void> {
    let body: Record<string, string> = {
      'old_password': oldPassword,
      'new_password': newPassword
    };
    await HttpClient.put('/api/users/password', body);
  }
}
