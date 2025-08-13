import 'package:flutter/material.dart';

class CircleNumberWidget extends StatefulWidget {
  final int number;
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final bool isBlinking; // 新增属性，控制是否闪烁

  const CircleNumberWidget({
    Key? key,
    required this.number,
    this.size = 24.0,
    this.backgroundColor = Colors.green,
    this.textColor = Colors.white,
    this.isBlinking = false,
  }) : super(key: key);

  @override
  _CircleNumberWidgetState createState() => _CircleNumberWidgetState();
}

class _CircleNumberWidgetState extends State<CircleNumberWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        setState(() {});
      });

    _animation = Tween(begin: 1.0, end: 0.0).animate(_controller);

    if (widget.isBlinking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CircleNumberWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinking != oldWidget.isBlinking) {
      if (widget.isBlinking) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0; // 停止时保持完全不透明
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isBlinking ? _animation.value : 1.0,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.isBlinking ? Colors.red : widget.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            widget.number.toString(),
            style: TextStyle(
              color: widget.textColor,
              fontSize: widget.size * 0.389,
              // fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}