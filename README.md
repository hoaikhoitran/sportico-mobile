# Sportico Mobile

Ứng dụng di động Flutter cho **Sportico Platform** — kết nối huấn luyện viên
và người tập qua các gói tập có lịch cố định.

Backend: [sportico-platform](https://github.com/hoaikhoitran/sportico-platform)
(ASP.NET Core 8, Clean Architecture, PostgreSQL).

## Chạy ứng dụng

```sh
flutter pub get

# Production API (mặc định)
flutter run

# Backend local (Android emulator: 10.0.2.2 trỏ về máy host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5095

# Backend local (iOS simulator / desktop)
flutter run --dart-define=API_BASE_URL=http://localhost:5095
```

Mặc định `API_BASE_URL` là `https://sportico-api-khoi.azurewebsites.net`
(xem [lib/app/config/environment.dart](lib/app/config/environment.dart)).
Không có secret nào được commit — mọi cấu hình môi trường đi qua
`--dart-define`.

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
