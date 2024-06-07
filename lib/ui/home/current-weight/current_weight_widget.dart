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

        return Center(
            child: Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(children: [
                  Text(
                    weight,
                    style: const TextStyle(fontSize: 25),
                  )
                ]),
                const Row(children: [Text('Grams')]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const SizedBox(width: 8),
                    FilledButton(
                      child: const Text('Tare'),
                      onPressed: () {
                        context.read<CurrentWeightCubit>().tareScale();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        ));
      },
    );
  }
}
