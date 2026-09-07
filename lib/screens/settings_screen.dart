import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/settings_provider.dart';
import '../utils/weather_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tùy chỉnh màu sắc thời tiết'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: WeatherType.values.map((type) {
          final currentColor = settingsProv.weatherColors[type] ?? Colors.blue;
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                _getWeatherTypeName(type),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                'Nhấn để đổi màu chủ đạo',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
              onTap: () {
                _showAdvancedColorPicker(context, settingsProv, type, currentColor);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getWeatherTypeName(WeatherType type) {
    switch (type) {
      case WeatherType.sunny: return 'Trời nắng (Sunny)';
      case WeatherType.cloudy: return 'Nhiều mây (Cloudy)';
      case WeatherType.rainy: return 'Trời mưa (Rainy)';
      case WeatherType.snowy: return 'Có tuyết (Snowy)';
      case WeatherType.thunder: return 'Có dông (Thunder)';
    }
  }

  void _showAdvancedColorPicker(
    BuildContext context,
    SettingsProvider provider,
    WeatherType type,
    Color initialColor,
  ) {
    Color pickerColor = initialColor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn màu sắc'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.updateColor(type, pickerColor);
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}
