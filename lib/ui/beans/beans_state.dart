part of 'beans_cubit.dart';

class BeansState extends Equatable {
  const BeansState({
    this.loaded = false,
    this.beans = const [],
    this.selectedBeanId,
    this.doseGrams = defaultDoseGrams,
  });

  final bool loaded;

  /// Non-archived beans in name order.
  final List<Bean> beans;
  final String? selectedBeanId;
  final double doseGrams;

  Bean? get selectedBean {
    for (final bean in beans) {
      if (bean.id == selectedBeanId) return bean;
    }
    return null;
  }

  @override
  List<Object?> get props => [loaded, beans, selectedBeanId, doseGrams];
}
