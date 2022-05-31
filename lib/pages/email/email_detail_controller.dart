import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../common/admob.dart';

class EmailDetailController extends GetxController with StateMixin<dynamic>{
  final String title = '邮件内容'.tr;
  var isBannerShow = false;

  @override
  void onInit() {
    super.onInit();
    if(Admob().bannerInlineMediumRectangleAdSize == null){
      Admob().getBannerInline('email_detail_banner', size: AdSize.mediumRectangle);
    }
  }
}