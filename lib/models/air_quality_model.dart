import 'package:flutter/material.dart';

class AirQuality {
  final int aqi;
  final double pm25;
  final double pm10;
  final double carbonMonoxide;
  final double nitrogenDioxide;
  final double ozone;

  AirQuality({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.carbonMonoxide,
    required this.nitrogenDioxide,
    required this.ozone,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final current = json['current'] ?? {};
    return AirQuality(
      aqi: (current['us_aqi'] as num?)?.toInt() ?? 0,
      pm25: (current['pm2_5'] as num?)?.toDouble() ?? 0.0,
      pm10: (current['pm10'] as num?)?.toDouble() ?? 0.0,
      carbonMonoxide: (current['carbon_monoxide'] as num?)?.toDouble() ?? 0.0,
      nitrogenDioxide: (current['nitrogen_dioxide'] as num?)?.toDouble() ?? 0.0,
      ozone: (current['ozone'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ({String label, Color color, String advice}) getAqiStatus() {
    if (aqi <= 50) {
      return (
        label: 'Tốt',
        color: const Color(0xFF00E400),
        advice: 'Không khí trong lành, lý tưởng cho mọi hoạt động ngoài trời.',
      );
    } else if (aqi <= 100) {
      return (
        label: 'Trung bình',
        color: const Color(0xFFFF7E00),
        advice: 'Chất lượng chấp nhận được. Người quá nhạy cảm nên chú ý.',
      );
    } else if (aqi <= 150) {
      return (
        label: 'Kém',
        color: const Color(0xFFFF5050),
        advice: 'Nhóm nhạy cảm (trẻ nhỏ, người lớn tuổi) nên hạn chế ra ngoài.',
      );
    } else if (aqi <= 200) {
      return (
        label: 'Xấu',
        color: const Color(0xFFE60000),
        advice: 'Có hại cho sức khỏe. Nên đeo khẩu trang chống bụi PM2.5 khi ra ngoài.',
      );
    } else if (aqi <= 300) {
      return (
        label: 'Rất xấu',
        color: const Color(0xFF8F3F97),
        advice: 'Cảnh báo sức khỏe khẩn cấp! Tránh các hoạt động thể lực ngoài trời.',
      );
    } else {
      return (
        label: 'Nguy hại',
        color: const Color(0xFF7E0023),
        advice: 'Mức độ cực kỳ độc hại. Hạn chế tối đa ra ngoài, đóng kín cửa sổ.',
      );
    }
  }
}
