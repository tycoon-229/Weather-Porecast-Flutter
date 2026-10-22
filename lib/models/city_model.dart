class City {
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final bool isCurrentLocation;

  City({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.isCurrentLocation = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'country': country,
    'isCurrentLocation': isCurrentLocation,
  };

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      country: json['country'] ?? '',
      isCurrentLocation: json['isCurrentLocation'] ?? false,
    );
  }

  City copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? country,
    bool? isCurrentLocation,
  }) {
    return City(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          (latitude - other.latitude).abs() < 0.01 &&
          (longitude - other.longitude).abs() < 0.01;

  @override
  int get hashCode => name.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}
