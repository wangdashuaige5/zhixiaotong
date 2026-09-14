export function formatDateTime(value?: string): string {
  if (value === undefined || value.length === 0) {
    return '';
  }
  return value.replace('T', ' ').substring(0, 16);
}

export function formatDate(value?: string): string {
  if (value === undefined || value.length === 0) {
    return '';
  }
  return value.substring(0, 10);
}

export function randomRequestKey(prefix: string): string {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
}

export function randomDeviceCode(): string {
  return `harmony-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
}

export function leaveStatusText(status: number): string {
  switch (status) {
    case 0:
      return '草稿';
    case 1:
      return '辅导员审批';
    case 2:
      return '院系审批';
    case 3:
      return '已通过';
    case 4:
      return '已驳回';
    case 5:
      return '已退回';
    case 6:
      return '已撤回';
    case 7:
      return '已销假';
    default:
      return '未知';
  }
}

export function enrollStatusText(status: number): string {
  switch (status) {
    case 0:
      return '待筛选';
    case 1:
      return '成功';
    case 2:
      return '未录取';
    case 3:
      return '已退选';
    default:
      return '未知';
  }
}

export function examFlagText(flag: number): string {
  switch (flag) {
    case 0:
      return '正常';
    case 1:
      return '缺考';
    case 2:
      return '缓考';
    case 3:
      return '免修';
    default:
      return '未知';
  }
}
