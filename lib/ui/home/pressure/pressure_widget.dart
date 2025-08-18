import 'package:espresso_log/ui/home/pressure/pressure_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PressureWidget extends StatelessWidget {
  const PressureWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PressureCubit, PressureState>(
      builder: (context, state) {
        var pressureText = "-.-";
        if (state is Pressure) {
          pressureText = state.pressure.toStringAsFixed(1);
        }
        return Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pressureText,
                  style: const TextStyle(fontSize: 25),
                ),
                const Text("Bar")
              ],
            ),
          ),
        );
      },
    );
  }
}
