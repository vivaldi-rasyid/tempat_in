import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    const icons = [
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.calendar_month_rounded,
      Icons.person_rounded,
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        color: AppColors.navBarBg,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(icons.length, (i) {
                final active = i == currentIndex;
                return IconButton(
                  onPressed: () => navigationShell.goBranch(
                    i,
                    initialLocation: i == currentIndex,
                  ),
                  icon: Icon(
                    icons[i],
                    size: 28,
                    color: active ? AppColors.primary : const Color(0xFF9E9E9E),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}