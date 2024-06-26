import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/scale/decent_scale_service.dart';
import 'package:espresso_log/ui/scaffold/screen_container.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});
  late final AbstractScaleService _scaleService =
      getIt.get<DecentScaleService>();

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      title: 'Bla',
      child: _getScreen(),
    );
  }

  Widget _getScreen() {
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FilledButton(
              onPressed: () => _scaleService.init(), child: const Text("init")),
          FilledButton(
              onPressed: () => _scaleService.tareCommand(),
              child: const Text("tare")),
        ],
      ),
    );
  }
}
