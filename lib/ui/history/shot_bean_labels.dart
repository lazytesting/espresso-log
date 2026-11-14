import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';

const unknownBeanLabel = 'Unknown bean';

String beanNameFor(RecordedShot shot, Bean? bean) =>
    bean?.name ?? unknownBeanLabel;

String formatDose(double? grams) =>
    grams == null ? '--' : '${grams.toStringAsFixed(1)} g';
