import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pool_temp_app/src/screen/home/home_screen.dart';
import 'package:pool_temp_app/src/screen/load/load_screen.dart';
import 'package:pool_temp_app/src/screen/misc/error_screen.dart';

import '../screen/misc/offline_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
        path: '/offline',
        builder: (context, state) => const OfflineScreen(),
      ),
      GoRoute(
        path: "/error",
        builder: (context, state) {
          Object? error = state.extra;
          if (error == null || error is! ErrorObject) {
            return ErrorScreen(
              errorObject: ErrorObject(
                error: "Unbekannter Fehler",
                stackTrace: null,
              ),
            );
          }

          return ErrorScreen(errorObject: error);
        },
      ),
      GoRoute(
        path: "/load",
        builder: (context, state) => const LoadingScreen(),
      ),
    ],
    initialLocation: "/load",
    debugLogDiagnostics: true,
  );
});
