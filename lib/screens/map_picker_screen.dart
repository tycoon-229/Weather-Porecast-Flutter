import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String displayName;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'displayName': displayName,
  };

  factory LocationResult.fromJson(Map<String, dynamic> json) => LocationResult(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    displayName: json['displayName'] as String,
  );
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialCenter;

  const MapPickerScreen({
    super.key,
    this.initialCenter = const LatLng(12.2388, 109.1967), // Nha Trang mặc định
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const String _recentSearchesKey = 'recent_searches_locations';

  late final MapController _mapController;
  late LatLng _currentLocation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  bool _isSearching = false;
  String? _selectedPlaceName;

  List<LocationResult> _suggestions = [];
  List<LocationResult> _recentSearches = [];
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.initialCenter;
    _loadRecentSearches();

    _searchFocusNode.addListener(() {
      setState(() {
        _showOverlay = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Tải danh sách 5 địa điểm gần nhất từ SharedPreferences
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_recentSearchesKey) ?? [];
    setState(() {
      _recentSearches = rawList
          .map((item) => LocationResult.fromJson(json.decode(item)))
          .toList();
    });
  }

  // Lưu một địa điểm vào lịch sử (giới hạn tối đa 5 mục)
  Future<void> _saveToRecent(LocationResult location) async {
    final prefs = await SharedPreferences.getInstance();

    // Loại bỏ mục trùng lặp trước đó
    _recentSearches.removeWhere((item) =>
    item.displayName == location.displayName ||
        (item.latitude == location.latitude && item.longitude == location.longitude));

    // Thêm mục mới lên đầu
    _recentSearches.insert(0, location);

    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }

    final rawList = _recentSearches.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_recentSearchesKey, rawList);
    setState(() {});
  }

  // Xóa 1 mục khỏi lịch sử
  Future<void> _removeFromRecent(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.removeAt(index);
    });
    final rawList = _recentSearches.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_recentSearchesKey, rawList);
  }

  // Xóa toàn bộ lịch sử
  Future<void> _clearAllRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    setState(() {
      _recentSearches.clear();
    });
  }

  // Tìm kiếm gợi ý (Debounce 500ms)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _suggestions.clear();
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=vn',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterWeatherApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _suggestions = data.map((item) {
            return LocationResult(
              latitude: double.parse(item['lat']),
              longitude: double.parse(item['lon']),
              displayName: item['display_name'] as String,
            );
          }).toList();
        });
      }
    } catch (_) {
      // Bỏ qua lỗi mạng khi đang gõ
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // Chọn địa điểm từ danh sách gợi ý hoặc lịch sử
  void _selectLocation(LocationResult location) {
    _searchFocusNode.unfocus();
    setState(() {
      _showOverlay = false;
      _currentLocation = LatLng(location.latitude, location.longitude);
      _selectedPlaceName = location.displayName.split(',')[0];
      _searchController.text = _selectedPlaceName!;
      _suggestions.clear();
    });

    _saveToRecent(location);
    _mapController.move(_currentLocation, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí dự báo'),
        backgroundColor: const Color(0xff1f293d),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Bản đồ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 9.0,
              onPositionChanged: (camera, hasGesture) {
                _currentLocation = camera.center;
              },
              onTap: (tapPosition, point) {
                _searchFocusNode.unfocus();
                setState(() {
                  _showOverlay = false;
                  _currentLocation = point;
                  _selectedPlaceName = null;
                  _mapController.move(point, _mapController.camera.zoom);
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.weather_app',
              ),
            ],
          ),

          // 2. Ghim đỏ cố định giữa màn hình
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36.0),
              child: Icon(
                Icons.location_on,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
          ),

          // 3. Khung bottom xác nhận vị trí
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff1f293d).withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPlaceName != null
                        ? 'Đã chọn: $_selectedPlaceName'
                        : 'Kéo hoặc chạm bản đồ để đặt điểm cần xem',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'Xem thời tiết tại đây',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final name = _selectedPlaceName ??
                            'Vị trí (${_currentLocation.latitude.toStringAsFixed(2)}, ${_currentLocation.longitude.toStringAsFixed(2)})';

                        Navigator.pop(
                          context,
                          LocationResult(
                            latitude: _currentLocation.latitude,
                            longitude: _currentLocation.longitude,
                            displayName: name,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Thanh tìm kiếm và Dropdown gợi ý/lịch sử
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Tìm địa điểm (ví dụ: Vũng Tàu, Ba Vì...)',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.black45),
                      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                      suffixIcon: _isSearching
                          ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : (_searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                          : null),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                // Danh sách gợi ý hoặc lịch sử tìm kiếm
                if (_showOverlay) _buildSuggestionsOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final displayList = hasQuery ? _suggestions : _recentSearches;

    if (!hasQuery && _recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    if (hasQuery && _suggestions.isEmpty && !_isSearching) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: const Text(
          'Không tìm thấy địa điểm phù hợp',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header tiêu đề (Gợi ý hoặc Tìm kiếm gần đây)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasQuery ? 'Gợi ý kết quả' : 'Tìm kiếm gần đây (Tối đa 5)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  if (!hasQuery && _recentSearches.isNotEmpty)
                    GestureDetector(
                      onTap: _clearAllRecent,
                      child: const Text(
                        'Xóa tất cả',
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: displayList.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
                itemBuilder: (context, index) {
                  final item = displayList[index];
                  final title = item.displayName.split(',')[0].trim();
                  final subtitle = item.displayName;

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      hasQuery ? Icons.location_on_outlined : Icons.history,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    trailing: !hasQuery
                        ? IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                      onPressed: () => _removeFromRecent(index),
                    )
                        : null,
                    onTap: () => _selectLocation(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}