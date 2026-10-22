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

// ─── Màu sắc nhất quán với giao diện tối ─────────────────────────────────────
const Color _kBg = Color(0xFF0F1923);
const Color _kSurface = Color(0xFF1A2535);
const Color _kAccent = Color(0xFF3B82F6);
const Color _kBorder = Color(0x33FFFFFF);
const Color _kText = Colors.white;
const Color _kTextSub = Color(0xFFB0BEC5);

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
  // ← FIX: dùng đúng package name từ build.gradle.kts
  static const String _kUserAgent = 'com.example.weather';
  // ← FIX: User-Agent rõ ràng hơn để Nominatim không reject
  static const String _nominatimAgent =
      'WeatherForecastVN/1.0 (flutter; contact: dev@example.com)';

  late final MapController _mapController;
  late LatLng _currentLocation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  bool _isSearching = false;
  String? _selectedPlaceName;
  bool _isReverseGeocoding = false;

  List<LocationResult> _suggestions = [];
  List<LocationResult> _recentSearches = [];
  bool _showOverlay = false;

  bool _showRadar = false;
  String? _radarTilePath;
  bool _isLoadingRadar = false;

  Future<void> _fetchRadarLayer() async {
    setState(() => _isLoadingRadar = true);
    try {
      final res = await http.get(
        Uri.parse('https://api.rainviewer.com/public/weather-maps.json'),
        headers: {'User-Agent': _nominatimAgent},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final past = data['radar']?['past'] as List?;
        if (past != null && past.isNotEmpty) {
          _radarTilePath = past.last['path'] as String?;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingRadar = false);
  }

  void _toggleRadar() async {
    if (!_showRadar && _radarTilePath == null) {
      await _fetchRadarLayer();
    }
    setState(() => _showRadar = !_showRadar);
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.initialCenter;
    _loadRecentSearches();

    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() => _showOverlay = _searchFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Lịch sử tìm kiếm ──────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_recentSearchesKey) ?? [];
    if (mounted) {
      setState(() {
        _recentSearches = rawList
            .map((item) => LocationResult.fromJson(json.decode(item)))
            .toList();
      });
    }
  }

  Future<void> _saveToRecent(LocationResult location) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.removeWhere((item) =>
        item.displayName == location.displayName ||
        (item.latitude == location.latitude &&
            item.longitude == location.longitude));
    _recentSearches.insert(0, location);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    final rawList =
        _recentSearches.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_recentSearchesKey, rawList);
    if (mounted) setState(() {});
  }

  Future<void> _removeFromRecent(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _recentSearches.removeAt(index));
    final rawList =
        _recentSearches.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_recentSearchesKey, rawList);
  }

  Future<void> _clearAllRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (mounted) setState(() => _recentSearches.clear());
  }

  // ── Tìm kiếm Nominatim ────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      if (mounted) setState(() { _suggestions.clear(); _isSearching = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (mounted) setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&countrycodes=vn',
      );
      // ← FIX: User-Agent rõ ràng để Nominatim chấp nhận
      final response = await http.get(url, headers: {
        'User-Agent': _nominatimAgent,
        'Accept': 'application/json',
        'Accept-Language': 'vi,en',
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _suggestions = data.map((item) => LocationResult(
              latitude: double.parse(item['lat'] as String),
              longitude: double.parse(item['lon'] as String),
              displayName: item['display_name'] as String,
            )).toList();
          });
        }
      }
    } catch (_) {
      // bỏ qua lỗi mạng khi đang gõ
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ← FIX: Reverse geocoding khi người dùng kéo/chạm bản đồ
  Future<void> _reverseGeocode(LatLng point) async {
    if (mounted) setState(() => _isReverseGeocoding = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}'
        '&format=json&accept-language=vi',
      );
      final response = await http.get(url, headers: {
        'User-Agent': _nominatimAgent,
        'Accept': 'application/json',
      });

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        String name = '';
        if (address != null) {
          name = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              address['state'] ??
              '') as String;
        }
        if (name.isEmpty) {
          name = data['display_name'] as String? ?? '';
          if (name.contains(',')) name = name.split(',')[0].trim();
        }
        if (mounted && name.isNotEmpty) {
          setState(() => _selectedPlaceName = name);
        }
      }
    } catch (_) {
      // fallback: giữ null → hiện tọa độ
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  void _selectLocation(LocationResult location) {
    _searchFocusNode.unfocus();
    final shortName = location.displayName.split(',')[0].trim();
    setState(() {
      _showOverlay = false;
      _currentLocation = LatLng(location.latitude, location.longitude);
      _selectedPlaceName = shortName;
      _searchController.text = shortName;
      _suggestions.clear();
    });
    _saveToRecent(location);
    _mapController.move(_currentLocation, 14.0);
  }

  String _buildLocationLabel() {
    if (_isReverseGeocoding) return 'Đang xác định vị trí...';
    if (_selectedPlaceName != null) return 'Đã chọn: $_selectedPlaceName';
    return 'Kéo hoặc chạm bản đồ để đặt ghim';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kText,
        elevation: 0,
        title: const Text(
          'Chọn vị trí dự báo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ── 1. Bản đồ ──────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 9.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  _currentLocation = camera.center;
                  // Xóa tên cũ khi kéo bản đồ
                  if (_selectedPlaceName != null) {
                    setState(() => _selectedPlaceName = null);
                  }
                }
              },
              onTap: (tapPosition, point) {
                _searchFocusNode.unfocus();
                setState(() {
                  _showOverlay = false;
                  _currentLocation = point;
                  _selectedPlaceName = null;
                });
                _mapController.move(point, _mapController.camera.zoom);
                // Reverse geocode để lấy tên địa điểm
                _reverseGeocode(point);
              },
              onMapEvent: (event) {
                // Sau khi kéo xong thì reverse geocode
                if (event is MapEventMoveEnd) {
                  _reverseGeocode(_currentLocation);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // ← FIX: đúng package name
                userAgentPackageName: _kUserAgent,
              ),
              if (_showRadar && _radarTilePath != null)
                Opacity(
                  opacity: 0.65,
                  child: TileLayer(
                    urlTemplate:
                        'https://tilecache.rainviewer.com$_radarTilePath/256/{z}/{x}/{y}/2/1_1.png',
                    userAgentPackageName: _kUserAgent,
                  ),
                ),
            ],
          ),

          // ── 2. Ghim giữa màn hình ──────────────────────────────────────
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0),
              child: Icon(Icons.location_on, size: 44, color: Color(0xFFEF4444)),
            ),
          ),

          // ── 3. Nút Radar (góc trên phải) ──────────────────────────────
          Positioned(
            top: 12,
            right: 16,
            child: _RadarToggleButton(
              isActive: _showRadar,
              isLoading: _isLoadingRadar,
              onTap: _toggleRadar,
            ),
          ),

          // ── 4. Chú giải cường độ mưa ──────────────────────────────────
          if (_showRadar)
            Positioned(
              left: 16,
              bottom: 148,
              child: _RadarLegend(),
            ),

          // ── 5. Bottom action bar ───────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildBottomPanel(),
          ),

          // ── 6. Thanh tìm kiếm + overlay gợi ý ────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 72, // nhường chỗ cho nút radar
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBar(),
                if (_showOverlay) _buildSuggestionsOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: _kText, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tìm địa điểm (Vũng Tàu, Ba Vì...)',
          hintStyle: const TextStyle(color: _kTextSub, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _kAccent, size: 20),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kAccent),
                  ),
                )
              : (_searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: _kTextSub),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }

  // ── Overlay gợi ý / lịch sử ──────────────────────────────────────────────

  Widget _buildSuggestionsOverlay() {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final displayList = hasQuery ? _suggestions : _recentSearches;

    if (!hasQuery && _recentSearches.isEmpty) return const SizedBox.shrink();
    if (hasQuery && _suggestions.isEmpty && !_isSearching) {
      return _overlayContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.search_off, color: _kTextSub, size: 18),
              SizedBox(width: 8),
              Text('Không tìm thấy địa điểm phù hợp',
                  style: TextStyle(color: _kTextSub, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return _overlayContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasQuery ? 'Kết quả tìm kiếm' : 'Tìm kiếm gần đây',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _kTextSub,
                    letterSpacing: 0.8,
                  ),
                ),
                if (!hasQuery && _recentSearches.isNotEmpty)
                  GestureDetector(
                    onTap: _clearAllRecent,
                    child: const Text('Xóa tất cả',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFFEF4444))),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: _kBorder),
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: displayList.length,
              separatorBuilder: (_, i) =>
                  Divider(height: 1, color: _kBorder, indent: 48),
              itemBuilder: (context, index) {
                final item = displayList[index];
                final title = item.displayName.split(',')[0].trim();
                final subtitle = item.displayName;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    hasQuery ? Icons.location_on_outlined : Icons.history,
                    color: _kAccent,
                    size: 20,
                  ),
                  title: Text(title,
                      style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  subtitle: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _kTextSub),
                  ),
                  trailing: !hasQuery
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 15, color: _kTextSub),
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
    );
  }

  Widget _overlayContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Material(color: Colors.transparent, child: child),
    );
  }

  // ── Bottom panel ─────────────────────────────────────────────────────────

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface.withOpacity(0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location label
          Row(
            children: [
              Icon(
                _isReverseGeocoding
                    ? Icons.hourglass_empty
                    : Icons.pin_drop_outlined,
                color: _isReverseGeocoding ? _kTextSub : _kAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _buildLocationLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _kTextSub, fontSize: 13),
                ),
              ),
              if (_isReverseGeocoding)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kAccent),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'Xem thời tiết tại đây',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                final lat = _currentLocation.latitude;
                final lon = _currentLocation.longitude;
                final name = _selectedPlaceName ??
                    '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
                Navigator.pop(
                  context,
                  LocationResult(
                    latitude: lat,
                    longitude: lon,
                    displayName: name,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Extracted widgets ─────────────────────────────────────────────────────────

class _RadarToggleButton extends StatelessWidget {
  const _RadarToggleButton({
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? _kAccent : _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(
                isActive ? Icons.radar : Icons.layers_outlined,
                size: 16,
                color: Colors.white,
              ),
            const SizedBox(width: 6),
            Text(
              isActive ? 'Radar: BẬT' : 'Radar',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kSurface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CƯỜNG ĐỘ MƯA',
            style: TextStyle(
                color: _kTextSub,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendDot(const Color(0xFF22C55E), 'Nhẹ'),
              const SizedBox(width: 8),
              _legendDot(const Color(0xFFEAB308), 'Vừa'),
              const SizedBox(width: 8),
              _legendDot(const Color(0xFFF97316), 'Lớn'),
              const SizedBox(width: 8),
              _legendDot(const Color(0xFFEF4444), 'Rất lớn'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
      ],
    );
  }
}