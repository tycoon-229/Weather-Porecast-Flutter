import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/weather_utils.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  
  Map<WeatherType, Color> _weatherColors = {
    WeatherType.sunny: Colors.yellow,
    WeatherType.cloudy: Colors.blueGrey,
    WeatherType.rainy: Colors.blue,
    WeatherType.snowy: Colors.white,
    WeatherType.thunder: Colors.deepPurple,
  };

  Map<WeatherType, Color> get weatherColors => _weatherColors;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    for (var type in WeatherType.values) {
      int? colorValue = _prefs.getInt('color_${type.name}');
      if (colorValue != null) {
        _weatherColors[type] = Color(colorValue);
      }
    }
    notifyListeners();
  }

  Future<void> updateColor(WeatherType type, Color color) async {
    _weatherColors[type] = color;
    await _prefs.setInt('color_${type.name}', color.value);
    notifyListeners();
  }
}
