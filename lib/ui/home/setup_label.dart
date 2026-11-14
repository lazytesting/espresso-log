import 'package:flutter/material.dart';

/// Fixed-width label in front of a Home setup row (Bean, Dose), so both rows
/// use the same label size and their values line up.
class SetupLabel extends StatelessWidget {
  final String text;

  const SetupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 64,
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
