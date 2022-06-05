import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import '../../common/remote_config.dart';
import '../../request/http_utils.dart';
import '../../request/interceptor/api_request.dart';
import '../../utils/api.dart';
import '../../utils/tools.dart';
import 'package:get/get.dart';

//如果需要更新广告，就不能使用GetX的StateMixin，否则可能不会生效
class PhoneListController extends GetxController with StateMixin<dynamic> {
  String title = '号码'.tr;
  dynamic countryID = 0;
  RxList<dynamic> phoneList = RxList([]);
  int page = 1;
  var isAdShowList = [].obs; // 控制原生广告显示列表
  List<int> insertIndex = [1, 4, 9]; //插入广告的下标,下标不能为8，不明所已
  int requestError = 0;
  final ScrollController scrollController = ScrollController(); // 滚动
  final EasyRefreshController refreshController = EasyRefreshController(); // 上下拉刷新
  var isShowFloatBtn = false.obs; // 是否显示返回顶部按钮
  double currentScroll = 0; // 当前滚动高度

  @override
  void onInit() {
    super.onInit();
    // remote config 远程获取原生广告下标
    String index = RemoteConfigApi().getJson('phone')['adPhoneNativeIndex'];
    if (index != '') {
      insertIndex = Tools.listStringTransitionInt(index.split(','));
    }

    if (Get.parameters['countryID'] != null) {
      title = Get.parameters['title']!;
      countryID = Get.parameters['countryID']!;
      phoneList.clear();
      fetchPhoneList(countryID: countryID);
    }
    _initScrollEvent(); // 监听滚动
  }


  @override
  onClose() {
    super.onClose();
    scrollController.dispose();
    refreshController.dispose();
  }

  void _initScrollEvent() {
    scrollController.addListener(() {
      currentScroll = scrollController.offset;
      if (scrollController.offset < 1000 && isShowFloatBtn.isTrue) {
        isShowFloatBtn.value = false;
      } else if (scrollController.offset >= 1000 && isShowFloatBtn.isFalse) {
        isShowFloatBtn.value = true;
      }
    });
  }

  //请求号码信息
  Future<bool> fetchPhoneList({required countryID, int page = 1}) async {
    try {
      Map<String, dynamic> data = {'country_id': countryID, 'page': page};
      return await HttpUtils.post(Api.getPhone, data: data).then((response) async {
        log('Phone 加载完成');
        requestError = 0;
        if (response['error_code'] == 0) {

          if (page == 1 && phoneList.isNotEmpty) {
            phoneList.clear();
            isAdShowList = [].obs;
          }
          List phoneListData = response["data"];
          phoneListData.sort((left, right){
            return right['last_time'].compareTo(left['last_time']);
          });
          var data = Tools.insertNativeAd(dataList: phoneListData, insertIndex: insertIndex);

          phoneList.addAll(data);

          /// todo 有一个检测widget(mounted)完成的方法，GetX里面需要找到替代的方法
          /// todo 这里强制性给每个广告位都显示，如果填充率不高的话，会有问题，还得优化
          await Future.delayed(const Duration(milliseconds: 50));
          if (page == 1 && phoneList.isNotEmpty) {
            for (var value in insertIndex) {
              isAdShowList.add(value);
            }
            // phoneList.refresh();
          }

          change(phoneList, status: ApiRequest(response['error_code']).errorCode());
        } else if (response['error_code'] == 3000) {
          if (page > 1) {
            Tools.toast('全部加载完成'.tr, type: 'info');
          }
        }
        return true;
      }).catchError((e) {
        log('getPhone catchError 异常 = $e');
        error();
        return false;
      });
    } on DioError catch (e) {
      log('getPhone DioError 异常 = $e');
      error();
      return false;
    } catch (e) {
      log('getPhone 异常 = $e');
      error();
      return false;
    }
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
