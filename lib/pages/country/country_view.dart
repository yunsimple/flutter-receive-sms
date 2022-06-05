import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../Routes.dart';
import '../../common/notice_bar.dart';
import '../../utils/api.dart';
import 'package:get/get.dart';
import '../../widget/widget.dart';
import 'country_controller.dart';

class CountryView extends GetView<CountryController> {
  const CountryView({Key? key}) : super(key: key);
  Size get size => MediaQuery.of(Get.context!).size;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.title, semanticsLabel: controller.title,),
      ),
      body: Column(
        children: [getNotice(), Expanded(child: _countryList())],
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

  _countryList() {
    return controller.obx(
      (data) {
        return EasyRefresh(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Wrap(
              runSpacing: 20,
              alignment: WrapAlignment.spaceAround,
              children: List.generate(data.length, (index) {
                if (controller.countryList[index] is NativeAd) {
                  return Card(
                    elevation: 8.0,
                    child: Obx(() {
                      return Container(
                        child: AdWidget(ad: controller.countryList[index]),
                        height: controller.countryList[index].factoryId == 'nativeBigAd' ? 340.0 : 120.0, // big 340.0 small 120.0,
                        alignment: Alignment.center,
                      );
                    }),
                  );
                }
                return SizedBox(
                  width: (size.width - 10)/2,
                  child: countryListItem(index, data[index]),
                );

              }),
            ),
          ),
          onLoad: _onLoad,
          onRefresh: _onRefresh,
          scrollController: controller.scrollController,
        );
      },
      onEmpty: EasyRefresh(onRefresh: _onRefresh, child: emptyPageWidget(title: '列表为空'.tr, subTitle: '尝试下拉刷新'.tr)),
      onError: (error) => EasyRefresh(
          onRefresh: _onRefresh, child: emptyPageWidget(title: '请求失败'.tr, subTitle: '尝试下拉刷新'.tr, image: 'error')),
    );
  }

  countryListItem(int index, data) {
    String image = Api.baseUrl + "/static/images/flag/1000/" + data['bh'].toString() + ".png";
    return InkWell(
      onTap: () {
        Get.toNamed(
          Routes.phoneList + '?countryID=${data['id']}&title=${data['title']}',
        );
      },
      child: Column(
        children: [
          Semantics(
            child: CachedNetworkImage(
              imageUrl: image,
              errorWidget: (context, url, error) => const Icon(
                Icons.image_outlined,
                size: 100,
              ),
            ),
            label: data['title'],
          ),
          Text(
            data['title'],
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            semanticsLabel: data['title'],
          )
        ],
      ),
    );
  }

  ///上拉加载
  Future<void> _onLoad() async {
    controller.page = controller.page + 1;
    await controller.fetchCountryList(page: controller.page);
    controller.refreshController.finishLoad(success: true);
  }

  ///下拉刷新
  Future<void> _onRefresh() async {
    //await Future.delayed(const Duration(milliseconds: 5000));
    await controller.fetchCountryList();
    controller.refreshController.finishRefresh(success: true);
    controller.page = 1;
  }
}
