import 'package:espresso_log/ui/home/auto-tare/auto_tare_cubit.dart';
import 'package:espresso_log/ui/home/current-weight/current_weight_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AutoTareWidget extends StatelessWidget {
  const AutoTareWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AutoTareCubit, AutoTareState>(
      builder: (context, state) {
        return Checkbox(
            checkColor: Colors.white,
            value: state is AutoTareEnabledState,
            onChanged: (bool? value) {
              if (value == true) {
                context.read<AutoTareCubit>().enable();
              } else {
                context.read<AutoTareCubit>().disable();
              }
            });
      },
    );
  }
}
