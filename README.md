# Sportico Mobile

Ứng dụng di động Flutter cho **Sportico Platform** — kết nối huấn luyện viên
và người tập qua các gói tập có lịch cố định.

Backend: [sportico-platform](https://github.com/hoaikhoitran/sportico-platform)
(ASP.NET Core 8, Clean Architecture, PostgreSQL).

## Chạy ứng dụng

Toàn bộ cấu hình môi trường đi qua `--dart-define` (không có secret/`.env`
nào được commit). App đọc hai giá trị:

- `API_BASE_URL` — base URL của backend. **Mặc định:** `http://10.0.2.2:5095`
  (backend local nhìn từ Android emulator). Nếu không truyền, app in cảnh báo
  rõ ràng lên console debug.
- `APP_ENV` — `local` (mặc định) hoặc `production`.

Nguồn duy nhất: [lib/app/config/environment.dart](lib/app/config/environment.dart)
→ [lib/app/config/app_config.dart](lib/app/config/app_config.dart) → Dio client.
Không file API/repository nào hardcode URL.

```sh
flutter pub get
```

**Android emulator + backend local** (`10.0.2.2` trỏ về máy host):

```bash
flutter run --dart-define=APP_ENV=local --dart-define=API_BASE_URL=http://10.0.2.2:5095
```

**iOS simulator + backend local:**

```bash
flutter run --dart-define=APP_ENV=local --dart-define=API_BASE_URL=http://127.0.0.1:5095
```

**Điện thoại thật + backend local** (thay bằng IPv4 LAN của máy tính —
xem `ipconfig` / `ifconfig`; điện thoại và máy tính phải cùng Wi-Fi):

```bash
flutter run --dart-define=APP_ENV=local --dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:5095
```

**Production:**

```bash
flutter run --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://sportico-api-khoi.azurewebsites.net
```

Dùng VS Code: chọn sẵn profile trong `.vscode/launch.json` —
`Sportico Local Android Emulator`, `Sportico Local iOS Simulator`,
`Sportico Production`.

### Khắc phục sự cố kết nối

- **Android emulator không gọi được backend** → dùng `10.0.2.2`, **không**
  dùng `localhost` (localhost trong emulator là chính emulator).
- **Điện thoại thật không gọi được backend** → dùng địa chỉ IPv4 LAN của máy
  tính (`ipconfig`), đảm bảo điện thoại và máy tính cùng một mạng Wi-Fi và
  firewall không chặn cổng 5095.
- **Backend ASP.NET Core local** phải lắng nghe trên host/port mà thiết bị
  với tới được — với điện thoại thật, chạy backend bind mọi interface, ví dụ:
  `dotnet run --urls http://0.0.0.0:5095`.
- **Android chặn HTTP (cleartext)** → bản debug đã bật
  `android:usesCleartextTraffic="true"` trong
  `android/app/src/debug/AndroidManifest.xml` (chỉ áp dụng debug; release vẫn
  chặn HTTP). iOS đã bật `NSAllowsLocalNetworking` cho backend local.
- **DNS production lỗi** (`sportico-api-khoi.azurewebsites.net` không phân
  giải) → chuyển sang backend local bằng `--dart-define` như trên.

## Kiểm tra chất lượng

```sh
dart format .
flutter analyze
flutter test
```

## Kiến trúc

Feature-first + tầng core dùng chung:

```
lib/
  app/            # theme (màu thương hiệu, spacing, typography), router, config
  core/
    network/      # Dio + bearer & token-refresh interceptor, Result<T>/PagedResult<T>
    storage/      # flutter_secure_storage cho access/refresh token
    utils/        # định dạng VNĐ, ngày giờ, validators, JWT decode
    widgets/      # AppButton (primary/secondary/ghost/destructive), state widgets…
  features/
    auth/               # đăng nhập, đăng ký, xác thực email, phiên đăng nhập
    shell/              # bottom navigation 5 tab, màn hình admin-unsupported
    home/               # dashboard với shortcut theo vai trò
    training_packages/  # danh mục công khai + chi tiết gói
    coach/              # onboarding HLV, quản lý gói tập (tạo/sửa/lưu trữ)
    bookings/           # đơn đăng ký (học viên + HLV), mua gói thủ công
    sessions/           # lịch tập, xác nhận/hủy/hoàn thành buổi tập
    training_plan/      # đánh giá đầu vào, giáo án, ghi nhận tiến độ
    chat/               # phòng chat + tin nhắn (polling nhẹ, không websocket)
    notifications/      # thông báo + badge chưa đọc
    wallet/             # ví HLV (chỉ xem), màn hình rút tiền "sắp ra mắt"
    profile/            # tab tài khoản
```

- **State**: Riverpod 3 (Notifier/AsyncNotifier, không codegen).
- **Điều hướng**: go_router — redirect theo trạng thái đăng nhập và vai trò
  (`learner` / `coach` / `admin`; một tài khoản có thể giữ nhiều vai trò).
- **Auth**: JWT Bearer; refresh token xoay vòng tự động khi gặp 401 và retry
  đúng một lần; đăng xuất là thao tác phía client (backend không có endpoint
  logout). Token lưu bằng `flutter_secure_storage`.
- **API**: mọi response đi qua envelope `Result<T>`; body 200 với
  `isSuccess: false` vẫn được coi là lỗi; enum lạ không làm crash app;
  lỗi hiển thị tiếng Việt theo `error.code`.

## Phạm vi phase 1 (quan trọng)

Cố ý **không** có trong bản mobile này:

- Thanh toán online PayOS (`POST /api/bookings/purchase/payos`) — chỉ có
  ghi danh thủ công; UI hiển thị "Thanh toán online chưa hỗ trợ trên mobile."
- Tạo yêu cầu rút tiền (`POST /api/coaches/me/withdrawal-requests`) — ví chỉ
  xem số dư/giao dịch; nút Rút tiền dẫn tới màn hình "sẽ hỗ trợ sau".
- Dashboard quản trị — tài khoản chỉ có vai trò admin thấy màn hình
  "chưa hỗ trợ trên mobile".
- Luồng đặt buổi lẻ legacy (`POST /api/bookings/{id}/sessions`) — mua gói
  lịch cố định sẽ được backend tự tạo buổi tập.
- Các module legacy: `/api/packages`, `/api/coach-packages`, `/api/posts`.
- Mở phòng chat mới (`POST /api/chat/rooms`) — ngoài allow-list phase 1;
  mobile chỉ xem/gửi tin trong phòng đã có.

## Ghi chú tích hợp backend

- Backend **không có** endpoint liệt kê môn thể thao công khai (chỉ có
  `POST /api/sports` cho admin). Picker môn thể thao suy ra danh mục từ các
  gói tập đang mở bán và cho phép nhập mã môn thủ công. Nên bổ sung
  `GET /api/sports` ở backend.
- `GET /api/users/me` (docs/api/users.md) được dùng làm nguồn vai trò/hồ sơ
  chính; vai trò trong JWT chỉ là gợi ý nhanh cho UI.
- Chat/thông báo dùng polling nhẹ (chat 8s khi màn hình mở, dừng khi đóng)
  vì backend không có websocket.
