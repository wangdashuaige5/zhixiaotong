export class AppConstants {
  static readonly BASE_URL: string = 'http://172.16.30.110:8080';
  static readonly ACCESS_TOKEN_KEY: string = 'access_token';
  static readonly REFRESH_TOKEN_KEY: string = 'refresh_token';
  static readonly USER_NAME_KEY: string = 'user_name';
  static readonly PAGE_HOME: string = 'pages/HomePage';
  static readonly PAGE_LOGIN: string = 'pages/LoginPage';
  static readonly PAGE_MAIN: string = 'pages/MainPage';
  static readonly PAGE_CAMPUS: string = 'pages/CampusPage';
  static readonly PAGE_TIMETABLE: string = 'pages/TimetablePage';
  static readonly PAGE_COURSES: string = 'pages/CoursesPage';
  static readonly PAGE_GRADES: string = 'pages/GradesPage';
  static readonly PAGE_LEAVE: string = 'pages/LeavePage';
  static readonly PAGE_CARD: string = 'pages/CampusCardPage';
  static readonly PAGE_LIBRARY: string = 'pages/LibraryPage';
  static readonly PAGE_NOTICES: string = 'pages/NoticesPage';
  static readonly PAGE_MESSAGES: string = 'pages/MessagesPage';
  static readonly PAGE_PROFILE: string = 'pages/ProfilePage';
  static readonly PAGE_ADMIN: string = 'pages/AdminPage';
  static readonly PAGE_ATTENDANCE: string = 'pages/AttendancePage';
  static readonly PAGE_ASSIGNMENTS: string = 'pages/AssignmentsPage';
  static readonly PAGE_EXAMS: string = 'pages/ExamsPage';
  static readonly PAGE_APPROVALS: string = 'pages/ApprovalsPage';
}

export class CommonText {
  static readonly NETWORK_ERROR: string = '网络请求失败，请检查后端服务';
  static readonly LOGIN_EXPIRED: string = '登录已过期，请重新登录';
}
