import 'package:flutter/material.dart';
import 'package:flaride_driver/core/utils/responsive_utils.dart';

class ProfileSectionContainer extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ProfileSectionContainer({
    super.key,
    required this.children,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ??
          EdgeInsets.only(
            bottom: context.responsiveValue(mobile: 12, tablet: 16),
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          children: children,
        ),
      ),
    );
  }
}
