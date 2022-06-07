import 'dart:io';
import 'dart:math';

import 'package:ReceiveSMS/utils/api.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
// 拦截器
import '../../request/interceptor/dio_logger.dart';
import '../../request/interceptor/error.dart';
import '../../request/interceptor/request.dart';
import '../../request/interceptor/response.dart';
import '../utils/config.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:dio_http_cache/dio_http_cache.dart';

class Http {
  static final Http _instance = Http._internal();
  factory Http() => _instance;

  static late final Dio dio;

  List<CancelToken?> pendingRequest = [];

  Http._internal() {
    // BaseOptions、Options、RequestOptions 都可以配置参数，优先级别依次递增，且可以根据优先级别覆盖参数
    BaseOptions options = BaseOptions();

    dio = Dio(options);

    //开启日志
    dio.interceptors.add(PrettyDioLogger());
    // 添加request拦截器
    dio.interceptors.add(RequestInterceptor());
    // 添加Response拦截器
    dio.interceptors.add(ResponseInterceptor());
    // 添加error拦截器
    dio.interceptors.add(ErrorInterceptor());
    // 添加重试retry拦截器
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: print, // specify log function (optional)
      retries: 3, // retry count (optional)
      retryDelays: const [
        // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));
    // 添加cache拦截器
    dio.interceptors.add(
        DioCacheManager(CacheConfig(baseUrl: Api.baseUrl, defaultMaxAge: const Duration(minutes: 30))).interceptor);

    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      print('Dio https 校验');
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  // 初始化公共属性
  // [baseUrl] 地址前缀
  // [connectTimeout] 连接超时赶时间
  // [receiveTimeout] 接收超时赶时间
  // [interceptors] 基础拦截器
  void init({
    String? baseUrl,
    int connectTimeout = HTTP_TIMEOUT,
    int receiveTimeout = HTTP_TIMEOUT,
    Map<String, String>? headers,
    List<Interceptor>? interceptors,
  }) {
    dio.options = dio.options.copyWith(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers ?? const {},
    );
    if (interceptors != null && interceptors.isNotEmpty) {
      dio.interceptors.addAll(interceptors);
    }
  }

  // 关闭所有 pending dio
  void cancelRequests() {
    pendingRequest.map((token) => token!.cancel('dio cancel'));
  }

  // 添加认证
  // 读取本地配置
  Map<String, dynamic>? getAuthorizationHeader() {
    Map<String, dynamic>? headers;
    // 从getx或者sputils中获取
    // String accessToken = Global.accessToken;
    // String accessToken = "";
    // if (accessToken != null) {
    //   headers = {
    //     'Authorization': 'Bearer $accessToken',
    //   };
    // }
    return headers;
  }

  // 获取cancelToken , 根据传入的参数查看使用者是否有动态传入cancel，没有就生成一个
  CancelToken createDioCancelToken(CancelToken? cancelToken) {
    CancelToken token = cancelToken ?? CancelToken();
    pendingRequest.add(token);
    return token;
  }

  Future get(
    String path, {
    Map<String, dynamic>? params,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    Options requestOptions = options ?? Options();
    Map<String, dynamic>? _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.copyWith(headers: _authorization);
    }
    Response response;
    CancelToken dioCancelToken = createDioCancelToken(cancelToken);
    response = await dio.get(
      path,
      queryParameters: params,
      options: requestOptions,
      cancelToken: dioCancelToken,
    );
    pendingRequest.remove(dioCancelToken);
    return response.data;
  }

  Future post(
    String path, {
    Map<String, dynamic>? params,
    data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    Options requestOptions = options ?? Options();
    Map<String, dynamic>? _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.copyWith(headers: _authorization);
    }
    CancelToken dioCancelToken = createDioCancelToken(cancelToken);
    var response = await dio.post(
      path,
      data: data,
      queryParameters: params,
      options: requestOptions,
      cancelToken: dioCancelToken,
    );
    pendingRequest.remove(dioCancelToken);
    return response.data;
  }

  Future put(
    String path, {
    data,
    Map<String, dynamic>? params,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    Options requestOptions = options ?? Options();

    Map<String, dynamic>? _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.copyWith(headers: _authorization);
    }
    CancelToken dioCancelToken = createDioCancelToken(cancelToken);
    var response = await dio.put(
      path,
      data: data,
      queryParameters: params,
      options: requestOptions,
      cancelToken: dioCancelToken,
    );
    pendingRequest.remove(dioCancelToken);
    return response.data;
  }

  Future patch(
    String path, {
    data,
    Map<String, dynamic>? params,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    Options requestOptions = options ?? Options();
    Map<String, dynamic>? _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.copyWith(headers: _authorization);
    }
    CancelToken dioCancelToken = createDioCancelToken(cancelToken);
    var response = await dio.patch(
      path,
      data: data,
      queryParameters: params,
      options: requestOptions,
      cancelToken: dioCancelToken,
    );
    pendingRequest.remove(dioCancelToken);
    return response.data;
  }

  Future delete(
    String path, {
    data,
    Map<String, dynamic>? params,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    Options requestOptions = options ?? Options();

    Map<String, dynamic>? _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.copyWith(headers: _authorization);
    }
    CancelToken dioCancelToken = createDioCancelToken(cancelToken);
    var response = await dio.delete(
      path,
      data: data,
      queryParameters: params,
      options: requestOptions,
      cancelToken: dioCancelToken,
    );
    pendingRequest.remove(dioCancelToken);
    return response.data;
  }
}
