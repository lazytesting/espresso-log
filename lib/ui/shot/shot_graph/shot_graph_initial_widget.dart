import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShotGraphInitialWidget extends StatelessWidget {
  const ShotGraphInitialWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        FilledButton(
          onPressed: () => {context.read<ShotGraphCubit>().start()},
          child: const Text('Start'),
        ),
      ],
    );
  }
}
