import 'package:dio/dio.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pool_temp_app/src/repository/temperature.dart';
import 'package:pool_temp_app/src/types/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

final remoteConfigProvider = FutureProvider((ref) async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.fetchAndActivate();
  return remoteConfig;
});

final prefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final baseUrlProvider = Provider<String>((ref) {
  return ref.watch(remoteConfigProvider).valueOrNull?.getString("base_url") ??
      "";
});

final httpProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      headers: {
        "X-Token":
            ref.watch(remoteConfigProvider).valueOrNull?.getString("token") ??
                "",
      },
      baseUrl: ref.watch(baseUrlProvider),
    ),
  );
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
