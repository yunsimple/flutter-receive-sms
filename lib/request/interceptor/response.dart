import 'package:dio/dio.dart';
import 'package:get/get.dart' as tr;
import '../../common/auth.dart';
import '../../common/remote_config.dart';
import '../../common/secure_storage.dart';
import '../../request/token_http.dart';
import '../../utils/config.dart';
import '../../common/local_storage.dart';
import '../../utils/tools.dart';

// 错误处理拦截器
class ResponseInterceptor extends QueuedInterceptorsWrapper {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    /// 根据api返回的expire时间来判断，如果时间不足，重新请求accessToken
    if(response.headers['expires'] != null && int.parse(response.headers['expires']![0]) < ACCESS_TOKEN_RESIDUE_TIME){
      log('access离过期不足10分钟,开始请求新的access token');
      Auth().getAccessToken();
    }

    /// access token 已经到期的情况
    if (response.data['error_code'] == 3001) {
      var options = response.requestOptions;
      //log('onResponse token不存在或已经过期，重新获取token');
      int? accessTokenExpire = LocalStorage().getInt('accessTokenExpire');
      int nowTime = DateTime.now().millisecondsSinceEpoch;
      String? accessToken = '';
      //print("$accessTokenExpire - $nowTime = ${accessTokenExpire! - nowTime}");

      if (accessTokenExpire != null && accessTokenExpire - nowTime > ACCESS_TOKEN_EXPIRE - 10000) {
        /// 如果短时间内同时请求，则放行
        //log('10秒内已经请求过，直接从缓存读取');
        accessToken = await SecureStorage().read('accessToken');
      } else {
        //log('result 301，需要重新获取accessToken');
        accessToken = await Auth().getAccessToken();
      }

      if (accessToken != null) {
        //log("新的accessToken $accessToken 新Dio重新发起失败的请求");
        options.headers['Access-Token'] = accessToken;
        //重复请求失败的请求
        Dio newDio = TokenHttp().dio;
        try {
          newDio.fetch(options).then((result) {
              handler.next(result);
            },
            onError: (e) {
              handler.next(e);
            },
          ).catchError((e) {
            //log('Response拦截器 catchError 拦截后，重复请求异常');
          });
        } on DioError catch (e) {
          //log('Response拦截器 DioError 拦截后，重复请求异常');
        } catch (e) {
          //log('Response拦截器 拦截后，重复请求异常');
        }
      }
      return;
    }
    // 累计请求数量
    LocalStorage().setIncr('requestNumber');

    return super.onResponse(response, handler);
  }

}
