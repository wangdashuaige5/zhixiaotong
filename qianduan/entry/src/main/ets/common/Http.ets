import { http } from '@kit.NetworkKit';
import { router } from '@kit.ArkUI';
import { AppConstants } from './Constants';

export interface ApiResult {
  code: number;
  message: string;
  data: Object;
  request_id?: string;
}

export class ApiException extends Error {
  code: number;

  constructor(code: number, message: string) {
    super(message);
    this.name = 'ApiException';
    this.code = code;
  }
}

export class HttpClient {
  private static refreshing: Promise<void> | null = null;
  private static sessionVersion: number = 0;
  private static redirecting: boolean = false;

  static getToken(): string {
    return AppStorage.get<string>(AppConstants.ACCESS_TOKEN_KEY) ?? '';
  }

  static getRefreshToken(): string {
    return AppStorage.get<string>(AppConstants.REFRESH_TOKEN_KEY) ?? '';
  }

  static setTokens(accessToken: string, refreshToken: string): void {
    // 功能：新登录开启新会话，旧会话未完成的刷新不得覆盖新账号。
    HttpClient.sessionVersion++;
    HttpClient.redirecting = false;
    HttpClient.refreshing = null;
    AppStorage.setOrCreate(AppConstants.ACCESS_TOKEN_KEY, accessToken);
    AppStorage.setOrCreate(AppConstants.REFRESH_TOKEN_KEY, refreshToken);
  }

  static clearTokens(): void {
    HttpClient.sessionVersion++;
    HttpClient.refreshing = null;
    AppStorage.setOrCreate(AppConstants.ACCESS_TOKEN_KEY, '');
    AppStorage.setOrCreate(AppConstants.REFRESH_TOKEN_KEY, '');
    AppStorage.setOrCreate(AppConstants.USER_NAME_KEY, '');
    AppStorage.setOrCreate('login_device_code', '');
    AppStorage.setOrCreate('attendance_device_id', '');
  }

  static async request(
    method: http.RequestMethod,
    path: string,
    body?: Object,
    query?: Map<string, string>
  ): Promise<ApiResult> {
    const isAuth = path.startsWith('/api/auth/');
    const version = HttpClient.sessionVersion;
    const originalToken = HttpClient.getToken();
    try {
      const result = await HttpClient.send(method, path, body, query);
      if (!isAuth && version !== HttpClient.sessionVersion) {
        throw new ApiException(409, '登录账号已变化，请重新加载页面');
      }
      return result;
    } catch (e) {
      // 功能：仅认证失败重试一次；网络错误/权限拒绝不重放写操作。
      if (isAuth || !(e instanceof ApiException) || e.code !== 401) {
        throw e instanceof ApiException ? e : new ApiException(0, '请求失败，请稍后重试');
      }
      if (version !== HttpClient.sessionVersion) { throw new ApiException(409, '登录账号已变化，请重新加载页面'); }
      try {
        if (originalToken === HttpClient.getToken()) { await HttpClient.refreshOnce(version); }
        if (version !== HttpClient.sessionVersion) { throw new ApiException(409, '登录账号已变化，请重新加载页面'); }
        const retried = await HttpClient.send(method, path, body, query);
        if (version !== HttpClient.sessionVersion) { throw new ApiException(409, '登录账号已变化，请重新加载页面'); }
        return retried;
      } catch (failure) {
        if (failure instanceof ApiException && failure.code === 401 && version === HttpClient.sessionVersion) {
          HttpClient.expireLogin();
        }
        throw failure instanceof ApiException ? failure : new ApiException(0, '请求失败，请稍后重试');
      }
    }
  }

  private static async refreshOnce(version: number): Promise<void> {
    // 功能：同时过期的多个请求共用一次刷新，避免服务端单次刷新凭据被重复使用。
    if (HttpClient.refreshing !== null) { return HttpClient.refreshing; }
    const pending = HttpClient.renewTokens(version);
    HttpClient.refreshing = pending;
    try { await pending; }
    finally { if (HttpClient.refreshing === pending) { HttpClient.refreshing = null; } }
  }

  private static async renewTokens(version: number): Promise<void> {
    const refreshToken = HttpClient.getRefreshToken();
    if (refreshToken.length === 0) { throw new ApiException(401, '登录已过期，请重新登录'); }
    const result = await HttpClient.send(http.RequestMethod.POST, '/api/auth/refresh',
      { 'refresh_token': refreshToken } as Record<string, string>);
    const pair = result.data as Record<string, Object>;
    const access = pair['access_token'];
    const refresh = pair['refresh_token'];
    if (typeof access !== 'string' || typeof refresh !== 'string' || !access || !refresh) {
      throw new ApiException(401, '登录凭据无效，请重新登录');
    }
    if (version !== HttpClient.sessionVersion) { throw new ApiException(409, '登录账号已变化，请重新加载页面'); }
    // 刷新仍是同一个用户会话，不清空已确认的签到设备。
    AppStorage.setOrCreate(AppConstants.ACCESS_TOKEN_KEY, access);
    AppStorage.setOrCreate(AppConstants.REFRESH_TOKEN_KEY, refresh);
  }

  private static expireLogin(): void {
    HttpClient.clearTokens();
    if (HttpClient.redirecting) { return; }
    HttpClient.redirecting = true;
    router.replaceUrl({ url: AppConstants.PAGE_LOGIN }).catch(() => {
      HttpClient.redirecting = false;
    });
  }

  private static async send(
    method: http.RequestMethod, path: string, body?: Object, query?: Map<string, string>
  ): Promise<ApiResult> {
    let url = AppConstants.BASE_URL + path;
    if (query !== undefined && query.size > 0) {
      let parts: string[] = [];
      query.forEach((value: string, key: string) => {
        parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
      });
      url = `${url}?${parts.join('&')}`;
    }

    let header: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    let token = HttpClient.getToken();
    if (token.length > 0 && path !== '/api/auth/login' && path !== '/api/auth/refresh') {
      header['Authorization'] = `Bearer ${token}`;
    }

    let options: http.HttpRequestOptions = {
      method: method,
      header: header,
      connectTimeout: 10000,
      readTimeout: 30000
    };
    if (body !== undefined) {
      options.extraData = JSON.stringify(body);
    }

    // 每次请求独立创建并销毁连接对象，允许多个页面并行查询。
    const client = http.createHttp();
    let response: http.HttpResponse;
    try { response = await client.request(url, options); }
    catch (e) { throw new ApiException(0, '网络连接失败，请检查后端服务和模拟器端口转发'); }
    finally { client.destroy(); }
    let text: string = '';
    if (typeof response.result === 'string') {
      text = response.result;
    } else {
      throw new ApiException(response.responseCode, '响应类型不支持');
    }

    let parsed: ApiResult;
    try {
      parsed = JSON.parse(text) as ApiResult;
    } catch (e) {
      throw new ApiException(response.responseCode, '服务器响应异常，请稍后重试');
    }

    if (response.responseCode === 401) { throw new ApiException(401, parsed.message || '请重新登录'); }
    if (response.responseCode < 200 || response.responseCode >= 300) {
      throw new ApiException(response.responseCode, parsed.message || '请求失败');
    }
    if (parsed.code !== 0) {
      throw new ApiException(parsed.code, parsed.message);
    }
    return parsed;
  }

  static get(path: string, query?: Map<string, string>): Promise<ApiResult> {
    return HttpClient.request(http.RequestMethod.GET, path, undefined, query);
  }

  static post(path: string, body?: Object): Promise<ApiResult> {
    return HttpClient.request(http.RequestMethod.POST, path, body, undefined);
  }

  static put(path: string, body?: Object): Promise<ApiResult> {
    return HttpClient.request(http.RequestMethod.PUT, path, body, undefined);
  }

  static delete(path: string): Promise<ApiResult> {
    return HttpClient.request(http.RequestMethod.DELETE, path, undefined, undefined);
  }
}
