import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/weather_model.dart';
import '../models/city_model.dart';
import '../services/weather_api_service.dart';
import '../utils/weather_utils.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherApiService _apiService = WeatherApiService();
  
  WeatherData? _weatherData;
  WeatherData? get weatherData => _weatherData;

  City _selectedCity = WeatherUtils.vietnamCities[0];
  City get selectedCity => _selectedCity;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  WeatherProvider() {
    fetchWeatherForSelectedCity();
  }

  void selectCity(City city) {
    _selectedCity = city;
    fetchWeatherForSelectedCity();
  }

  Future<void> fetchWeatherForSelectedCity() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _weatherData = await _apiService.fetchWeather(_selectedCity.latitude, _selectedCity.longitude);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeatherForCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permissions are denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String cityName = placemarks.isNotEmpty ? placemarks[0].locality ?? 'Vị trí hiện tại' : 'Vị trí hiện tại';

      _selectedCity = City(
        name: cityName,
        latitude: position.latitude,
        longitude: position.longitude,
        country: placemarks.isNotEmpty ? placemarks[0].country ?? '' : '',
      );

      _weatherData = await _apiService.fetchWeather(position.latitude, position.longitude);
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
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      String cityName = placemarks.isNotEmpty ? (placemarks[0].locality ?? query) : query;

      _selectedCity = City(
        name: cityName,
        latitude: location.latitude,
        longitude: location.longitude,
        country: placemarks.isNotEmpty ? placemarks[0].country ?? 'VN' : 'VN',
      );

      _weatherData = await _apiService.fetchWeather(location.latitude, location.longitude);
    } catch (e) {
      _error = 'Không thể tìm thấy địa điểm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
