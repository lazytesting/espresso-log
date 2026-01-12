import 'package:espresso_log/ui/shot/shot_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShotCubit, ShotState>(
      builder: (context, state) {
        String timer = "";
        if (state is ShotInitial || state is ShotWaiting) {
          timer = '--.-';
        }

        if (state is ShotRun) {
          var seconds = (state.timer / 1000).floor();
          var deciSeconds = ((state.timer - 1000 * seconds) / 100).floor();
          timer = "$seconds.$deciSeconds";
        }


        return Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timer, style: const TextStyle(fontSize: 25)),
                const Text('Seconds'),
              ],
            ),
          ),
        );
      },
    );
  }
}
