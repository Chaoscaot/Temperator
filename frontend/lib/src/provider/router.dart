import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pool_temp_app/src/provider/temperature.dart';
import 'package:pool_temp_app/src/screen/home/home_screen.dart';
import 'package:pool_temp_app/src/screen/init/init_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    ],
    redirect: (context, state) async {
      SharedPreferences prefs = await ref.read(prefsProvider.future);
      final device = prefs.getString("device");
      if (state.location == "/" && device == null) {
        return "/init";
      }
      return null;
    },
  );
});
