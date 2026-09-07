import 'package:flutter/material.dart';
import 'package:weather_animation/weather_animation.dart';
import '../utils/weather_utils.dart';

class WeatherAnimationWrapper extends StatelessWidget {
  final int weatherCode;
  final Map<WeatherType, Color> customColors;
  final Widget? child;

  const WeatherAnimationWrapper({
    super.key,
    required this.weatherCode,
    required this.customColors,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final type = WeatherUtils.getWeatherType(weatherCode);
    final scene = WeatherUtils.getSchema(type, customColors[type]!);

    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WrapperScene.weather(
            scene: scene,
            sizeCanvas: size,
            colors: [customColors[type]!.withOpacity(0.8), customColors[type]!],
          ),
          if (child != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
              child: child!,
            ),
        ],
      ),
    );
  }
}