import 'package:flutter/material.dart';

import '../../../../core/widgets/icon_button_card.dart';

/// Top app bar for the home screen with menu and profile buttons
class HomeTopBar extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onProfilePressed;

  const HomeTopBar({
    super.key,
    required this.onMenuPressed,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButtonCard(
              icon: Icons.menu,
              onPressed: onMenuPressed,
            ),
            const Spacer(),
            IconButtonCard(
              icon: Icons.person,
              onPressed: onProfilePressed,
            ),
          ],
        ),
      ),
    );
  }
}
