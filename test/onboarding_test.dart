import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto1/views/OnBoardingView.dart';

Widget app(Widget home) => MaterialApp(
  home: home,
  routes: {'/HomeView': (_) => const Scaffold(body: Text('Destino'))},
);

void main() {
  testWidgets('desliza y avanza hasta el botón Comenzar', (tester) async {
    await tester.pumpWidget(app(const Onboardingview()));
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Descubre tu espacio'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Comenzar'), findsOneWidget);
  });
  for (final size in [const Size(375, 667), const Size(667, 375)]) {
    testWidgets('layout $size con texto grande y movimiento reducido', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const Onboardingview(),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Descubre tu espacio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
