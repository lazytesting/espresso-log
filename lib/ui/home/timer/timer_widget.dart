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
        var button = FilledButton(
          child: const Text('Start'),
          onPressed: () {
            context.read<TimerCubit>().start();
          },
        );

        if (state is TimerRunning) {
          timer = state.seconds.toString();
          button = FilledButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
            onPressed: () {
              context.read<TimerCubit>().stop();
            },
            child: const Text('Stop'),
          );
        }

        if (state is TimerStopped) {
          timer = state.seconds.toString();
        }

        return Center(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(children: [
                  Text(
                    timer,
                    style: const TextStyle(fontSize: 25),
                  )
                ]),
                const Row(children: [Text('Seconds')]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const SizedBox(width: 8),
                    button,
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
