import 'dart:io';

import 'package:aula_iot/screens/login_screen.dart';
import 'package:aula_iot/screens/profile_screen.dart';
import 'package:aula_iot/services/profile_settings.dart';
import 'package:aula_iot/widgets/aula_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    const fontDir = String.fromEnvironment('FLUTTER_FONT_DIR');
    if (fontDir.isEmpty) return;
    for (final font in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final loader = FontLoader(font.key);
      loader.addFont(
        File('$fontDir/${font.value}')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      );
      await loader.load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfileSettings.instance.initialize();
    ProfileSettings.instance.signIn('docente@aulasense.mx');
  });

  Widget app() => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AulaStyle.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AulaStyle.purple,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: const ProfileScreen(),
  );

  testWidgets(
    'Perfil se adapta a móvil y escritorio con la navegación existente',
    (tester) async {
      for (final size in [const Size(360, 800), const Size(1280, 900)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(find.text('docente@aulasense.mx'), findsOneWidget);
        expect(find.text('Aulas favoritas'), findsOneWidget);
        expect(find.text('Notificaciones'), findsOneWidget);
        expect(find.text('Preferencias de medición'), findsOneWidget);
        expect(find.text('Ayuda y soporte'), findsOneWidget);
        expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .items
              .length,
          4,
        );
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('PROFILE_PREVIEW') &&
            size.width == 360) {
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile('../build/profile-preview.png'),
          );
        }
      }
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'Edita el nombre y conserva las favoritas y su orden por cuenta',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app());
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'María López');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.text('María López'), findsOneWidget);
      await tester.tap(find.text('Aulas favoritas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zona S1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zona S1').last);
      await tester.pumpAndSettle();
      expect(ProfileSettings.instance.firstZone, 'S1');
      ProfileSettings.instance.signIn('otra@aulasense.mx');
      expect(ProfileSettings.instance.favorites, isEmpty);
      ProfileSettings.instance.signIn('docente@aulasense.mx');
      expect(ProfileSettings.instance.name, 'María López');
      expect(ProfileSettings.instance.firstZone, 'S1');
      expect(ProfileSettings.instance.favorites, {'S1'});
      await tester.tap(find.text('Zona S1').first);
      await tester.pumpAndSettle();
      expect(ProfileSettings.instance.firstZone, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Configura avisos y cierra la sesión sin volver al perfil', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());
    await tester.tap(find.text('Notificaciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(ProfileSettings.instance.temperatureAlerts, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(ProfileSettings.instance.email, isEmpty);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
