import 'package:flutter/material.dart';

class MetricsCardWidget extends StatelessWidget {
  const MetricsCardWidget({super.key, required this.typeText, this.value});

  final String typeText;
  final String? value;


  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(value ?? "--", style: const TextStyle(fontSize: 25)),
            Text(typeText),
          ],
        ),
      ),
    );
  }
}
