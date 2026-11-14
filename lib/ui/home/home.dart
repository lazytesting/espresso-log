import 'package:espresso_log/ui/home/bean_selector.dart';
import 'package:espresso_log/ui/home/dose_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: const Column(
                children: [
                  BeanSelector(),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  DoseSelector(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 64,
              child: FilledButton.icon(
                onPressed: () => context.push('/shot'),
                icon: const Icon(Icons.coffee, size: 28),
                label: const Text('START SHOT', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
