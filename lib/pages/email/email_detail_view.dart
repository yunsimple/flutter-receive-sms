import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../common/admob.dart';
import '../../utils/tools.dart';
import 'package:get/get.dart';
import 'email_detail_controller.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class EmailDetailView extends GetView<EmailDetailController> {
  const EmailDetailView({Key? key}) : super(key: key);

  static const _insets = 16.0;
  double get _adWidth => MediaQuery.of(Get.context!).size.width - (2 * _insets);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> emailDetail = Get.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Text(
              emailDetail['subject'],
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(emailDetail['from']),
            Text(emailDetail['to']),
            Text(Tools.timeHandler(emailDetail['time'])),
            const SizedBox(height: 20),
            ad(),
            const SizedBox(height: 20),
            HtmlWidget(emailDetail['html'])
          ],
        ),
      ),
    );
  }

  /// 广告
  Widget ad() {
    if (Admob().bannerInlineMediumRectangleAdSize != null) {
      return Center(
        child: Container(
          color: Colors.transparent,
          width: _adWidth,
          height: Admob().bannerInlineMediumRectangleAdSize!.height.toDouble(),
          child: AdWidget(ad: Admob().bannerInlineMediumRectangleAd!),
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
