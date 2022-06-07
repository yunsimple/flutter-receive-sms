import 'dart:convert';
import 'dart:io';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import '../../common/auth.dart';
import '../../utils/tools.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

///改成单例
class TokenHttp {
  //创建dio实例
  Dio dio = Dio();

  TokenHttp() {
    // 在构造函数里面添加拦截器
    BaseOptions options = BaseOptions(
      connectTimeout: 10000,
      receiveTimeout: 10000,
    );
    dio = Dio(options);
    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async{
        log('TokenHttp 排除拦截 onRequest');
        log('TokenHttp 请求地址 = ${options.path}');
        handler.next(options);
      },
    ));
    // 添加重试retry拦截器
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: print, // specify log function (optional)
      retries: 5, // retry count (optional)
      retryDelays: const [ // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
        Duration(seconds: 3), // wait 3 sec before third retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      print('Dio https 校验');
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  //post方法
  Future post(path, data) async {
    Response resp;
    try {
      String? authorization = await Auth().getAuthorization();
      dio.options.headers = {
        'Authorization': authorization,
        'Language': Tools.getCurrentLanguage()
      };
      resp = await dio.post(path, data: data);
      log(resp.data);
      if (resp.statusCode == 200 && resp.data['error_code'] == 0) {
        String val = resp.toString();
        return jsonDecode(val);
      } else {
        String val = resp.toString();
        return jsonDecode(val);
      }
    } catch (error) {
      return error;
    }
  }

  Future put(path, data) async {
    Response resp;
    try {
      resp = await dio.put(path, data: data);
      if (resp.statusCode == 200) {
        String val = resp.toString();
        return jsonDecode(val);
      } else {
        String val = resp.toString();
        return jsonDecode(val);
      }
    } catch (error) {
      return error;
    }
  }

  //get方法 path和query参数
  Future get(path, query) async {
    Response resp;
    try {
      resp = await dio.get(path, queryParameters: query);

      if (resp.statusCode == 200) {
        String val = resp.toString();
        return jsonDecode(val);
      } else {
        String val = resp.toString();
        return jsonDecode(val);
      }
    } catch (error) {
      return error;
    }
  }

}
