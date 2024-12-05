import 'package:espresso_log/ui/home/weight-change/weight_change_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WeightChangeWidget extends StatelessWidget {
  const WeightChangeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeightChangeCubit, WeightChangeState>(
      builder: (context, state) {
        var weight = '--.-';
        if (state is WeightChangeUpdated) {
          weight = state.weightChangeRate.toStringAsFixed(1);
        }

        return Card(
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
                const Row(children: [Text('g/s')]),
              ],
            ),
          ),
        );
      },
    );
  }
}
