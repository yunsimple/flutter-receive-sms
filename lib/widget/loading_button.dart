import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';

class LoadingButton<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? color;
  final Color? textColor;
  final Future<T> Function() onPress;
  final Function(T)? onAsyncCallFinished;

  const LoadingButton(
      {Key? key, required this.title, required this.icon, required this.onPress, this.onAsyncCallFinished, this.color, this.iconColor, this.textColor})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController animaController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    animaController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    animaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : _onPressed,
      icon: RotationTransition(
        turns: animaController,
        child: Icon(isLoading ? PhosphorIcons.arrows_counter_clockwise : widget.icon, color: widget.iconColor,),
      ),
      label: Text(
        widget.title,
        style: TextStyle(
          color: widget.textColor,
        ),
        semanticsLabel: widget.title,
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(widget.color),
      ),
    );
  }

  _onPressed() {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    animaController.repeat();

    ///点击按扭的时候，按扭变成disable状态，回调有返回后，再激活
    widget.onPress.call().then((value) {
      //通知回调完成
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      widget.onAsyncCallFinished?.call(true);
      animaController.reset();
    }).catchError((onError) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      widget.onAsyncCallFinished?.call(true);
      animaController.reset();
    });
  }

  @override
  bool get wantKeepAlive => true;
}
