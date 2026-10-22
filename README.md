# Ứng dụng Dự báo Thời tiết Việt Nam (Flutter & Open-Meteo)

Ứng dụng xem dự báo thời tiết dành riêng cho Việt Nam được xây dựng bằng **Flutter**, tích hợp dữ liệu thời tiết thực tế từ **Open-Meteo API**, hiệu ứng hoạt hình sinh động với **weather_animation**, cùng khả năng tùy chỉnh màu sắc cá nhân hóa cho từng dạng thời tiết.

---

## 🌟 Các Tính năng Chính

1. **Dự báo Thời tiết Chuyên sâu (Thời gian thực & 7 ngày tới)**:
   - Nhiệt độ hiện tại, **nhiệt độ cảm nhận thực tế (Feels like)**.
   - **Chỉ số tia cực tím (UV Index)** với bảng màu cảnh báo mức độ và khuyến cáo bảo vệ da.
   - **Tốc độ gió & Hướng gió** tự động quy đổi la bàn tiếng Việt (Bắc, Đông Bắc, Đông Nam...).
   - **Áp suất khí quyển (hPa)** và độ ẩm không khí.
   - **Chu kỳ Mặt trời mọc & Hoàng hôn** (Bình minh & Hoàng hôn).
   - **Khả năng có mưa (%)** chi tiết cho từng giờ và từng ngày.
   - Bảng dự báo 7 ngày hỗ trợ chuyển đổi linh hoạt giữa **Biểu đồ đường mượt mà (`fl_chart`)** và **Danh sách thẻ chi tiết**.
   - Hỗ trợ thao tác **kéo để làm mới dữ liệu (Pull-to-refresh)**.

2. **Quản lý Địa điểm Yêu thích & Trượt Đổi Thành phố (PageView)**:
   - **Trượt ngang (Swipe)** để chuyển đổi mượt mà giữa các thành phố yêu thích tương tự Apple Weather / Google Weather.
   - **Thanh chỉ báo trang (Dots Indicator)** ở góc dưới màn hình giúp nhận biết trang và chạm để nhảy nhanh tới thành phố mong muốn.
   - **Nút Ngôi sao Yêu thích** ngay trên AppBar để thêm/bỏ lưu địa điểm nhanh chóng.
   - **Màn hình Quản lý Địa điểm (`SavedLocationsScreen`)**:
     - Xem danh sách thẻ thời tiết thời gian thực của tất cả thành phố đã lưu.
     - Tìm kiếm và thêm nhanh thành phố mới bằng thanh tìm kiếm thông minh hoặc ghim trên bản đồ.
     - Thao tác vuốt ngang để xóa địa điểm khỏi danh sách (`Dismissible`) kèm nút Hoàn tác (Undo).
     - Tự động lưu trữ danh sách yêu thích vào bộ nhớ máy (`shared_preferences`).

3. **Bản đồ Tương tác & Định vị GPS**:
   - Tự động định vị GPS vị trí hiện tại của người dùng qua `geolocator`.
   - Màn hình Bản đồ số vệ tinh/OpenStreetMap (`flutter_map`) hỗ trợ ghim tọa độ chính xác, tìm kiếm địa chỉ kèm lịch sử tìm kiếm gần đây.

4. **Hiệu ứng Hoạt hình & Tùy biến Màu sắc Cá nhân hóa**:
   - Sử dụng thư viện `weather_animation` để hiển thị hoạt ảnh nền sống động (Nắng, Mưa, Mây, Dông sét, Tuyết...).
   - Đồng bộ màu sắc thanh `AppBar` và `BottomBar` theo trạng thái thời tiết.
   - Cho phép người dùng tùy chọn bảng màu tùy thích cho từng kiểu thời tiết qua `flutter_colorpicker`.

---

## 📁 Cấu trúc Thư mục Dự án

```text
lib/
│
├── models/             # Các mô hình dữ liệu (City, WeatherData, HourlyWeather, DailyForecast...)
├── providers/          # Quản lý trạng thái (WeatherProvider, SettingsProvider)
├── screens/            # Các màn hình chính (HomeScreen, MapPickerScreen, SavedLocationsScreen, SettingsScreen)
├── services/           # Kết nối Open-Meteo API (WeatherApiService)
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
