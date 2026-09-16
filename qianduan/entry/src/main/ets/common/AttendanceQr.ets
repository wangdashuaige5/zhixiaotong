// 二维码只传递现有签到接口需要的数据，不传登录令牌，不跳转任意网址。
export interface AttendanceQrPayload {
  type: string;
  version: number;
  task_id: string;
  sign_code: string;
  start_time: string;
  end_time: string;
}

export function parseAttendanceQr(raw: string): AttendanceQrPayload {
  if (raw.length === 0 || raw.length > 1024) {
    throw new Error('二维码内容无效，请扫描老师展示的智校通签到码');
  }
  let value: AttendanceQrPayload;
  try {
    value = JSON.parse(raw) as AttendanceQrPayload;
  } catch (e) {
    throw new Error('这不是智校通课堂签到二维码');
  }
  if (value === null || typeof value !== 'object' || value.type !== 'zhixiaotong.attendance' ||
    value.version !== 1 || typeof value.task_id !== 'string' || !/^[1-9][0-9]{0,18}$/.test(value.task_id) ||
    typeof value.sign_code !== 'string' || !/^[0-9]{6}$/.test(value.sign_code) ||
    typeof value.start_time !== 'string' || typeof value.end_time !== 'string') {
    throw new Error('签到二维码格式不正确');
  }
  let start = new Date(value.start_time).getTime();
  let end = new Date(value.end_time).getTime();
  if (!Number.isFinite(start) || !Number.isFinite(end) || end <= start) {
    throw new Error('签到二维码时间无效');
  }
  return value;
}

// 兼容原调用：安排时间与系统时间无关；开放状态、选课和设备由后端判断。
export function attendanceTimeError(value: AttendanceQrPayload, now: number): string {
  return '';
}
