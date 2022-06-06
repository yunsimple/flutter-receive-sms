import 'package:ReceiveSMS/utils/api.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import '../../common/auth.dart';
import '../../common/secure_storage.dart';
import '../../utils/tools.dart';


// 错误处理拦截器
class RequestInterceptor extends Interceptor {
  /// todo 对不需要access请求的接求进行处理
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {

    String? authorization = await Auth().getAuthorization();
    String? accessToken = await getAccessToken(options);

    Map<String, dynamic> headers = {
      'Access-Token': accessToken,
      'Authorization': authorization,
      'Language': Tools.getCurrentLanguage()
    };

    options.headers.addAll(headers);
    log(options.headers.toString());
    options = retry(options);
    return super.onRequest(options, handler);
  }

  Future<String?> getAccessToken(RequestOptions options) async {
    //如果accessToken不存在，就需要去请求
    String? accessToken = await SecureStorage().read('accessToken');
    accessToken ??= await Auth().getAccessToken();
    return accessToken;
  }

  // 哪些api不需要重试
  retry(RequestOptions options){
    List<String> noRetry = [
      'update',
      'notice',
      'new_phone',
    ];
    String apiName = options.path.replaceAll(options.baseUrl, '');
    if(noRetry.contains(apiName)){
      options.disableRetry = true;
    }
    return options;
  }

}
