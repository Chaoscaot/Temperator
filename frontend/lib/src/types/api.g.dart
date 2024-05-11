// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentTemperature _$CurrentTemperatureFromJson(Map<String, dynamic> json) =>
    CurrentTemperature(
      time: (json['time'] as num).toInt(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      outsideTemp: (json['air_temp'] as num?)?.toDouble(),
      waterTemp: (json['water_temp'] as num?)?.toDouble(),
      pump: json['pump'] as bool?,
      lastPumpToggle: (json['last_pump_toggle'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CurrentTemperatureToJson(CurrentTemperature instance) =>
    <String, dynamic>{
      'time': instance.time,
      'humidity': instance.humidity,
      'air_temp': instance.outsideTemp,
      'water_temp': instance.waterTemp,
      'pump': instance.pump,
      'last_pump_toggle': instance.lastPumpToggle,
    };

ChartData _$ChartDataFromJson(Map<String, dynamic> json) => ChartData(
      (json['hour'] as num).toInt(),
      (json['humidity'] as num).toDouble(),
      (json['air_temp'] as num).toDouble(),
      (json['water_temp'] as num).toDouble(),
    );

Map<String, dynamic> _$ChartDataToJson(ChartData instance) => <String, dynamic>{
      'hour': instance.time,
      'humidity': instance.humidity,
      'air_temp': instance.outsideTemp,
      'water_temp': instance.waterTemp,
    };
