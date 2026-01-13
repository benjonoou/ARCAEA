import 'package:flutter/material.dart';

/// 自定義滾動行為，移除 overscroll 發光效果
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // 返回原始的 child，不添加 overscroll indicator
    return child;
  }
}
