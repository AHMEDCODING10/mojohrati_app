import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/colors.dart';

class ShimmerHelper {
  static Widget buildShimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: child,
    );
  }

  static Widget buildGoldShimmer({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: AppColors.primaryGold.withOpacity(0.3),
      highlightColor: AppColors.primaryGold.withOpacity(0.1),
      child: child,
    );
  }

  static Widget buildBoxShimmer({
    double width = double.infinity,
    double height = 20,
    double borderRadius = 8,
  }) {
    return buildShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
