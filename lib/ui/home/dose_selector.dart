import 'package:espresso_log/domain/bean/dose.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoseSelector extends StatelessWidget {
  const DoseSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeansCubit, BeansState>(
      builder: (context, state) {
        final cubit = context.read<BeansCubit>();
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Dose'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () =>
                      cubit.setDose(state.doseGrams - doseStepGrams),
                ),
                InkWell(
                  key: const Key('dose-text'),
                  onTap: () => _editDose(context, cubit),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${state.doseGrams.toStringAsFixed(1)} g',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () =>
                      cubit.setDose(state.doseGrams + doseStepGrams),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editDose(BuildContext context, BeansCubit cubit) async {
    final controller = TextEditingController(
      text: cubit.state.doseGrams.toStringAsFixed(1),
    );
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dose'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'g'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (text == null) return;
    final dose = parseDose(text);
    if (dose != null) cubit.setDose(dose);
  }
}
