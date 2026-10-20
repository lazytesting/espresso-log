import 'package:espresso_log/data/mock/mock_shot_simulator.dart';
import 'package:flutter/material.dart';

/// Debug-only overlay that triggers a scripted shot on the mock devices.
/// Only wired up from `main.dart` when a mock device is in use.
class MockShotButton extends StatelessWidget {
  final MockShotSimulator simulator;
  final Widget? child;

  const MockShotButton({super.key, required this.simulator, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (child != null) child!,
        Positioned(
          left: 16,
          bottom: 16,
          child: SafeArea(
            child: FloatingActionButton.small(
              heroTag: null,
              onPressed: simulator.pullShot,
              child: const Icon(Icons.coffee),
            ),
          ),
        ),
      ],
    );
  }
}
