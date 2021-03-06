import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:upgrader/upgrader.dart';
import '../../Routes.dart';
import '../../common/notice_bar.dart';
import '../../utils/api.dart';
import '../../utils/tools.dart';
import '../../widget/widget.dart';
import 'package:get/get.dart';
import 'phone_controller.dart';

class PhoneView extends GetView<PhoneController> {
  const PhoneView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.title,
          semanticsLabel: controller.title,
        ),
      ),
      body: Column(
        children: [
          getNotice(),
          Expanded(child: _phoneListView()),
        ],
      ),
      floatingActionButton: Obx(() {
        return controller.isShowFloatBtn.isFalse
            ? const SizedBox()
            : FloatingActionButton(
                onPressed: () async {
                  controller.scrollController.animateTo(
                    .0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                },
                tooltip: 'Top',
                child: const Icon(PhosphorIcons.arrow_fat_lines_up_fill),
                mini: true,
              );
      }),
    );
  }

  _phoneListView() {
    return controller.obx(
      (data) {
        return EasyRefresh(
          child: ListView.separated(
            itemCount: data.length,
            itemBuilder: (context, index) => phoneItem(context, index),
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(
                height: 10,
              );
            },
            controller: controller.scrollController,
          ),
          onRefresh: _onRefresh,
          onLoad: _onLoad,
        );
      },
      onEmpty: EasyRefresh(onRefresh: _onRefresh, child: emptyPageWidget(title: '????????????'.tr, subTitle: '??????????????????'.tr)),
      onError: (error) => EasyRefresh(
          onRefresh: _onRefresh, child: emptyPageWidget(title: '????????????'.tr, subTitle: '??????????????????'.tr, image: 'error')),
    );
  }

  Widget phoneItem(BuildContext context, int index) {
    if (controller.phoneList[index] is NativeAd) {
      return Card(
        elevation: 8.0,
        child: Obx(() {
          if (index < 10) {
            return controller.isAdShowList.contains(index)
                ? Container(
                    child: AdWidget(ad: controller.phoneList[index]),
                    height: controller.phoneList[index].factoryId == 'nativeBigAd'
                        ? 340.0
                        : 120.0, // big 340.0 small 120.0,
                    alignment: Alignment.center,
                  )
                : Text(
                    '?????????'.tr,
                    semanticsLabel: '?????????'.tr,
                  );
          }
          return Container(
            child: AdWidget(ad: controller.phoneList[index]),
            height: controller.phoneList[index].factoryId == 'nativeBigAd' ? 340.0 : 120.0, // big 340.0 small 120.0,
            alignment: Alignment.center,
          );
        }),
      );
    }

    var bh = controller.phoneList[index]['country']['bh'].toString();
    String image = Api.baseUrl + "/static/images/flag/circle/" + bh + ".png";
    bh = "+$bh";
    final String phoneNum = controller.phoneList[index]['phone_num'];

    final String country = controller.phoneList[index]['country']['title'];
    final String receiveTotal = controller.phoneList[index]['receive_total'].toString() +
        (controller.phoneList[index]['receive_total'] > 0 ? '+' : '');
    String type = controller.phoneList[index]['type'];
    String typeTitle;
    if (type == '2') {
      typeTitle = '(${'??????'.tr})';
    } else if (type == '3') {
      typeTitle = '(VIP)';
    } else {
      typeTitle = '';
    }

    // last time
    String lastTime;
    if (type == '1' || type == '3') {
      lastTime = Tools.timeHandler(controller.phoneList[index]['last_time']);
    } else {
      lastTime = Tools.timeHandler(0);
    }

    return SizedBox(
      height: 120,
      child: Card(
        elevation: 8.0, //????????????
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))), //????????????
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              /// ????????????
              GestureDetector(
                // ?????????????????????
                onTap: () {
                  Get.toNamed(
                    Routes.phoneList +
                        '?countryID=${controller.phoneList[index]['country']['id']}&title=${controller.phoneList[index]['country']['title']}',
                  );
                },
                child: Semantics(
                  child: CachedNetworkImage(
                    width: 64,
                    imageUrl: image,
                    errorWidget: (context, url, error) => const Icon(Icons.image_outlined, size: 64),
                  ),
                  label: controller.phoneList[index]['country']['title'],
                ),
              ),

              /// ????????????
              GestureDetector(
                // ??????????????????
                onLongPress: () {
                  FlutterClipboard.copy(phoneNum).then((value) {
                    Tools.toast(phoneNum + ' ' + '????????????'.tr, type: 'info');
                  });
                },
                child: GestureDetector(
                  // ?????????????????????
                  onTap: () {
                    Get.toNamed(Routes.phoneDetail + '?phone=' + controller.phoneList[index]['phone_num'],
                        arguments: controller.phoneList[index]);
                  },
                  child: Column(
                    //????????????
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          /// ????????????
                          Text(
                            country,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                            semanticsLabel: country,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Row(
                          children: [
                            Text(
                              bh,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              semanticsLabel: bh,
                            ),
                            Text(
                              " " + phoneNum,
                              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                              semanticsLabel: phoneNum,
                            ),
                            const SizedBox(
                              width: 5,
                            ),

                            /// ????????????
                            GestureDetector(
                              onTap: () {
                                if (type == '2') {
                                  Get.toNamed(Routes.phoneList + '?countryID=upcoming&title=' + '????????????'.tr);
                                } else if (type == '3') {
                                  Get.toNamed(Routes.phoneList + '?countryID=vip&title=' + 'VIP??????'.tr);
                                }
                              },
                              child: type == '2'
                                  ? AutoSizeText(
                                      typeTitle,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      semanticsLabel: typeTitle,
                                    )
                                  : Text(
                                      typeTitle,
                                      style: const TextStyle(fontSize: 12, color: Colors.green),
                                      semanticsLabel: typeTitle,
                                    ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              /// ????????????
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      ///??????????????????
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 1.0),
                          child: Icon(PhosphorIcons.clock, size: 15.0, color: Colors.grey),
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        Text(
                          lastTime,
                          style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                          semanticsLabel: lastTime,
                        )
                        //Text(lastTime)
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        ///??????????????????
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                              padding: const EdgeInsets.only(left: 5.0, top: 2.0, right: 5.0, bottom: 2.0),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.all(Radius.circular(3.0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    PhosphorIcons.envelope_simple,
                                    size: 18.0,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    receiveTotal,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                    ),
                                    semanticsLabel: receiveTotal,
                                  )
                                ],
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///????????????
  Future<void> _onLoad() async {
    controller.page = controller.page + 1;
    bool isOk = await controller.fetchPhoneList(page: controller.page);
    if(isOk == false){
      controller.scrollController.animateTo(
        controller.currentScroll - 60,
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    }
    //controller.refreshController.finishRefresh(success: true);
  }

  ///????????????
  Future<void> _onRefresh() async {
    //await Future.delayed(const Duration(milliseconds: 5000));
    controller.page = 1;
    await controller.fetchPhoneList();
  }
}
