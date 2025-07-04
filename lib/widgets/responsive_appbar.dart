import 'package:assistify/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  ResponsiveAppBar({super.key, required bool isTablet})
      : preferredSize = Size.fromHeight(
          isTablet ? kToolbarHeight * 1.1 : kToolbarHeight * 1.1,
        );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    const double tabletThreshold = 600;

    if (size.width > tabletThreshold) {
      return const CustomAppBar();
    } else {
      return const CustomAppBar();
    }
  }
}
