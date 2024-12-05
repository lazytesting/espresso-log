import 'package:espresso_log/ui/home/timer/timer_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        var timer = '--.-';

        if (state is TimerStopped) {
          timer = "${state.seconds}.${state.deciSeconds}";
        }

        return Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                timer,
                style: const TextStyle(fontSize: 25),
              ),
              const Text('Seconds')
            ]),
          ),
        );
      },
    );
  }
}
