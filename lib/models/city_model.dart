class City {
  final String name;
  final double latitude;
  final double longitude;
  final String country;

  City({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      country: json['country'] ?? '',
    );
  }
}
