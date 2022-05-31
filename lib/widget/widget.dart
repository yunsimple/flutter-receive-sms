import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import '../../Routes.dart';
import '../../utils/api.dart';
import '../../utils/tools.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:get/get.dart';

Widget emptyPageWidget({String title = 'No email received', String subTitle = 'Try the drop-down refresh', String image = 'empty'}) {
  Widget empty = SingleChildScrollView(
    child: Center(
      child: Column(
        children: [
          Image.asset('assets/images/$image.png'),
          Text(title, style: const TextStyle(
              color: Colors.grey,
            fontSize: 20
          )),
          const SizedBox(height: 10,),
          Text(subTitle, style: const TextStyle(
              color: Colors.grey,
              fontSize: 15
          )),
        ],
      ),
    ),
  );
  return empty;
}


Widget phoneItem(BuildContext context, int index, data) {
  var bh = data[index]['country']['bh'].toString();
  String image = Api.baseUrl + "/static/images/flag/circle/" + bh + ".png";
  bh = "+$bh";
  final String phoneNum = data[index]['phone_num'];

  final String country = data[index]['country']['title'];
  final int lastTime = data[index]['last_time'];
  final String totalNum = " 10" + (data[index]['total_num'].toString()) + "+";

  return SizedBox(
    height: 120,
    child: Card(
      elevation: 8.0, //设置阴影
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))), //设置圆角
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            CachedNetworkImage(
              width: 64,
              imageUrl: image,
              errorWidget: (context, url, error) => const Icon(Icons.image_outlined,size: 64),
            ),
            GestureDetector(
              onTap: (){
                Get.toNamed(Routes.phoneDetail + '?phone=' + data[index]['phone_num'], arguments: data[index]);
              },
              onLongPress: () {
                FlutterClipboard.copy(phoneNum).then((value) {
                  Tools.toast("$phoneNum号码复制完成");
                });
              },
              child: Column(
                //中间号码
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country,
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      children: [
                        Text(
                          bh,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          " " + phoneNum,
                          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: Column(
                ///右边信息
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    ///最后更新时间
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 1.0),
                        child: Icon(PhosphorIcons.clock, size: 15.0, color: Colors.grey),
                      ),
                      Text(Tools.timeHandler(lastTime), style: const TextStyle(fontSize: 12.0, color: Colors.grey))
                      //Text(lastTime)
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      ///接收数量标签
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
                                Text(
                                  totalNum,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                  ),
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
