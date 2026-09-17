import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/hourly_weather_model.dart';
import '../providers/weather_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_animation_wrapper.dart';
import 'map_picker_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến chuyển tab giữa "Biểu đồ" và "Danh sách"
  bool _showChartTab = true;

  @override
  Widget build(BuildContext context) {
    return Consumer2<WeatherProvider, SettingsProvider>(
      builder: (context, weatherProv, settingsProv, child) {
        final weatherCode = weatherProv.weatherData?.current.weatherCode ?? 0;
        final type = WeatherUtils.getWeatherType(weatherCode);
        final appBarColor = settingsProv.weatherColors[type] ?? Colors.blue;
        final isDark = ThemeData.estimateBrightnessForColor(appBarColor) == Brightness.dark;

        return Scaffold(
          appBar: // Thay thế nút IconButton tìm kiếm trong appBar của HomeScreen:
          AppBar(
            backgroundColor: appBarColor,
            foregroundColor: isDark ? Colors.white : Colors.black,
            title: const Text('Thời tiết Việt Nam'),
            actions: [
              IconButton(
                icon: const Icon(Icons.map_outlined), // Đổi sang icon bản đồ
                tooltip: 'Chọn vị trí trên bản đồ',
                onPressed: () async {
                  // Mở màn hình bản đồ và đợi người dùng chọn vị trí
                  final LocationResult? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapPickerScreen(),
                    ),
                  );

                  // Khi người dùng bấm "Xem thời tiết tại đây"
                  if (result != null && context.mounted) {
                    context.read<WeatherProvider>().fetchWeatherForCoordinates(
                      result.latitude,
                      result.longitude,
                      result.displayName,
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: 'Vị trí hiện tại',
                onPressed: () {
                  weatherProv.fetchWeatherForCurrentLocation();
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Cài đặt màu sắc',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: _buildBody(context, weatherProv, settingsProv),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WeatherProvider weatherProv, SettingsProvider settingsProv) {
    if (weatherProv.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (weatherProv.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Lỗi: ${weatherProv.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    final data = weatherProv.weatherData;
    if (data == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return WeatherAnimationWrapper(
      weatherCode: data.current.weatherCode,
      customColors: settingsProv.weatherColors,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: _buildCitySelector(context, weatherProv),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    '${data.current.temperature.round()}°C',
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                  ),
                  Text(
                    WeatherUtils.getWeatherDescription(data.current.weatherCode),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildWeatherDetails(data.current),
                  const SizedBox(height: 30),
                  _buildHourlyForecast(data.hourly),
                  const SizedBox(height: 30),

                  // Biểu đồ dự báo nhiều ngày tương tự mẫu ảnh
                  _buildMultiDayForecastCard(context, data.daily),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card dự báo nhiều ngày (Hỗ trợ chuyển đổi Biểu đồ / Danh sách)
  Widget _buildMultiDayForecastCard(BuildContext context, dynamic daily) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tiêu đề + Tabs Biểu đồ / Danh sách
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dự báo thời tiết nhiều ngày',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _tabButton(label: 'Biểu đồ', isSelected: _showChartTab, onTap: () {
                      setState(() => _showChartTab = true);
                    }),
                    _tabButton(label: 'Danh sách', isSelected: !_showChartTab, onTap: () {
                      setState(() => _showChartTab = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nội dung hiển thị dạng Biểu đồ hoặc Danh sách
          _showChartTab
              ? _buildMultiDayChartContent(daily)
              : _buildDailyListView(daily),
        ],
      ),
    );
  }

  Widget _tabButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  // Nội dung biểu đồ tương tự giao diện mẫu
  Widget _buildMultiDayChartContent(dynamic daily) {
    final int count = daily.time.length;
    const double columnWidth = 85.0; // Chiều rộng mỗi cột ngày
    final double totalWidth = count * columnWidth;

    List<FlSpot> maxSpots = [];
    List<FlSpot> minSpots = [];
    double minTempOverall = double.infinity;
    double maxTempOverall = double.negativeInfinity;

    for (int i = 0; i < count; i++) {
      double maxT = (daily.temperatureMax[i] as num).toDouble();
      double minT = (daily.temperatureMin[i] as num).toDouble();

      maxSpots.add(FlSpot(i.toDouble(), maxT));
      minSpots.add(FlSpot(i.toDouble(), minT));

      if (minT < minTempOverall) minTempOverall = minT;
      if (maxT > maxTempOverall) maxTempOverall = maxT;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            // 1. Cột thông tin: Thứ, ngày, thời tiết, icon, % mưa
            Row(
              children: List.generate(count, (index) {
                final date = DateTime.parse(daily.time[index]);
                String dayTitle;
                if (index == 0) {
                  dayTitle = 'Hôm nay';
                } else if (index == 1) {
                  dayTitle = 'Ngày mai';
                } else {
                  dayTitle = DateFormat('E', 'vi_VN').format(date);
                }

                final dateStr = DateFormat('dd/MM').format(date);
                final desc = WeatherUtils.getWeatherDescription(daily.weatherCode[index]);

                return SizedBox(
                  width: columnWidth,
                  child: Column(
                    children: [
                      Text(
                        dayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: Text(
                          desc,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Icon(Icons.cloud_queue, color: Colors.white, size: 26),
                      const SizedBox(height: 4),
                      Text(
                        '60%',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      // Nhãn nhiệt độ Max hiển thị ngay trên đỉnh đường vẽ
                      Text(
                        '${daily.temperatureMax[index].round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 6),

            // 2. Biểu đồ đường kép (Nhiệt độ Max & Min)
            SizedBox(
              height: 70,
              width: totalWidth,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (count - 1).toDouble(),
                  minY: minTempOverall - 2,
                  maxY: maxTempOverall + 2,
                  clipData: const FlClipData.none(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    // Đường Max Temp (Đường trên)
                    LineChartBarData(
                      spots: maxSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.white,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 3.5,
                              color: Colors.white,
                              strokeWidth: 0,
                            ),
                      ),
                    ),
                    // Đường Min Temp (Đường dưới)
                    LineChartBarData(
                      spots: minSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.white.withOpacity(0.4),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 3.5,
                              color: Colors.white70,
                              strokeWidth: 0,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 3. Nhãn nhiệt độ Min đặt ngay dưới đường vẽ
            Row(
              children: List.generate(count, (index) {
                return SizedBox(
                  width: columnWidth,
                  child: Center(
                    child: Text(
                      '${daily.temperatureMin[index].round()}°',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Danh sách 7 ngày (Tab Danh sách)
  Widget _buildDailyListView(dynamic daily) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: daily.time.length,
      separatorBuilder: (context, index) => Divider(height: 14, color: Colors.white.withOpacity(0.15)),
      itemBuilder: (context, index) {
        final date = DateTime.parse(daily.time[index]);
        final dayName = index == 0 ? 'Hôm nay' : DateFormat('EEEE', 'vi_VN').format(date);
        final desc = WeatherUtils.getWeatherDescription(daily.weatherCode[index]);
        final maxTemp = '${daily.temperatureMax[index].round()}°';
        final minTemp = '${daily.temperatureMin[index].round()}°';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                dayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
              ),
            ),
            Expanded(
              child: Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
            ),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    maxTemp,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    minTemp,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCitySelector(BuildContext context, WeatherProvider provider) {
    List<String> cityNames = WeatherUtils.vietnamCities.map((c) => c.name).toList();
    if (!cityNames.contains(provider.selectedCity.name)) {
      cityNames.add(provider.selectedCity.name);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: provider.selectedCity.name,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.blue),
            onChanged: (value) {
              try {
                final city = WeatherUtils.vietnamCities.firstWhere((c) => c.name == value);
                provider.selectCity(city);
              } catch (_) {}
            },
            items: cityNames.map((name) {
              return DropdownMenuItem(
                value: name,
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(dynamic data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _detailItem(Icons.water_drop, '${data.humidity}%', 'Độ ẩm'),
          Container(height: 30, width: 1, color: Colors.white38),
          _detailItem(Icons.air, '${data.windSpeed} km/h', 'Gió'),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.lightBlueAccent, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(HourlyWeather hourlyData) {
    final DateTime now = DateTime.now();

    int startIndex = 0;
    for (int i = 0; i < hourlyData.time.length; i++) {
      final DateTime apiTime = DateTime.parse(hourlyData.time[i]);
      if (apiTime.year == now.year &&
          apiTime.month == now.month &&
          apiTime.day == now.day &&
          apiTime.hour == now.hour) {
        startIndex = i;
        break;
      }
    }

    final int remainingHours = hourlyData.time.length - startIndex;
    final int itemCount = remainingHours > 24 ? 24 : remainingHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Dự báo 24 giờ tới',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final int realIndex = startIndex + index;
              final DateTime date = DateTime.parse(hourlyData.time[realIndex]);
              final String timeString = index == 0 ? "Bây giờ" : "${date.hour.toString().padLeft(2, '0')}:00";
              final double temp = hourlyData.temperature2m[realIndex];

              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: index == 0 ? Border.all(color: Colors.white54, width: 1) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeString,
                      style: TextStyle(
                        color: index == 0 ? Colors.white : Colors.white70,
                        fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.cloud, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      '${temp.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tìm kiếm địa điểm'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nhập tên thành phố (ví dụ: Đà Lạt, Nha Trang...)',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final query = controller.text.trim();
                if (query.isNotEmpty) {
                  context.read<WeatherProvider>().fetchWeatherForCustomLocation(query);
                  Navigator.pop(context);
                }
              },
              child: const Text('Tìm kiếm'),
            ),
          ],
        );
      },
    );
  }
}