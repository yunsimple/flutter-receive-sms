import 'package:dio/dio.dart';
import '../../common/auth.dart';
import '../../common/secure_storage.dart';
import '../../utils/tools.dart';


// 错误处理拦截器
class RequestInterceptor extends Interceptor {
  /// todo 对不需要access请求的接求进行处理
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    log('Dio网络请求 = ${options.uri}');

    String? authorization = await Auth().getAuthorization();
    String? accessToken = await getAccessToken(options);

    Map<String, dynamic> headers = {
      'Access-Token': accessToken,
      'Authorization': authorization,
      'Language': Tools.getCurrentLanguage()
    };

    options.headers.addAll(headers);
    log(options.headers.toString());
    return super.onRequest(options, handler);
  }

  Future<String?> getAccessToken(RequestOptions options) async {
    //如果accessToken不存在，就需要去请求
    String? accessToken = await SecureStorage().read('accessToken');
    accessToken ??= await Auth().getAccessToken();
    return accessToken;
  }

}
