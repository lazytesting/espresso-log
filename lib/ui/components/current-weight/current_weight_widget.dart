import 'package:espresso_log/ui/shot/metric_grid.dart';
import 'package:espresso_log/ui/components/current-weight/current_weight_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CurrentWeightWidget extends StatelessWidget {
  const CurrentWeightWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentWeightCubit, CurrentWeightState>(
      builder: (context, state) {
        var weight = '--';
        if (state is CurrentWeightMeasured) {
          weight = state.weight.toStringAsFixed(1);
        }

        return MetricCell(value: weight, unit: 'g');
      },
    );
  }
}
