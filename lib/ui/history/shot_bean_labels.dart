import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';

const unknownBeanLabel = 'Unknown bean';
const unknownGrinderLabel = 'Unknown grinder';

String beanNameFor(Bean? bean) => bean?.name ?? unknownBeanLabel;

String formatDose(double? grams) =>
    grams == null ? '--' : '${grams.toStringAsFixed(1)} g';

String grinderLineFor(Grinder grinder, String? grindSetting) =>
    grindSetting == null ? grinder.name : '${grinder.name} · $grindSetting';
