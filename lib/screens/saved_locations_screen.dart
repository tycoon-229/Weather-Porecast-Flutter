import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../models/city_model.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/weather_utils.dart';
import 'map_picker_screen.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAndAddCity(BuildContext context) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        throw Exception('Không tìm thấy địa điểm');
      }

      final loc = locations.first;
      final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      final name = placemarks.isNotEmpty ? (placemarks[0].locality ?? query) : query;
      final country = placemarks.isNotEmpty ? (placemarks[0].country ?? 'VN') : 'VN';

      final newCity = City(
        name: name,
        latitude: loc.latitude,
        longitude: loc.longitude,
        country: country,
      );

      if (context.mounted) {
        final prov = context.read<WeatherProvider>();
        await prov.addFavorite(newCity);
        _searchController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm "$name" vào danh sách yêu thích'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _searchError = 'Không tìm thấy địa điểm "$query". Vui lòng thử lại!';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProv = context.watch<WeatherProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final favoriteCities = weatherProv.favoriteCities;
    final gpsCity = weatherProv.currentGpsCity;

    return Scaffold(
      backgroundColor: const Color(0xFF1E2430),
      appBar: AppBar(
        title: const Text('Quản lý địa điểm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2430),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Chọn từ bản đồ',
            onPressed: () async {
              final LocationResult? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapPickerScreen(),
                ),
              );

              if (result != null && context.mounted) {
                final newCity = City(
                  name: result.displayName,
                  latitude: result.latitude,
                  longitude: result.longitude,
                  country: 'VN',
                );
                await context.read<WeatherProvider>().addFavorite(newCity);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm "${result.displayName}" vào danh sách!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchAndAddCity(context),
                decoration: InputDecoration(
                  hintText: 'Nhập tên thành phố (Hải Phòng, Cần Thơ...)',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.lightBlueAccent),
                          tooltip: 'Thêm địa điểm',
                          onPressed: () => _searchAndAddCity(context),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                _searchError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),

          // City List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Thẻ GPS nếu có
                if (gpsCity != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'VỊ TRÍ HIỆN TẠI',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildCityCard(
                    context: context,
                    city: gpsCity,
                    isGps: true,
                    weatherData: weatherProv.getWeatherForCity(gpsCity),
                    settingsProv: settingsProv,
                    onTap: () {
                      weatherProv.selectCity(gpsCity);
                      Navigator.pop(context);
                    },
                    onDelete: null,
                  ),
                  const SizedBox(height: 16),
                ],

                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ĐỊA ĐIỂM YÊU THÍCH (${favoriteCities.length})',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Vuốt để xóa',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                      ),
                    ],
                  ),
                ),

                if (favoriteCities.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.location_city, size: 56, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có địa điểm yêu thích nào',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
                        ),
                      ],
                    ),
                  )
                else
                  ...favoriteCities.map((city) {
                    final weather = weatherProv.getWeatherForCity(city);
                    return Dismissible(
                      key: Key('fav_${city.name}_${city.latitude}_${city.longitude}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Xóa',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) {
                        weatherProv.removeFavorite(city);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã xóa "${city.name}"'),
                            action: SnackBarAction(
                              label: 'Hoàn tác',
                              onPressed: () => weatherProv.addFavorite(city),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCityCard(
                          context: context,
                          city: city,
                          isGps: false,
                          weatherData: weather,
                          settingsProv: settingsProv,
                          onTap: () {
                            weatherProv.selectCity(city);
                            Navigator.pop(context);
                          },
                          onDelete: () => weatherProv.removeFavorite(city),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard({
    required BuildContext context,
    required City city,
    required bool isGps,
    required WeatherData? weatherData,
    required SettingsProvider settingsProv,
    required VoidCallback onTap,
    required VoidCallback? onDelete,
  }) {
    final weatherCode = weatherData?.current.weatherCode ?? 0;
    final type = WeatherUtils.getWeatherType(weatherCode);
    final cardColor = settingsProv.weatherColors[type] ?? Colors.blue;

    final temp = weatherData != null ? '${weatherData.current.temperature.round()}°' : '--°';
    final desc = weatherData != null
        ? WeatherUtils.getWeatherDescription(weatherData.current.weatherCode)
        : 'Đang tải...';

    final maxTemp = (weatherData != null && weatherData.daily.temperatureMax.isNotEmpty)
        ? '${weatherData.daily.temperatureMax[0].round()}°'
        : '--°';
    final minTemp = (weatherData != null && weatherData.daily.temperatureMin.isNotEmpty)
        ? '${weatherData.daily.temperatureMin[0].round()}°'
        : '--°';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardColor.withOpacity(0.85),
              cardColor.withOpacity(0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cột bên trái: Tên địa điểm, Mô tả
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isGps) ...[
                        const Icon(Icons.near_me, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          city.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isGps ? 'Vị trí hiện tại' : (city.country.isNotEmpty ? city.country : 'Việt Nam'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Cột bên phải: Nhiệt độ, Max/Min, Icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  temp,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'C: $maxTemp  T: $minTemp',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
