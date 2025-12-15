import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A floating action button for location-related actions
class LocationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;

  const LocationButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.my_location,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: backgroundColor ?? Colors.white,
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              icon,
              color: iconColor ?? AppColors.primary,
            ),
    );
  }
}
