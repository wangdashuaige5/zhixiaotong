export interface PageData<T> {
  items: T[];
  // 后端 Long 序列化为字符串；分页比较时显式 Number(total)。
  total: number | string;
  page_no: number;
  page_size: number;
}

export interface RoleSummary {
  role_code: string;
  scope_type: number;
}

export interface UserInfo {
  id: string;
  user_name: string;
  real_name: string;
  user_no?: string;
  gender?: number;
  email?: string;
  phone?: string;
  org_id?: string;
  class_id?: string;
  avatar_id?: string;
  user_status?: number;
  roles: RoleSummary[];
  permissions: string[];
}

export interface TimetableItem {
  id: string;
  teaching_class_id: string;
  classroom_id: string;
  start_week: number;
  end_week: number;
  week_mode: number;
  week_day: number;
  start_period: number;
  end_period: number;
  start_time: string;
  end_time: string;
  class_name: string;
  course_id: string;
  course_name: string;
  room_name: string;
  teacher_name: string;
}

export interface TodayCard {
  timetables: TimetableItem[];
  pending_leaves: number;
  unread_messages: number;
  update_time: string;
}

export interface CourseOption {
  id: string;
  batch_id: string;
  teaching_class_id: string;
  admission_type: number;
  process_status?: number;
  class_name: string;
  capacity: number;
  enrolled_count: number;
  course_name: string;
  credit: string;
  teacher_name: string;
}

export interface EnrollmentItem {
  id: string;
  student_id: string;
  teaching_class_id: string;
  batch_course_id: string;
  enroll_status: number;
  result_note?: string;
  course_name: string;
  class_name: string;
  semester_id: string;
}

export interface AssignmentItem {
  id: string;
  teaching_class_id: string;
  assignment_title: string;
  content?: string;
  deadline: string;
  allow_late: number;
  publish_status: number;
  max_score: string;
}

export interface ExamItem {
  id: string;
  teaching_class_id: string;
  course_name: string;
  room_name: string;
  start_time: string;
  end_time: string;
  plan_status: number;
}

export interface SemesterItem {
  id: string;
  semester_name: string;
  start_date: string;
  end_date: string;
  week_count: number;
  is_current: number;
  is_locked: number;
}

export interface GradeItem {
  id: string;
  enrollment_id: string;
  usual_score?: string;
  final_score?: string;
  total_score?: string;
  grade_point?: string;
  exam_flag: number;
  publish_time?: string;
  course_name: string;
  credit: string;
  semester_id: string;
}

export interface LeaveItem {
  id: string;
  student_id: string;
  leave_type: string;
  start_time: string;
  end_time: string;
  leave_days: string;
  leave_reason: string;
  leave_status: number;
  apply_round: number;
  submit_time?: string;
  close_time?: string;
  approvals?: LeaveApprovalItem[];
}

export interface LeaveApprovalItem {
  id: string;
  leave_id: string;
  apply_round: number;
  node_order: number;
  node_type: number;
  approver_id: string;
  decision: number;
  opinion?: string;
  approve_time?: string;
}

export interface CardBalance {
  id: string;
  card_no: string;
  balance: string;
  account_status: number;
  sync_time?: string;
  integration_mode: string;
}

export interface CardTransaction {
  id: string;
  transaction_no: string;
  amount: string;
  transaction_type: number;
  balance_before: string;
  balance_after: string;
  transaction_time: string;
}

export interface RechargeOrder {
  id: string;
  order_no: string;
  amount: string;
  order_status: number;
  expire_time?: string;
  pay_time?: string;
  posted_time?: string;
}

export interface BookReservationItem {
  id: string;
  book_id: string;
  book_name: string;
  reserve_status: number;
  reserve_time: string;
  expire_time?: string;
}

export interface BookItem {
  id: string;
  book_code: string;
  book_name: string;
  author?: string;
  category_code?: string;
  available_count: number;
}

export interface BookLoanItem {
  id: string;
  book_id?: string;
  copy_id?: string;
  reader_id: string;
  borrow_time: string;
  due_time: string;
  renew_count: number;
  renew_time?: string;
  loan_status: number;
  book_name: string;
  copy_no: string;
}

export interface NoticeItem {
  id: string;
  notice_title: string;
  publisher_id: string;
  urgency_level: number;
  is_pinned: number;
  need_ack: number;
  start_time: string;
  expire_time?: string;
  publish_time?: string;
}

export interface MessageItem {
  id: string;
  message_title?: string;
  content?: string;
  delivery_status: number;
  read_time?: string | null;
  ack_time?: string | null;
}
