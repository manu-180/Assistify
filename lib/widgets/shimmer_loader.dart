import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Color brillo;
  final Color color;
  final double width;
  final double height;
  const ShimmerLoading(
      {super.key,
      required this.color,
      required this.width,
      required this.height,
      required this.brillo});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: color,
      highlightColor: brillo,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.onPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
