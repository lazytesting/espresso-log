import 'package:espresso_log/ui/shot/metric_grid.dart';
import 'package:espresso_log/ui/components/pressure/pressure_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PressureWidget extends StatelessWidget {
  const PressureWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PressureCubit, PressureState>(
      builder: (context, state) {
        var pressureText = '--';
        if (state is Pressure) {
          pressureText = state.pressure.toStringAsFixed(1);
        }
        return MetricCell(value: pressureText, unit: 'bar');
      },
    );
  }
}
