// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentTemperature _$CurrentTemperatureFromJson(Map<String, dynamic> json) =>
    CurrentTemperature(
      time: DateTime.parse(json['Time'] as String),
      deviceID: json['DeviceID'] as String,
      humidity: (json['Humidity'] as num).toDouble(),
      outsideTemp: (json['OutsideTemp'] as num).toDouble(),
      waterTemp: (json['WaterTemp'] as num).toDouble(),
    );

Map<String, dynamic> _$CurrentTemperatureToJson(CurrentTemperature instance) =>
    <String, dynamic>{
      'Time': instance.time.toIso8601String(),
      'DeviceID': instance.deviceID,
      'Humidity': instance.humidity,
      'OutsideTemp': instance.outsideTemp,
      'WaterTemp': instance.waterTemp,
    };

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
      json['DevId'] as String,
      json['Name'] as String,
    );

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
      'DevId': instance.id,
      'Name': instance.name,
    };

ChartData _$ChartDataFromJson(Map<String, dynamic> json) => ChartData(
      json['Hourcol'] as int,
      (json['Humidity'] as num).toDouble(),
      (json['OutsideTemp'] as num).toDouble(),
      (json['WaterTemp'] as num).toDouble(),
    );

Map<String, dynamic> _$ChartDataToJson(ChartData instance) => <String, dynamic>{
      'Hourcol': instance.time,
      'Humidity': instance.humidity,
      'OutsideTemp': instance.outsideTemp,
      'WaterTemp': instance.waterTemp,
    };
