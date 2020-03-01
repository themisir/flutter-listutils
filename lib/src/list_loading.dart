import 'package:flutter/material.dart';

class CustomListLoading extends StatelessWidget {
  final double height;
  final double indicatorSize;
  final double strokeWidth;

  static WidgetBuilder defaultBuilder = (context) => CustomListLoading();

  const CustomListLoading({
    this.height = 100,
    this.indicatorSize = 20,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}
