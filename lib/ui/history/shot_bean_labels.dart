import 'package:espresso_log/domain/bean/bean.dart';

const unknownBeanLabel = 'Unknown bean';
const unknownGrinderLabel = 'Unknown grinder';

String beanNameFor(Bean? bean) => bean?.name ?? unknownBeanLabel;

String formatDose(double? grams) =>
    grams == null ? '--' : '${grams.toStringAsFixed(1)} g';
