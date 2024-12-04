import 'package:espresso_log/ui/home/auto-tare/auto_tare_widget.dart';
import 'package:espresso_log/ui/home/current-weight/current_weight_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CurrentWeightWidget extends StatelessWidget {
  const CurrentWeightWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentWeightCubit, CurrentWeightState>(
      builder: (context, state) {
        var weight = '--.-';
        if (state is CurrentWeightMeasured) {
          weight = state.weight.toStringAsFixed(1);
        }

        return Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text(
                weight,
                style: const TextStyle(fontSize: 25),
              ),
              const Row(children: [Text('Grams')]),
            ]),
          ),
        );
      },
    );
  }
}
