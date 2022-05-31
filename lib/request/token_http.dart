import 'dart:convert';
import 'package:dio/dio.dart';
import '../../common/auth.dart';
import '../../utils/tools.dart';

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
        log('TokenHttp QueuedInterceptorsWrapper onRequest');
        handler.next(options);
      },
    ));
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
