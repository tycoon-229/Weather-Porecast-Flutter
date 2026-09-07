# Ứng dụng Dự báo Thời tiết Việt Nam (Flutter & Open-Meteo)

Ứng dụng xem dự báo thời tiết dành riêng cho Việt Nam được xây dựng bằng **Flutter**, tích hợp dữ liệu thời tiết thực tế từ **Open-Meteo API**, hiệu ứng hoạt hình sinh động với **weather_animation**, cùng khả năng tùy chỉnh màu sắc cá nhân hóa cho từng dạng thời tiết.

---

## 🌟 Các Tính năng Chính

1. **Dự báo Thời tiết Thời gian thực & 7 ngày tới**:
   - Cung cấp nhiệt độ hiện tại, trạng thái thời tiết, độ ẩm và tốc độ gió.
   - Bảng dự báo chi tiết 7 ngày tới với giao diện thẻ nổi (Card) và các cột được căn chỉnh trực quan.
2. **Hiệu ứng Hoạt hình Thời tiết (Weather Animation)**:
   - Sử dụng thư viện `weather_animation` để hiển thị các hiệu ứng sinh động (Trời nắng, Nhiều mây, Mưa, Tuyết, Dông sét...) trực tiếp trên màn hình.
   - Nội dung chi tiết thời tiết được phủ trực tiếp lên khung animation với hiệu ứng gradient mờ hiện đại.
3. **Định vị GPS & Tìm kiếm Địa điểm**:
   - Tự động lấy vị trí hiện tại của người dùng tại Việt Nam thông qua `geolocator`.
   - Hỗ trợ hộp thoại tìm kiếm địa điểm/thành phố bất kỳ trên toàn quốc (sử dụng `geocoding` để tra cứu tọa độ).
   - Danh sách các thành phố lớn tại Việt Nam có sẵn trong menu thả xuống (Dropdown).
4. **Đồng bộ Màu sắc Thanh AppBar**:
   - Màu nền của `AppBar` tự động đồng bộ theo màu chủ đạo của dạng thời tiết hiện tại.
   - Tự động tính toán độ sáng tối (Contrast) để hiển thị màu chữ và icon phù hợp (Trắng/Đen).
5. **Tùy chỉnh Màu sắc Cá nhân hóa (Settings & Color Picker)**:
   - Cho phép người dùng tùy chỉnh màu sắc chủ đạo cho từng loại thời tiết (Nắng, Mây, Mưa, Dông...).
   - Tích hợp bảng chọn màu chuyên nghiệp (`flutter_colorpicker`).
   - Lưu trữ tự động với `shared_preferences` (giữ nguyên tùy chỉnh sau khi khởi động lại ứng dụng).

---

## 🛠 Công nghệ & Thư viện Sử dụng

- **Framework**: Flutter (Dart)
- **Quản lý trạng thái (State Management)**: `provider` (^6.1.2)
- **API Thời tiết**: [Open-Meteo API](https://open-meteo.com/) (Miễn phí, không cần API Key)
- **Hiệu ứng thời tiết**: `weather_animation` (^1.2.0)
- **Định vị & Địa lý**: `geolocator` (^13.0.0), `geocoding` (^3.0.0)
- **Lưu trữ cục bộ**: `shared_preferences` (^2.2.2)
- **Chọn màu sắc**: `flutter_colorpicker` (^1.1.0)
- **Định dạng ngày tháng**: `intl` (^0.19.0) (Hỗ trợ tiếng Việt)

---

## 📁 Cấu trúc Thư mục Dự án

```text
lib/
│
├── models/             # Các mô hình dữ liệu (City, WeatherData, HourlyWeather...)
├── providers/          # Quản lý trạng thái (WeatherProvider, SettingsProvider)
├── screens/            # Các màn hình chính (HomeScreen, SettingsScreen)
├── services/           # Kết nối API (WeatherApiService)
├── utils/              # Tiện ích hỗ trợ & Mapping (WeatherUtils)
├── widgets/            # Các thành phần giao diện tái sử dụng (WeatherAnimationWrapper)
└── main.dart           # Điểm khởi đầu ứng dụng và cấu hình Provider
```

---

## 🚀 Hướng dẫn Cài đặt & Chạy Ứng dụng

1. **Yêu cầu hệ thống**:
   - Đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản 3.x trở lên).
   - Đã cài đặt Android Studio / VS Code và thiết lập Máy ảo (Emulator) hoặc thiết bị thật.

2. **Clone/Mở dự án**:
   - Mở thư mục dự án trong terminal hoặc IDE của bạn.

3. **Cài đặt các gói phụ thuộc**:
   ```bash
   flutter pub get
   ```

4. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```
