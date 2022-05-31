import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import '../../common/admob.dart';
import '../../request/http_utils.dart';
import '../../request/interceptor/api_request.dart';
import '../../utils/api.dart';
import '../../utils/tools.dart';
import 'package:get/get.dart';

class PhoneListController extends GetxController with StateMixin<dynamic> {
  final EasyRefreshController refreshController = EasyRefreshController();
  final ScrollController scrollController = ScrollController(); // 滚动
  var isShowFloatBtn = false.obs; // 是否显示返回顶部按钮
  String title = 'Country';
  RxList<dynamic> phoneList = RxList([]);
  int page = 1;
  dynamic countryID = 0;
  var isAdShowList = [].obs; // 控制原生广告显示列表
  List<int> insertIndex = [1, 4, 9]; //插入广告的下标,下标不能为8，不明所已
  int requestError = 0;

  @override
  void onInit() {
    log('PhoneListController onInit');
    super.onInit();
    if (Get.parameters['countryID'] != null) {
      title = Get.parameters['title']!;
      countryID = Get.parameters['countryID']!;
      phoneList.clear();
      fetchPhoneList(countryID: countryID);
    }
    _initScrollEvent();
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

/*  init(int cID, {String title = ''}){
    titleB = title;
    phoneList.clear();
    countryID = cID;
    fetchPhoneList(countryID: countryID);
  }*/

  //请求号码信息
  fetchPhoneList({required countryID, int page = 1}) async {
    try {
      Map<String, dynamic> data = {'country_id': countryID, 'page': page};
      await HttpUtils.post(Api.getPhone, data: data).then((response) async {
        requestError = 0;
        if (response['error_code'] == 0) {
          if (page == 1 && phoneList.isNotEmpty) {
            phoneList.clear();
            isAdShowList = [].obs;

          }
          var data = insertNativeAd(response['data']);
          phoneList.addAll(data);

          await Future.delayed(const Duration(milliseconds: 10));
          if (page == 1 && phoneList.isNotEmpty) {
            for (var value in insertIndex) {
              isAdShowList.add(value);
            }
            // phoneList.refresh();
          }
          change(phoneList, status: ApiRequest(response['error_code']).errorCode());
        } else {
          if (page > 1) {
            Tools.toast('全部加载完成'.tr, type: 'info');
          }
          if (phoneList.isEmpty) {
            change(phoneList, status: RxStatus.empty());
          }
        }
      }).catchError((e) {
        log('getPhoneList catchError 异常 = $e');
        error();
      });
    } on DioError catch (e) {
      log('getPhoneList DioError 异常 = $e');
      error();
    } catch (e) {
      log('getPhoneList 异常 = $e');
      error();
    }
  }

  /// 插入广告到列表
  insertNativeAd(List data) {
    /// todo 如果广告填充失败处理
    log("开始在号码中插入广告");
    //return data;
    var admob = Admob();
    int length = data.length;
    int lengthIndex = Tools.indexComputeAd(length, insertIndex);
    log('号码数量 = $length');

    /// 需要计算插入的数量
    for (var i = 0; i < length + lengthIndex; i++) {
      if (insertIndex.contains(i)) {
        log('i = $i 符合要求，插入广告');
        if (admob.preloadNativeAd.isNotEmpty) {
          String adKey = admob.preloadNativeAd.keys.toList()[0];
          data.insert(i, admob.preloadNativeAd[adKey]);
          admob.preloadNativeAd.remove(adKey);
        } else {
          log("原生广告缓存不存在，预加载3条");
          admob.getNativeAd('phone_list_native', number: 3);
        }
      }
    }
    return data;
  }

  // dio返回错误处理
  error() {
    if (phoneList.isEmpty) {
      if (requestError > 3) {
        change(null, status: RxStatus.error("请求失败".tr));
      } else {
        change(null, status: RxStatus.empty());
      }
    }
    requestError++;
  }
}
