import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/shot/shot_result_view.dart';
import 'package:espresso_log/ui/shot/shot_screen.dart';
import 'package:espresso_log/ui/shot/timer/timer_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_shot_repository.dart';
import 'shot_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ShotGraphCubit>(), MockSpec<TimerCubit>()])
void main() {
  setUp(() {
    provideDummy<ShotGraphState>(ShotGraphInitial());
    provideDummy<TimerState>(TimerInitial());
  });

  testWidgets('shot done shows the shared result view with the selection', (
    tester,
  ) async {
    final beans = InMemoryBeanRepository();
    await beans.save(
      const Bean(
        id: 'b1',
        name: 'Guji',
        roaster: 'Friedhats',
        roastLevel: 1,
        archived: false,
        doseGrams: 18,
      ),
    );
    final settings = FakeSettings()..selectedBeanId = 'b1';
    final beansCubit = BeansCubit(beans, settings);
    addTearDown(beansCubit.close);
    await beansCubit.load();

    final graph = MockShotGraphCubit();
    when(graph.state).thenReturn(
      ShotGraphStopped(
        const ShotSnapshot(
          weightData: [],
          pressureData: [],
          summary: ShotSummary(finalWeight: 36.0, durationMillis: 28400),
        ),
      ),
    );
    when(graph.stream).thenAnswer((_) => const Stream.empty());
    final timer = MockTimerCubit();
    when(timer.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShotRepository>.value(value: InMemoryShotRepository()),
          BlocProvider<BeansCubit>.value(value: beansCubit),
          BlocProvider<ShotGraphCubit>.value(value: graph),
          BlocProvider<TimerCubit>.value(value: timer),
        ],
        child: const MaterialApp(home: ShotScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Shot done'), findsOneWidget);
    expect(find.byType(ShotResultView), findsOneWidget);
    expect(find.text('Guji'), findsOneWidget);
    expect(find.text('Dose'), findsOneWidget);
    expect(find.text('1 : 2.0', findRichText: true), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
