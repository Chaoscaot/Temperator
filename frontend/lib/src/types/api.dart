import 'package:json_annotation/json_annotation.dart';

part 'api.g.dart';

@JsonSerializable()
class CurrentTemperature {
  @JsonKey(name: 'Time')
  DateTime time;
  @JsonKey(name: "DeviceID")
  String deviceID;
  @JsonKey(name: "Humidity")
  double humidity;
  @JsonKey(name: "OutsideTemp")
  double outsideTemp;
  @JsonKey(name: "WaterTemp")
  double waterTemp;

  CurrentTemperature({
    required this.time,
    required this.deviceID,
    required this.humidity,
    required this.outsideTemp,
    required this.waterTemp,
  });

  factory CurrentTemperature.fromJson(Map<String, dynamic> json) =>
      _$CurrentTemperatureFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentTemperatureToJson(this);
}

@JsonSerializable()
class Device {
  @JsonKey(name: "DevId")
  final String id;
  @JsonKey(name: "Name")
  final String name;

  Device(this.id, this.name);

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceToJson(this);
}

@JsonSerializable()
class ChartData {
  @JsonKey(name: "Hourcol")
  final int time;
  @JsonKey(name: "Humidity")
  final double humidity;
  @JsonKey(name: "OutsideTemp")
  final double outsideTemp;
  @JsonKey(name: "WaterTemp")
  final double waterTemp;

  ChartData(this.time, this.humidity, this.outsideTemp, this.waterTemp);

  factory ChartData.fromJson(Map<String, dynamic> json) =>
      _$ChartDataFromJson(json);
  Map<String, dynamic> toJson() => _$ChartDataToJson(this);
}
