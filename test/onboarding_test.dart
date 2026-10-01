import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto1/views/OnBoardingView.dart';
import 'package:proyecto1/views/SplashView.dart';

Widget app(Widget home) => MaterialApp(
  home: home,
  routes: {'/HomeView': (_) => const Scaffold(body: Text('Destino'))},
);

void main() {
  testWidgets('desliza, avanza y completa antes de navegar', (tester) async {
    var completado = false;
    await tester.pumpWidget(
      app(Onboardingview(completar: () async => completado = true)),
    );
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Descubre tu espacio'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Comenzar'), findsOneWidget);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(completado, isTrue);
    expect(find.text('Destino'), findsOneWidget);
  });
  testWidgets('omitir guarda y abre Home', (tester) async {
    var escrituras = 0;
    await tester.pumpWidget(
      app(
        Onboardingview(
          completar: () async {
            escrituras++;
          },
        ),
      ),
    );
    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();
    expect(escrituras, 1);
    expect(find.text('Destino'), findsOneWidget);
  });
  testWidgets('error de escritura mantiene bienvenida y permite reintentar', (
    tester,
  ) async {
    var intentos = 0;
    await tester.pumpWidget(
      app(
        Onboardingview(
          completar: () async {
            if (intentos++ == 0) throw StateError('offline');
          },
        ),
      ),
    );
    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo guardar la bienvenida. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Destino'), findsNothing);
    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();
    expect(find.text('Destino'), findsOneWidget);
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
          home: Onboardingview(completar: () async {}),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Descubre tu espacio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'splash navega sin esperar imagen y muestra retry si falla destino',
    (tester) async {
      var intentos = 0;
      await tester.pumpWidget(
        app(
          SplashView(
            destino: () async {
              if (intentos++ == 0) throw StateError('offline');
              return '/HomeView';
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Reintentar'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Destino'), findsOneWidget);
    },
  );
}
