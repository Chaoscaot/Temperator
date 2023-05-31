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
  return "http://192.168.178.36:8080";
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

final deviceProvider = Provider.family<PoolRepository, String>((ref, devId) {
  return PoolRepository(ref.watch(httpProvider), devId);
});

final emptyDeviceProvider = Provider<PoolRepository>((ref) {
  return PoolRepository(ref.watch(httpProvider), "");
});

final currentTempProvider = FutureProvider.family
    .autoDispose<CurrentTemperature, String>((ref, devId) async {
  return ref.watch(deviceProvider(devId)).loadCurrent();
});

final devicesProvider = FutureProvider<List<Device>>((ref) async {
  return ref.watch(emptyDeviceProvider).loadDevices();
});

final chartDataProvider = FutureProvider.autoDispose
    .family<List<ChartData>, String>((ref, devId) async {
  return ref.watch(deviceProvider(devId)).loadChartData();
});
