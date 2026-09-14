import { http } from '@kit.NetworkKit';
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
  private static client: http.HttpRequest = http.createHttp();

  static getToken(): string {
    return AppStorage.get<string>(AppConstants.ACCESS_TOKEN_KEY) ?? '';
  }

  static getRefreshToken(): string {
    return AppStorage.get<string>(AppConstants.REFRESH_TOKEN_KEY) ?? '';
  }

  static setTokens(accessToken: string, refreshToken: string): void {
    AppStorage.setOrCreate(AppConstants.ACCESS_TOKEN_KEY, accessToken);
    AppStorage.setOrCreate(AppConstants.REFRESH_TOKEN_KEY, refreshToken);
  }

  static clearTokens(): void {
    AppStorage.setOrCreate(AppConstants.ACCESS_TOKEN_KEY, '');
    AppStorage.setOrCreate(AppConstants.REFRESH_TOKEN_KEY, '');
    AppStorage.setOrCreate(AppConstants.USER_NAME_KEY, '');
  }

  static async request(
    method: http.RequestMethod,
    path: string,
    body?: Object,
    query?: Map<string, string>
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
    if (token.length > 0) {
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

    let response: http.HttpResponse = await HttpClient.client.request(url, options);
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
      throw new ApiException(response.responseCode, text.length > 0 ? text : '响应解析失败');
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
