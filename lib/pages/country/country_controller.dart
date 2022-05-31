import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import '../../request/http_utils.dart';
import '../../request/interceptor/api_request.dart';
import '../../utils/api.dart';
import '../../utils/tools.dart';
import 'package:get/get.dart';

class CountryController extends GetxController with StateMixin<dynamic> {
  final EasyRefreshController refreshController = EasyRefreshController();
  final ScrollController scrollController = ScrollController(); // 滚动
  final String title = '国家'.tr;
  int page = 1;
  List<dynamic> countryList = [].obs;
  var isAdShowList = [].obs; // 控制原生广告显示列表
  List<int> insertIndex = [2, 7]; //插入广告的下标,下标不能为8，不明所已
  int requestError = 0;
  var isShowFloatBtn = false.obs; // 是否显示返回顶部按钮

  @override
  void onInit() {
    fetchCountryList();
    _initScrollEvent();
    super.onInit();
  }

  @override
  onClose() {
    super.onClose();
    scrollController.dispose();
    refreshController.dispose();
  }

  void _initScrollEvent() {
    scrollController.addListener(() {
      if (scrollController.offset < 1000 && isShowFloatBtn.isTrue) {
        isShowFloatBtn.value = false;
      } else if (scrollController.offset >= 1000 && isShowFloatBtn.isFalse) {
        isShowFloatBtn.value = true;
      }
    });
  }

  fetchCountryList({int page = 1}) async {
    try {
      Map<String, dynamic> data = {'page': page};
      await HttpUtils.post(Api.getCountry, data: data).then((response) {
        requestError = 0;
        log('Country列表获取成功');
        if (response['error_code'] == 0) {
          if (page == 1 && countryList.isNotEmpty) {
            countryList.clear();
          }
          // 列表插入广告后合并
          var data = Tools.insertNativeAd(dataList: response['data'], insertIndex: insertIndex);
          countryList.addAll(data);

          change(countryList, status: ApiRequest(response['error_code']).errorCode());
        } else {
          Tools.toast('全部加载完成'.tr, type: 'info');
        }
      }).catchError((e) {
        log('getCountry catchError 异常 = $e');
        error();
      });
    } on DioError catch (e) {
      log('getCountry DioError 异常 = $e');
      error();
    } catch (e) {
      log('getCountry 异常 = $e');
      error();
    }
  }

  // dio返回错误处理
  error() {
    if (countryList.isEmpty) {
      if (requestError > 3) {
        change(null, status: RxStatus.error("请求失败".tr));
      } else {
        change(null, status: RxStatus.empty());
      }
    }
    requestError++;
  }
}
