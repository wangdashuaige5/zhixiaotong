// 教学工作流共用的纯函数：课程来自服务端授权列表，表单不允许手填内部编号。
export interface TeachingClassChoice {
  id: string;
  class_name: string;
  course_id: string;
  course_name: string;
  teacher_id: string;
  teacher_name: string;
  semester_id: string;
  usual_weight?: string;
  final_weight?: string;
}

export function classChoiceLabel(item: TeachingClassChoice): string {
  return `${item.course_name} · ${item.class_name}`;
}

export function scoreInputError(value: string, max: number, required: boolean = true): string {
  if (value.trim().length === 0) { return required ? '请填写分数' : ''; }
  if (!/^\d+(\.\d{1,2})?$/.test(value.trim())) { return '分数须为非负数字，最多两位小数'; }
  const score = Number(value);
  return !Number.isFinite(score) || score < 0 || score > max ? `分数须在 0 至 ${max} 之间` : '';
}

export function submissionStateText(state: number): string {
  return ['待批改', '已退回，可重新提交', '已批改，待发布', '成绩已发布'][state] ?? '未知状态';
}

export function gradeStateText(state?: number): string {
  if (state === undefined || state === null) { return '未录入'; }
  return ['草稿', '待审核', '审核退回', '已发布'][state] ?? '未知状态';
}

export function teachingDate(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export function teachingTime(hour: number, minute: number): string {
  return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
}

export function assignmentDeadline(date: string, time: string, now: number): string {
  const result = `${date}T${time}:00+08:00`;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time) ||
    !Number.isFinite(Date.parse(result)) || Date.parse(result) <= now) {
    throw new Error('请选择当前时间之后的作业截止日期和时间');
  }
  return result;
}
