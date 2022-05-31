import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../common/local_storage.dart';
import '../common/remote_config.dart';

class NoticeBar extends StatefulWidget {
  // 文本颜色
  final Color? color;
  // 滚动条背景
  final Color? background;
  // 通知文本内容
  final String text;
  // 通知文本内容
  final String id;
  // 左侧图标
  final IconData? leftIcon;
  // 通知栏模式，可选值为 closeable、link
  final String? mode;
  // 是否在长度溢出时滚动播放
  final bool scrollable;
  // 是否开启文本换行，只在禁用滚动时生效
  final bool wrapable;
  // 关闭通知栏时触发
  final Function()? onClose;
  // 点击通知栏时触发
  final Function()? onClick;
  // 滚动速率
  final int speed;
  // 动画延迟时间 (s)
  final int delay;

  const NoticeBar({
    Key? key,
    this.color,
    this.background,
    required this.text,
    required this.id,
    this.leftIcon,
    this.mode = 'closeable',
    this.scrollable = true,
    this.wrapable = false,
    this.onClose,
    this.onClick,
    this.speed = 5,
    this.delay = 100,
  }) : super(key: key);

  @override
  _NoticeBar createState() => _NoticeBar();
}

class _NoticeBar extends State<NoticeBar> {
  ScrollController? scrollController;
  late double screenWidth;
  double? screenHeight;
  double position = 0.0;
  Timer? _timer;
  final GlobalKey _key = GlobalKey();
  bool showNotice = true;

  @override
  void initState() {
    scrollController = ScrollController();
    if (widget.scrollable) {
      WidgetsBinding.instance!.addPostFrameCallback(_onLayoutDone);
    }
    super.initState();
  }

  _onLayoutDone(_) {
    RenderBox notice = _key.currentContext!.findRenderObject() as RenderBox;
    double widgetWidth = notice.size.width;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    _timer = Timer.periodic(Duration(milliseconds: widget.delay), (timer) {
      double maxScrollExtent = scrollController!.position.maxScrollExtent;
      double pixels = scrollController!.position.pixels;
      if (pixels + widget.speed >= maxScrollExtent) {
        position = (maxScrollExtent - (screenWidth * 0.5) + widgetWidth) / 2 - widgetWidth + pixels - maxScrollExtent;
        scrollController!.jumpTo(position);
      }
      position += widget.speed;
      scrollController!.animateTo(position, duration: Duration(milliseconds: widget.delay), curve: Curves.linear);
    });
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
    super.dispose();
  }

  Widget buildText() {
    return Expanded(
      child: widget.scrollable
          ? ListView(
              key: _key,
              scrollDirection: Axis.horizontal,
              controller: scrollController,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                Center(
                  child: Text(
                    widget.text,
                    style: TextStyle(fontSize: 14.0, color: widget.color),
                    maxLines: widget.wrapable && !widget.scrollable ? null : 1,
                  ),
                ),
                Container(width: screenWidth * 0.5),
                Center(
                  child: Text(
                    widget.text,
                    style: TextStyle(fontSize: 14.0, color: widget.color),
                    maxLines: widget.wrapable && !widget.scrollable ? null : 1,
                  ),
                )
              ],
            )
          : Text(
              widget.text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.0, color: widget.color),
              maxLines: widget.wrapable ? null : 1,
            ),
    );
  }

  List<Widget> buildCloseButton() {
    return [
      (widget.mode == "closeable" || widget.mode == "link") ? const SizedBox(width: 6.0) : Container(),
      (widget.mode == "closeable" || widget.mode == "link")
          ? GestureDetector(
              child: Icon(widget.mode == "closeable" ? Icons.cancel : Icons.chevron_right,
                  color: widget.color, size: 16.0),
              onTap: () {
                if (widget.mode == "closeable" && widget.onClose != null) {
                  setState(() {
                    showNotice = false;
                  });
                  if (widget.scrollable) _timer!.cancel();
                  widget.onClose!();
                }
                if (widget.mode == "link" && widget.onClick != null) {
                  widget.onClick!();
                }
              },
            )
          : Container()
    ];
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Visibility(
      visible: showNotice,
      child: Container(
        height: widget.wrapable ? null : 40.0,
        padding: const EdgeInsets.only(left: 8, right: 8),
        color: widget.background,
        child: GestureDetector(
          onTap: () {
            /// 关闭前弹窗提示
            showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: SingleChildScrollView(child: Text(widget.text)),
                  actions: <Widget>[
                    widget.mode == 'closeable' ? TextButton(
                      child: Text("不再显示".tr),
                      onPressed: () {
                        // 关闭Notice
                        if (widget.mode == "closeable" && widget.onClose != null) {
                          setState(() {
                            showNotice = false;
                          });
                          if (widget.scrollable) _timer!.cancel();
                          widget.onClose!();
                        }
                        //关闭对话框并返回true
                        Navigator.of(context).pop();
                      },
                    ) : Container(),
                    TextButton(
                      child: Text("已阅".tr),
                      onPressed: () => Navigator.of(context).pop(), // 关闭对话框
                    ),
                  ],
                );
              },
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              widget.leftIcon != null ? Icon(widget.leftIcon, color: widget.color, size: 16.0) : Container(),
              SizedBox(width: widget.leftIcon != null ? 4.0 : 0),
              buildText(),
              ...buildCloseButton()
            ],
          ),
        ),
      ),
    );
  }
}

/// 远程请求notice
Widget getNotice() {
  /// 读取LocalStorage内请求到的远程notice
  /// 判断该条notice是否已经被标记不再显示，id = true
  ///
  var noticeData = LocalStorage().getJSON('notice');
  if (noticeData is List && RemoteConfigApi().getBool('noticeSwitch')) {
    List<Widget> noticesWidget = [];
    int i = 1;
    var colorList = [
      {'background': const Color(0xffecf9ff), 'color': const Color(0xff1989fa)},  // info
      {'background': const Color(0xfffffbe8), 'color': const Color(0xffed6a0c)},  // danger
    ];
    for (var value in noticeData) {
      // 如果存在关闭的标记，则不显示
      if (LocalStorage().getBool(value['id'].toString()) == true) break;

      if (i > 1) {
        noticesWidget.add(const SizedBox(
          height: 8,
        ));
      }

      Widget notice = NoticeBar(
        id: value['id'].toString(),
        text: value['description'],
        scrollable: false,
        // closeable、link
        mode: value['isClose'] ? 'closeable' : 'link',
        background: value['type'] == 'info' ? colorList[0]['background'] : colorList[1]['background'],
        color: value['type'] == 'info' ? colorList[0]['color'] : colorList[1]['color'],
        onClose: () {
          //缓存标记，该ID，不再显示
          if(value['isClose']) LocalStorage().setBool(value['id'].toString(), true);
        },
      );
      noticesWidget.add(notice);
      i++;
    }
    return Column(
      children: <Widget>[...noticesWidget],
    );
  }
  return Container();
}
