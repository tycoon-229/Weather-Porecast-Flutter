import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/hourly_weather_model.dart';
import '../providers/weather_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_animation_wrapper.dart';
import 'settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<WeatherProvider, SettingsProvider>(
      builder: (context, weatherProv, settingsProv, child) {
        final weatherCode = weatherProv.weatherData?.current.weatherCode ?? 0;
        final type = WeatherUtils.getWeatherType(weatherCode);
        final appBarColor = settingsProv.weatherColors[type] ?? Colors.blue;
        final isDark = ThemeData.estimateBrightnessForColor(appBarColor) == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            foregroundColor: isDark ? Colors.white : Colors.black,
            title: const Text('Thời tiết Việt Nam'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Tìm kiếm địa điểm',
                onPressed: () {
                  _showSearchDialog(context);
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

                  _buildHourlyChart(data.hourly),

                  const SizedBox(height: 30),

                  _buildForecastCard(context, data.daily),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildWeatherDetails(data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _detailItem(Icons.water_drop, '${data.humidity}%', 'Độ ẩm'),
          Container(height: 30, width: 1, color: Colors.white54),
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

  Widget _buildForecastCard(BuildContext context, daily) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Dự báo 7 ngày tới',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daily.time.length,
              separatorBuilder: (context, index) => const Divider(height: 12, color: Colors.black12),
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
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        desc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            maxTemp,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            minTemp,
                            style: const TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
                    color: Colors.white),
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
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: index == 0
                      ? Border.all(color: Colors.white54, width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(timeString,
                        style: TextStyle(
                          color: index == 0 ? Colors.white : Colors.white70,
                          fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 8),
                    const Icon(Icons.cloud, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text('${temp.round()}°',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyChart(HourlyWeather hourlyData) {
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

    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < 24; i++) {
      int realIndex = startIndex + i;
      if (realIndex < hourlyData.time.length) {
        double temp = hourlyData.temperature2m[realIndex];
        spots.add(FlSpot(i.toDouble(), temp));

        if (temp < minY) minY = temp;
        if (temp > maxY) maxY = temp;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Colors.lightBlueAccent),
              SizedBox(width: 8),
              Text(
                'Biểu đồ nhiệt độ 24h tới',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                minY: minY - 2,
                maxY: maxY + 2,
                minX: 0,
                maxX: 23,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();

                        if (index != 0 && index != 23 && index % 6 != 0) {
                          return const SizedBox();
                        }

                        int realIndex = startIndex + index;
                        if (realIndex >= hourlyData.time.length) return const SizedBox();

                        DateTime date = DateTime.parse(hourlyData.time[realIndex]);

                        String timeStr;
                        if (index == 0) {
                          timeStr = "Bây giờ";
                        } else {
                          timeStr = "${date.hour.toString().padLeft(2, '0')}:00";
                        }
                        double paddingLeft = 0.0;
                        double paddingRight = 0.0;

                        if (index == 0) {
                          paddingLeft = 16.0;
                        } else if (index == 23) {
                          paddingRight = 16.0;
                        }

                        return Padding(
                          padding: EdgeInsets.only(
                              top: 8.0,
                              left: paddingLeft,
                              right: paddingRight
                          ),
                          child: Text(
                            timeStr,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.white,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(radius: 3, color: Colors.blue, strokeWidth: 0),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.blueAccent.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
