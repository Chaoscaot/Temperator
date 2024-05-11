import 'package:json_annotation/json_annotation.dart';

part 'api.g.dart';

@JsonSerializable()
class CurrentTemperature {
  @JsonKey(name: 'time')
  int time;
  @JsonKey(name: "humidity")
  double? humidity;
  @JsonKey(name: "air_temp")
  double? outsideTemp;
  @JsonKey(name: "water_temp")
  double? waterTemp;
  @JsonKey(name: "pump")
  bool? pump;
  @JsonKey(name: "last_pump_toggle")
  int? lastPumpToggle;

  CurrentTemperature({
    required this.time,
    required this.humidity,
    required this.outsideTemp,
    required this.waterTemp,
    required this.pump,
    required this.lastPumpToggle,
  });

  factory CurrentTemperature.fromJson(Map<String, dynamic> json) =>
      _$CurrentTemperatureFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentTemperatureToJson(this);
}

@JsonSerializable()
class ChartData {
  @JsonKey(name: "hour")
  final int time;
  @JsonKey(name: "humidity")
  final double humidity;
  @JsonKey(name: "air_temp")
  final double outsideTemp;
  @JsonKey(name: "water_temp")
  final double waterTemp;

  ChartData(this.time, this.humidity, this.outsideTemp, this.waterTemp);

  factory ChartData.fromJson(Map<String, dynamic> json) =>
      _$ChartDataFromJson(json);
  Map<String, dynamic> toJson() => _$ChartDataToJson(this);
}
