import 'package:ReceiveSMS/request/http_utils.dart';
import 'package:ReceiveSMS/utils/api.dart';
import 'package:ReceiveSMS/utils/tools.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';


void main() {
  runApp(const PrivacyView());
}

class PrivacyView extends StatelessWidget {
  const PrivacyView({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MyHomePage();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String html = '加载中'.tr + '...';
  @override
  void initState() {
    super.initState();
    try{
      HttpUtils.get(Api.baseUrl + '/privacy.html', options: buildCacheOptions(const Duration(days: 3))).then((response){
        setState(() {
          html = response;
        });
      }).catchError((e){
        //log('catchError');
      });
    } on DioError catch (e){
      //log('DioError = $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: html == '加载中'.tr + '...' ? Center(child: Text(html),) : content(),
    );
  }

  content() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: HtmlWidget(html),
      ),
    );
  }
}
