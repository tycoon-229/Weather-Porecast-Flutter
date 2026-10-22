import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../models/city_model.dart';
import '../services/weather_api_service.dart';
import '../utils/weather_utils.dart';

class WeatherProvider with ChangeNotifier {
  static const String _favCitiesKey = 'favorite_cities_list_v1';

  final WeatherApiService _apiService = WeatherApiService();

  List<City> _favoriteCities = [];
  List<City> get favoriteCities => List.unmodifiable(_favoriteCities);

  City? _currentGpsCity;
  City? get currentGpsCity => _currentGpsCity;

  // Thành phố tuỳ chọn tạm thời (khi chọn từ tìm kiếm hoặc bản đồ mà chưa lưu)
  City? _customSelectedCity;

  int _selectedCityIndex = 0;
  int get selectedCityIndex => _selectedCityIndex;

  // Bộ nhớ cache dữ liệu thời tiết theo tọa độ
  final Map<String, WeatherData> _weatherCache = {};
  Map<String, WeatherData> get weatherCache => _weatherCache;

  WeatherData? _weatherData;
  WeatherData? get weatherData => _weatherData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Danh sách tất cả thành phố đang hiển thị trong PageView
  List<City> get allCities {
    final List<City> list = [];
    if (_currentGpsCity != null) {
      list.add(_currentGpsCity!);
    }
    for (final city in _favoriteCities) {
      if (!list.any((c) => c == city)) {
        list.add(city);
      }
    }
    if (_customSelectedCity != null && !list.any((c) => c == _customSelectedCity)) {
      list.add(_customSelectedCity!);
    }
    if (list.isEmpty) {
      list.add(WeatherUtils.vietnamCities[0]);
    }
    return list;
  }

  City get selectedCity {
    final cities = allCities;
    if (_selectedCityIndex >= cities.length) {
      _selectedCityIndex = 0;
    }
    return cities[_selectedCityIndex];
  }

  WeatherProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadFavoriteCities();
    await fetchWeatherForSelectedCity();
    // Tự động tải trước dữ liệu thời tiết cho các thành phố yêu thích
    preloadFavoritesWeather();
  }

  String _cacheKey(double lat, double lon) =>
      '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';

  WeatherData? getWeatherForCity(City city) =>
      _weatherCache[_cacheKey(city.latitude, city.longitude)];

  Future<void> loadFavoriteCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_favCitiesKey);
      if (listJson != null && listJson.isNotEmpty) {
        _favoriteCities = listJson
            .map((str) => City.fromJson(json.decode(str)))
            .toList();
      } else {
        // Mặc định 3 thành phố lớn tiêu biểu của 3 miền
        _favoriteCities = [
          WeatherUtils.vietnamCities[0], // Hà Nội
          WeatherUtils.vietnamCities[1], // TP. Hồ Chí Minh
          WeatherUtils.vietnamCities[2], // Đà Nẵng
        ];
        await _saveFavoriteCities();
      }
    } catch (_) {
      _favoriteCities = [WeatherUtils.vietnamCities[0]];
    }
    notifyListeners();
  }

  Future<void> _saveFavoriteCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson =
          _favoriteCities.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(_favCitiesKey, listJson);
    } catch (_) {}
  }

  bool isFavorite(City city) {
    return _favoriteCities.any((c) =>
        c.name == city.name ||
        ((c.latitude - city.latitude).abs() < 0.02 &&
            (c.longitude - city.longitude).abs() < 0.02));
  }

  Future<void> toggleFavorite(City city) async {
    if (isFavorite(city)) {
      await removeFavorite(city);
    } else {
      await addFavorite(city);
    }
  }

  Future<void> addFavorite(City city) async {
    if (!isFavorite(city)) {
      _favoriteCities.add(city.copyWith(isCurrentLocation: false));
      await _saveFavoriteCities();
      fetchWeatherForCity(city);
      notifyListeners();
    }
  }

  Future<void> removeFavorite(City city) async {
    _favoriteCities.removeWhere((c) =>
        c.name == city.name ||
        ((c.latitude - city.latitude).abs() < 0.02 &&
            (c.longitude - city.longitude).abs() < 0.02));
    await _saveFavoriteCities();

    if (_selectedCityIndex >= allCities.length) {
      _selectedCityIndex = (allCities.length - 1).clamp(0, allCities.length);
    }
    notifyListeners();
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final city = _favoriteCities.removeAt(oldIndex);
    _favoriteCities.insert(newIndex, city);
    await _saveFavoriteCities();
    notifyListeners();
  }

  void selectCityIndex(int index) {
    final cities = allCities;
    if (index >= 0 && index < cities.length) {
      _selectedCityIndex = index;
      final city = cities[index];
      // Nếu đã có trong cache thì gán ngay để hiển thị mượt mà
      final cached = getWeatherForCity(city);
      if (cached != null) {
        _weatherData = cached;
      }
      fetchWeatherForSelectedCity();
    }
  }

  void selectCity(City city) {
    final cities = allCities;
    final existingIndex = cities.indexWhere((c) =>
        c.name == city.name ||
        ((c.latitude - city.latitude).abs() < 0.02 &&
            (c.longitude - city.longitude).abs() < 0.02));

    if (existingIndex != -1) {
      _selectedCityIndex = existingIndex;
    } else {
      _customSelectedCity = city;
      _selectedCityIndex = allCities.length - 1;
    }

    final cached = getWeatherForCity(city);
    if (cached != null) {
      _weatherData = cached;
    }
    fetchWeatherForSelectedCity();
  }

  Future<WeatherData?> fetchWeatherForCity(City city) async {
    try {
      final data = await _apiService.fetchWeather(city.latitude, city.longitude);
      _weatherCache[_cacheKey(city.latitude, city.longitude)] = data;
      notifyListeners();
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> preloadFavoritesWeather() async {
    for (final city in _favoriteCities) {
      fetchWeatherForCity(city);
    }
  }

  Future<void> fetchWeatherForSelectedCity() async {
    final city = selectedCity;
    final cached = getWeatherForCity(city);
    if (cached != null) {
      _weatherData = cached;
      _isLoading = false;
    } else {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.fetchWeather(city.latitude, city.longitude);
      _weatherData = data;
      _weatherCache[_cacheKey(city.latitude, city.longitude)] = data;
    } catch (e) {
      if (_weatherData == null) {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWeather() async {
    final city = selectedCity;
    try {
      final data = await _apiService.fetchWeather(city.latitude, city.longitude);
      _weatherData = data;
      _weatherCache[_cacheKey(city.latitude, city.longitude)] = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchWeatherForCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Dịch vụ định vị GPS chưa được bật.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối');
        }
      }

      Position position = await Geolocator.getCurrentPosition();

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      String cityName = placemarks.isNotEmpty
          ? (placemarks[0].locality ?? placemarks[0].subAdministrativeArea ?? 'Vị trí hiện tại')
          : 'Vị trí hiện tại';

      _currentGpsCity = City(
        name: cityName,
        latitude: position.latitude,
        longitude: position.longitude,
        country: placemarks.isNotEmpty ? placemarks[0].country ?? 'VN' : 'VN',
        isCurrentLocation: true,
      );

      _selectedCityIndex = 0; // Đưa về vị trí đầu tiên
      final data = await _apiService.fetchWeather(position.latitude, position.longitude);
      _weatherData = data;
      _weatherCache[_cacheKey(position.latitude, position.longitude)] = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeatherForCustomLocation(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isEmpty) throw Exception('Không tìm thấy địa điểm này.');

      Location location = locations.first;
      List<Placemark> placemarks =
          await placemarkFromCoordinates(location.latitude, location.longitude);
      String cityName =
          placemarks.isNotEmpty ? (placemarks[0].locality ?? query) : query;

      final newCity = City(
        name: cityName,
        latitude: location.latitude,
        longitude: location.longitude,
        country: placemarks.isNotEmpty ? placemarks[0].country ?? 'VN' : 'VN',
      );

      selectCity(newCity);
    } catch (e) {
      _error = 'Không thể tìm thấy địa điểm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeatherForCoordinates(
    double lat,
    double lon,
    String locationName,
  ) async {
    final newCity = City(
      name: locationName,
      latitude: lat,
      longitude: lon,
      country: 'VN',
    );
    selectCity(newCity);
  }
}