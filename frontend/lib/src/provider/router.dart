import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pool_temp_app/src/provider/temperature.dart';
import 'package:pool_temp_app/src/screen/home/home_screen.dart';
import 'package:pool_temp_app/src/screen/init/init_screen.dart';
import 'package:pool_temp_app/src/screen/misc/error_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../screen/misc/offline_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
        path: '/init',
        builder: (context, state) => const SetupScreen(),
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
                stackTrace: "Ein unbekannter Fehler ist aufgetreten",
              ),
            );
          }

          return ErrorScreen(errorObject: error);
        },
      )
    ],
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      ConnectivityResult connectivityResult =
          await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return "/offline";
      }

      SharedPreferences prefs = await ref.read(prefsProvider.future);
      final device = prefs.getString("device");
      if (state.location == "/" && device == null) {
        return "/init";
      }
      return null;
    },
  );
});
