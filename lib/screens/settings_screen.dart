import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/settings_provider.dart';
import '../utils/weather_utils.dart';

// ─── Shared design tokens ────────────────────────────────────────────────────
const Color _kBg = Color(0xFF0F1923);
const Color _kSurface = Color(0xFF1A2535);
const Color _kBorder = Color(0x33FFFFFF);
const Color _kText = Colors.white;
const Color _kTextSub = Color(0xFFB0BEC5);
const Color _kAccent = Color(0xFF3B82F6);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kText,
        elevation: 0,
        title: const Text(
          'Màu sắc theo thời tiết',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Header info
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kAccent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: _kAccent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Màu được dùng cho AppBar, nền và thẻ thời tiết trên màn hình chính.',
                    style: TextStyle(color: _kTextSub, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // Color tiles
          ...WeatherType.values.map((type) {
            final currentColor = settingsProv.weatherColors[type] ?? Colors.blue;
            return _WeatherColorTile(
              type: type,
              color: currentColor,
              onTap: () =>
                  _showColorPicker(context, settingsProv, type, currentColor),
            );
          }),
        ],
      ),
    );
  }

  String _getWeatherTypeName(WeatherType type) {
    switch (type) {
      case WeatherType.sunny:
        return 'Trời nắng';
      case WeatherType.cloudy:
        return 'Nhiều mây';
      case WeatherType.rainy:
        return 'Trời mưa';
      case WeatherType.snowy:
        return 'Có tuyết';
      case WeatherType.thunder:
        return 'Có dông';
    }
  }


  IconData _getWeatherTypeIcon(WeatherType type) {
    switch (type) {
      case WeatherType.sunny:
        return Icons.wb_sunny_outlined;
      case WeatherType.cloudy:
        return Icons.cloud_outlined;
      case WeatherType.rainy:
        return Icons.grain;
      case WeatherType.snowy:
        return Icons.ac_unit;
      case WeatherType.thunder:
        return Icons.thunderstorm_outlined;
    }
  }

  void _showColorPicker(
    BuildContext context,
    SettingsProvider provider,
    WeatherType type,
    Color initialColor,
  ) {
    Color pickerColor = initialColor;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: _kSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: pickerColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: pickerColor.withOpacity(0.4)),
                        ),
                        child: Icon(
                          _getWeatherTypeIcon(type),
                          color: pickerColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getWeatherTypeName(type),
                            style: const TextStyle(
                              color: _kText,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Chọn màu sắc',
                            style: const TextStyle(
                                color: _kTextSub, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: _kBorder),
                  const SizedBox(height: 8),

                  // Color picker
                  ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) {
                      setDialogState(() => pickerColor = color);
                    },
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: false,
                    displayThumbColor: true,
                    labelTypes: const [],
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kTextSub,
                            side: const BorderSide(color: _kBorder),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pickerColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            provider.updateColor(type, pickerColor);
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Lưu',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

// ── Tile card cho mỗi loại thời tiết ─────────────────────────────────────────

class _WeatherColorTile extends StatelessWidget {
  const _WeatherColorTile({
    required this.type,
    required this.color,
    required this.onTap,
  });

  final WeatherType type;
  final Color color;
  final VoidCallback onTap;

  String get _typeName {
    switch (type) {
      case WeatherType.sunny: return 'Trời nắng';
      case WeatherType.cloudy: return 'Nhiều mây';
      case WeatherType.rainy: return 'Trời mưa';
      case WeatherType.snowy: return 'Có tuyết';
      case WeatherType.thunder: return 'Có dông';
    }
  }

  String get _typeSubtitle {
    switch (type) {
      case WeatherType.sunny: return 'Sunny / Clear sky';
      case WeatherType.cloudy: return 'Cloudy / Overcast';
      case WeatherType.rainy: return 'Rainy / Drizzle / Fog';
      case WeatherType.snowy: return 'Snowy / Freezing';
      case WeatherType.thunder: return 'Thunderstorm';
    }
  }

  IconData get _typeIcon {
    switch (type) {
      case WeatherType.sunny: return Icons.wb_sunny_outlined;
      case WeatherType.cloudy: return Icons.cloud_outlined;
      case WeatherType.rainy: return Icons.grain;
      case WeatherType.snowy: return Icons.ac_unit;
      case WeatherType.thunder: return Icons.thunderstorm_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            // Icon in colored circle
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Icon(_typeIcon, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeName,
                    style: const TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _typeSubtitle,
                    style: const TextStyle(color: _kTextSub, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Color preview + edit hint
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đổi',
                  style: TextStyle(
                      color: _kAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
