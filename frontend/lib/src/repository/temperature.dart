import 'package:flutter/material.dart';
import 'package:pool_temp_app/src/types/api.dart';
import 'package:dio/dio.dart';

class PoolRepository {
  final Dio _dio;
  final String _device;

  PoolRepository(this._dio, this._device);

  Future<CurrentTemperature> loadCurrent() {
    return _dio
        .get("/api/v1/devices/$_device/current")
        .then((value) => CurrentTemperature.fromJson(value.data));
  }

  Future<List<ChartData>> loadChartData() {
    return _dio.get("/api/v1/devices/$_device/chart").then((value) =>
        (value.data as List<dynamic>)
            .map((e) => ChartData.fromJson(e))
            .toList());
  }

  Future<List<Device>> loadDevices() {
    return _dio.get("/api/v1/devices").then((value) =>
        (value.data as List<dynamic>).map((e) => Device.fromJson(e)).toList());
  }
}
