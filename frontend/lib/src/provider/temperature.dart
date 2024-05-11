import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pool_temp_app/src/repository/temperature.dart';
import 'package:pool_temp_app/src/token.dart';
import 'package:pool_temp_app/src/types/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final baseUrlProvider = Provider<String>((ref) {
  return "https://pool.chaoscaot.de/api/v1";
});

final httpProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      headers: {
        "X-Token": token,
      },
      baseUrl: ref.watch(baseUrlProvider),
    ),
  );
});

final deviceIdProvider = FutureProvider<String>((ref) {
  return SharedPreferences.getInstance().then((value) {
    return value.getString("device") ?? "";
  });
});

final repositoryProvider = Provider<PoolRepository>((ref) {
  return PoolRepository(ref.watch(httpProvider));
});

final currentTempProvider =
    FutureProvider.autoDispose<CurrentTemperature>((ref) async {
  return ref.watch(repositoryProvider).loadCurrent();
});

final chartDataProvider =
    FutureProvider.autoDispose<List<ChartData>>((ref) async {
  return ref.watch(repositoryProvider).loadChartData();
});
