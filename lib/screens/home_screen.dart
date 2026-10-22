import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/hourly_weather_model.dart';
import '../models/weather_model.dart';
import '../models/city_model.dart';
import '../providers/weather_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_animation_wrapper.dart';
import 'map_picker_screen.dart';
import 'saved_locations_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showChartTab = true;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<WeatherProvider>().selectedCityIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WeatherProvider, SettingsProvider>(
      builder: (context, weatherProv, settingsProv, child) {
        final currentCity = weatherProv.selectedCity;
        final weatherData = weatherProv.weatherData;
        final weatherCode = weatherData?.current.weatherCode ?? 0;
        final type = WeatherUtils.getWeatherType(weatherCode);
        final appBarColor = settingsProv.weatherColors[type] ?? Colors.blue;
        final isDark = ThemeData.estimateBrightnessForColor(appBarColor) == Brightness.dark;
        final isFav = weatherProv.isFavorite(currentCity);

        // Đồng bộ PageController khi index thay đổi từ bên ngoài (ví dụ từ màn hình quản lý địa điểm)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients &&
              _pageController.page?.round() != weatherProv.selectedCityIndex) {
            _pageController.animateToPage(
              weatherProv.selectedCityIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });

        return Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            foregroundColor: isDark ? Colors.white : Colors.black,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentCity.isCurrentLocation) ...[
                  const Icon(Icons.near_me, size: 18),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    currentCity.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                ),
              ],
            ),
            actions: [
              // Nút bật/tắt yêu thích
              IconButton(
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? Colors.amberAccent : (isDark ? Colors.white : Colors.black),
                ),
                tooltip: isFav ? 'Bỏ lưu yêu thích' : 'Lưu vào yêu thích',
                onPressed: () async {
                  await weatherProv.toggleFavorite(currentCity);
                  if (context.mounted) {
                    final updatedFav = weatherProv.isFavorite(currentCity);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(updatedFav
                            ? 'Đã thêm "${currentCity.name}" vào danh sách yêu thích'
                            : 'Đã xóa "${currentCity.name}" khỏi danh sách yêu thích'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
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
          bottomNavigationBar: _buildBottomBar(context, weatherProv, appBarColor, isDark),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WeatherProvider weatherProv, SettingsProvider settingsProv) {
    if (weatherProv.isLoading && weatherProv.weatherData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (weatherProv.error != null && weatherProv.weatherData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lỗi: ${weatherProv.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => weatherProv.fetchWeatherForSelectedCity(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final cities = weatherProv.allCities;

    return PageView.builder(
      controller: _pageController,
      itemCount: cities.length,
      onPageChanged: (index) {
        weatherProv.selectCityIndex(index);
      },
      itemBuilder: (context, index) {
        final city = cities[index];
        final isSelected = index == weatherProv.selectedCityIndex;
        final data = isSelected ? weatherProv.weatherData : weatherProv.getWeatherForCity(city);

        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'Đang tải thời tiết cho ${city.name}...',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return _buildCityWeatherView(context, city, data, weatherProv, settingsProv);
      },
    );
  }

  Widget _buildCityWeatherView(
    BuildContext context,
    City city,
    WeatherData data,
    WeatherProvider weatherProv,
    SettingsProvider settingsProv,
  ) {
    final type = WeatherUtils.getWeatherType(data.current.weatherCode);
    final themeColor = settingsProv.weatherColors[type] ?? Colors.blue;

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
            child: RefreshIndicator(
              onRefresh: () => weatherProv.refreshWeather(),
              color: themeColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 6),
                    Text(
                      'Cảm giác như ${data.current.apparentTemperature.round()}°C',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1))],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildWeatherDetails(data.current),
                    const SizedBox(height: 16),
                    _buildSunAndPrecipitationCard(data.daily),
                    const SizedBox(height: 24),
                    _buildHourlyForecast(data.hourly),
                    const SizedBox(height: 24),

                    // Biểu đồ dự báo nhiều ngày tương tự mẫu ảnh
                    _buildMultiDayForecastCard(context, data.daily),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WeatherProvider weatherProv,
    Color barColor,
    bool isDark,
  ) {
    final cities = weatherProv.allCities;
    final fgColor = isDark ? Colors.white : Colors.black;

    return Container(
      color: barColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.map_outlined),
              color: fgColor,
              tooltip: 'Bản đồ chọn vị trí',
              onPressed: () async {
                final LocationResult? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapPickerScreen(),
                  ),
                );

                if (result != null && context.mounted) {
                  context.read<WeatherProvider>().fetchWeatherForCoordinates(
                    result.latitude,
                    result.longitude,
                    result.displayName,
                  );
                }
              },
            ),

            // Dấu chấm chỉ báo trang (Dots Page Indicator)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(cities.length, (dotIndex) {
                final isCurrentDot = dotIndex == weatherProv.selectedCityIndex;
                final isGps = cities[dotIndex].isCurrentLocation;

                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      dotIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrentDot ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCurrentDot ? fgColor : fgColor.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isGps && isCurrentDot
                        ? Center(
                            child: Icon(
                              Icons.near_me,
                              size: 7,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),

            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              color: fgColor,
              tooltip: 'Quản lý địa điểm',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedLocationsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
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
        final icon = WeatherUtils.getWeatherIcon(daily.weatherCode[index]);
        final maxTemp = '${daily.temperatureMax[index].round()}°';
        final minTemp = '${daily.temperatureMin[index].round()}°';
        final int rainProb = (daily.precipitationProbabilityMax.length > index)
            ? daily.precipitationProbabilityMax[index]
            : 0;

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                    ),
                  ),
                  if (rainProb > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '💧$rainProb%',
                      style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
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
    final Map<String, City> cityMap = {};
    for (final c in provider.allCities) {
      cityMap[c.name] = c;
    }
    for (final c in WeatherUtils.vietnamCities) {
      cityMap.putIfAbsent(c.name, () => c);
    }
    final cityNames = cityMap.keys.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: cityMap.containsKey(provider.selectedCity.name)
                ? provider.selectedCity.name
                : cityNames.first,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.blue),
            onChanged: (value) {
              if (value != null && cityMap.containsKey(value)) {
                provider.selectCity(cityMap[value]!);
              }
            },
            items: cityNames.map((name) {
              final isGps = cityMap[name]?.isCurrentLocation ?? false;
              return DropdownMenuItem(
                value: name,
                child: Row(
                  children: [
                    if (isGps) ...[
                      const Icon(Icons.near_me, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(CurrentWeather data) {
    final uvInfo = WeatherUtils.getUvInfo(data.uvIndex);
    final windDir = WeatherUtils.getWindDirection(data.windDirection);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  icon: Icons.water_drop,
                  iconColor: Colors.lightBlueAccent,
                  title: 'Độ ẩm',
                  value: '${data.humidity}%',
                  subtitle: data.humidity > 70 ? 'Khá ẩm ướt' : 'Dễ chịu',
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white24),
              Expanded(
                child: _detailTile(
                  icon: Icons.air,
                  iconColor: Colors.tealAccent,
                  title: 'Gió & Hướng',
                  value: '${data.windSpeed} km/h',
                  subtitle: windDir,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  icon: Icons.wb_sunny_outlined,
                  iconColor: uvInfo.color,
                  title: 'Chỉ số UV',
                  value: data.uvIndex.toStringAsFixed(1),
                  subtitle: uvInfo.label,
                  badgeColor: uvInfo.color,
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white24),
              Expanded(
                child: _detailTile(
                  icon: Icons.compress,
                  iconColor: Colors.orangeAccent,
                  title: 'Áp suất',
                  value: '${data.surfacePressure.round()} hPa',
                  subtitle: 'Khí quyển',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                badgeColor != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: badgeColor.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    : Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunAndPrecipitationCard(DailyForecast daily) {
    final sunrise = daily.sunrise.isNotEmpty ? WeatherUtils.formatTime(daily.sunrise[0]) : '--:--';
    final sunset = daily.sunset.isNotEmpty ? WeatherUtils.formatTime(daily.sunset[0]) : '--:--';
    final rainProb = daily.precipitationProbabilityMax.isNotEmpty ? daily.precipitationProbabilityMax[0] : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight, color: Colors.amberAccent, size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bình minh', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(sunrise, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 28, color: Colors.white24),
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: Colors.orangeAccent, size: 22),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hoàng hôn', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(sunset, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 28, color: Colors.white24),
          Row(
            children: [
              const Icon(Icons.umbrella, color: Colors.lightBlueAccent, size: 22),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mưa hôm nay', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('$rainProb%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
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
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final int realIndex = startIndex + index;
              final DateTime date = DateTime.parse(hourlyData.time[realIndex]);
              final String timeString = index == 0 ? "Bây giờ" : "${date.hour.toString().padLeft(2, '0')}:00";
              final double temp = hourlyData.temperature2m[realIndex];
              final int weatherCode = hourlyData.weatherCode[realIndex];
              final int rainProb = (hourlyData.precipitationProbability.length > realIndex)
                  ? hourlyData.precipitationProbability[realIndex]
                  : 0;

              return Container(
                width: 82,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      WeatherUtils.getWeatherIcon(weatherCode),
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${temp.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (rainProb > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '💧$rainProb%',
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
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