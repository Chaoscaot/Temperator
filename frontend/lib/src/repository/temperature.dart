import 'package:pool_temp_app/src/types/api.dart';
import 'package:dio/dio.dart';

class PoolRepository {
  final Dio _dio;

  PoolRepository(this._dio);

  Future<CurrentTemperature> loadCurrent() {
    return _dio
        .get("/current")
        .then((value) => CurrentTemperature.fromJson(value.data));
  }

  Future<List<ChartData>> loadChartData() {
    return _dio.get("/chart").then((value) =>
        ((value.data ?? []) as List<dynamic>)
            .map((e) => ChartData.fromJson(e))
            .toList());
  }

  Future<bool> togglePump() {
    return _dio.post("/pump").then((value) => value.data == "true");
  }
}
