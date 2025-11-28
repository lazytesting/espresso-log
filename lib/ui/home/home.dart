import 'package:espresso_log/ui/components/current-weight/current_weight_widget.dart';
import 'package:espresso_log/ui/components/pressure/pressure_widget.dart';
import 'package:espresso_log/ui/components/weight-change/weight_change_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: CurrentWeightWidget()),
            Expanded(child: WeightChangeWidget()),
            Expanded(child: PressureWidget()),
          ],
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            context.push('/shot');
          },
          icon: Icon(Icons.coffee, size: 32),
          label: Text('START SHOT', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            minimumSize: Size(200, 80),
          ),
        ),
      ],
    );
  }
}
