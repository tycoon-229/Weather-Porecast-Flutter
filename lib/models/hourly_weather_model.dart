class HourlyWeather {
  final List<String> time;
  final List<double> temperature2m;
  final List<int> weatherCode;
  final List<int> precipitationProbability;
  final List<double> uvIndex;

  HourlyWeather({
    required this.time,
    required this.temperature2m,
    required this.weatherCode,
    this.precipitationProbability = const [],
    this.uvIndex = const [],
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      time: List<String>.from(json['time'] ?? []),
      temperature2m: List<double>.from(
          (json['temperature_2m'] ?? []).map((x) => (x as num).toDouble())),
      weatherCode: List<int>.from(json['weather_code'] ?? []),
      precipitationProbability: List<int>.from(
          (json['precipitation_probability'] ?? []).map((x) => (x as num).toInt())),
      uvIndex: List<double>.from(
          (json['uv_index'] ?? []).map((x) => (x as num).toDouble())),
    );
  }
}