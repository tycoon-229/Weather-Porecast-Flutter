class HourlyWeather {
  final List<String> time;
  final List<double> temperature2m;
  final List<int> weatherCode;

  HourlyWeather({
    required this.time,
    required this.temperature2m,
    required this.weatherCode,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      time: List<String>.from(json['time'] ?? []),
      temperature2m: List<double>.from(
          (json['temperature_2m'] ?? []).map((x) => (x as num).toDouble())),
      weatherCode: List<int>.from(json['weather_code'] ?? []),
    );
  }
}