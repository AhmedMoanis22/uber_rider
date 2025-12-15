import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A reusable loading indicator widget
class LoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final bool useCupertino;

  const LoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.useCupertino = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useCupertino) {
      return SizedBox(
        width: size,
        height: size,
        child: CupertinoActivityIndicator(
          color: color,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: color != null ? AlwaysStoppedAnimation(color) : null,
      ),
    );
  }
}
