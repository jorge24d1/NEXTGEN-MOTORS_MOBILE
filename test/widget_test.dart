import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:mobile_app/providers/locale_provider.dart';
import 'package:mobile_app/screens/admin_screen.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/panel_movil.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/cache_service.dart';
import 'package:mobile_app/services/sesion_movil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SesionMovil sesion;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    sesion = SesionMovil(
      'propio',
      'Ana',
      'CLIENTE',
      'credencial-local',
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
  });

  testWidgets('Una instalación antigua con solo userId vuelve al login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'userId': 'antiguo',
      'role': 'ADMINISTRADOR',
    });
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('El login abre las citas aunque Firebase no esté disponible', (
    tester,
  ) async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(jsonEncode(sesion.toJson()), 200),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: LoginScreen(api: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'a@example.org');
    await tester.enterText(find.byType(TextField).last, 'prueba');
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('La lista avisa cuando muestra las últimas citas guardadas', (
    tester,
  ) async {
    await CacheService.cacheCitas([], userId: sesion.userId);
    final api = ApiService(
      client: MockClient((_) async => throw http.ClientException('sin red')),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: HomeScreen(sesion: sesion, salir: () {}, api: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Modo sin conexión'), findsOneWidget);
  });

  test(
    'Login guarda la credencial y al reabrir consulta el perfil actualizado',
    () async {
      final api = ApiService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/login')) {
            expect(req.bodyFields['correo'], 'a@example.org');
            return http.Response(jsonEncode(sesion.toJson()), 200);
          }
          expect(req.url.path, '/api/usuario/sesion');
          expect(req.headers['Authorization'], 'Bearer ${sesion.token}');
          return http.Response(
            jsonEncode({
              'userId': sesion.userId,
              'nombre': 'Ana',
              'role': 'TRABAJADOR',
            }),
            200,
          );
        }),
      );
      await api.login(' a@example.org ', 'prueba');
      final restaurada = (await api.restaurar())!;
      expect(PanelMovil.pantalla(restaurada, () {}), isA<AdminScreen>());
      expect(PanelMovil.pantalla(sesion, () {}), isA<HomeScreen>());
    },
  );

  test('Un servidor antiguo o una página HTML no acreditan una sesión', () async {
    for (final body in ['<html>Error</html>', '{"success":true,"userId":"propio","nombre":"Ana","role":"CLIENTE"}']) {
      final api = ApiService(client: MockClient((_) async => http.Response(body, 200)));
      await expectLater(api.login('a@example.org', 'prueba'), throwsA(same(FalloLogin.respuestaIncompatible)));
      expect(await api.almacen.leer(), isNull);
    }
  });

  test('Una sesión rechazada o vencida requiere volver a entrar', () async {
    final api = ApiService(
      client: MockClient((_) async => http.Response('', 401)),
    );
    await api.almacen.guardar(sesion);
    expect(await api.restaurar(), isNull);
    expect(await api.almacen.leer(), isNull);
    await api.almacen.guardar(
      SesionMovil('propio', 'Ana', 'CLIENTE', 'antigua', DateTime.utc(2000)),
    );
    expect(await api.restaurar(), isNull);
  });

  test('El cierre borra la sesión local y pide su revocación', () async {
    final evento = <String>[];
    final api = ApiService(
      client: MockClient((req) async {
        evento.add(req.url.path);
        expect(req.headers['Authorization'], 'Bearer ${sesion.token}');
        return http.Response('', 204);
      }),
    );
    await api.almacen.guardar(sesion);
    await api.salir(sesion);
    await Future<void>.delayed(Duration.zero);
    expect(await api.almacen.leer(), isNull);
    expect(evento, ['/api/usuario/salir']);
  });

  test(
    'Citas distinguen la respuesta actual de la copia del mismo usuario',
    () async {
      var sinRed = false;
      final api = ApiService(
        client: MockClient((req) async {
          expect(req.headers['Authorization'], 'Bearer ${sesion.token}');
          if (sinRed) throw http.ClientException('sin conexión');
          return http.Response('[{"id":"c1"}]', 200);
        }),
      );
      expect((await api.getCitas(sesion)).desdeCache, isFalse);
      sinRed = true;
      final copia = await api.getCitas(sesion);
      expect(copia.desdeCache, isTrue);
      expect(copia.citas.single['id'], 'c1');
      expect(copia.actualizado, isNotNull);
      await api.almacen.guardar(sesion);
      expect((await api.restaurar())?.userId, sesion.userId);
    },
  );

  test(
    'Una denegación nunca recupera las citas ni el embudo de la caché',
    () async {
      await CacheService.cacheCitas([
        {'id': 'privada'},
      ], userId: sesion.userId);
      await CacheService.cacheEmbudo({'total': 12}, userId: sesion.userId);
      for (final estado in [401, 403]) {
        final api = ApiService(
          client: MockClient((_) async => http.Response('', estado)),
        );
        await expectLater(api.getCitas(sesion), throwsA(isA<AccesoDenegado>()));
        await expectLater(
          api.obtenerDatosEmbudo(sesion),
          throwsA(isA<AccesoDenegado>()),
        );
      }
    },
  );

  test(
    'Las cachés compartidas antiguas y las de otra cuenta quedan aisladas',
    () async {
      SharedPreferences.setMockInitialValues({
        'cache_citas': '[{"id":"antigua"}]',
        'cache_chat_history': '[{"text":"privado"}]',
        'cache_embudo': '{"total":42}',
        'cache_citas_timestamp': 'anterior',
      });
      await CacheService.cacheCitas([
        {'id': 'otra'},
      ], userId: 'otra');
      expect(await CacheService.getCachedCitas(userId: 'propio'), isEmpty);
      expect(
        await CacheService.getCitasCacheTimestamp(userId: 'propio'),
        isNull,
      );
      expect(
        await CacheService.getCachedChatHistory(userId: 'propio'),
        isEmpty,
      );
      expect(await CacheService.getCachedEmbudo(userId: 'propio'), isNull);
    },
  );
}
