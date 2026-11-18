import 'package:espresso_log/ui/components/bean_icon.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key, required this.child});

  final StatefulNavigationShell child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: child.currentIndex,
        onTap: (index) {
          child.goBranch(index, initialLocation: index == child.currentIndex);
        },
        items: rootNavItems,
      ),
    );
  }
}

/// The bottom bar tabs, in branch order.
const rootNavItems = [
  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
  BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
  BottomNavigationBarItem(icon: BeanIcon(), label: 'Beans'),
  BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
];
