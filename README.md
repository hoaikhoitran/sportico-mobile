# Sportico Mobile

Ứng dụng di động Flutter cho **Sportico Platform** — kết nối huấn luyện viên
và người tập qua các gói tập có lịch cố định.

Backend: [sportico-platform](https://github.com/hoaikhoitran/sportico-platform)
(ASP.NET Core 8, Clean Architecture, PostgreSQL).

## Chạy ứng dụng

Toàn bộ cấu hình môi trường đi qua `--dart-define` (không có secret nào được
commit). App đọc hai giá trị:

- `API_BASE_URL` — base URL của backend. **Mặc định:** `http://10.0.2.2:5095`
  (backend local nhìn từ Android emulator). Nếu không truyền, app in cảnh báo
  rõ ràng lên console debug.
- `APP_ENV` — `local` (mặc định) hoặc `production`.

Nguồn duy nhất: [lib/app/config/environment.dart](lib/app/config/environment.dart)
→ [lib/app/config/app_config.dart](lib/app/config/app_config.dart) → Dio client.
Không file API/repository nào hardcode URL.

### File môi trường

Thay vì gõ tay từng `--dart-define`, các giá trị nằm trong
[dart_defines/](dart_defines/) và được nạp bằng `--dart-define-from-file`:

| File | Dùng cho | `API_BASE_URL` |
|------|----------|----------------|
| `dart_defines/production.json` | Backend Azure (production) | `https://sportico-api-khoi-g3bpg4a3dnhehng8.japaneast-01.azurewebsites.net` |
| `dart_defines/local_android.json` | Android emulator + backend local | `http://10.0.2.2:5095` |
| `dart_defines/local_ios.json` | iOS simulator / Windows desktop + backend local | `http://127.0.0.1:5095` |
| `dart_defines/local_device.json` | Điện thoại thật + backend local (tự tạo, đã gitignore) | IPv4 LAN của máy bạn |

```sh
flutter pub get
```

**Production (backend Azure):**

```bash
flutter run --dart-define-from-file=dart_defines/production.json
```

**Android emulator + backend local** (`10.0.2.2` trỏ về máy host):

```bash
flutter run --dart-define-from-file=dart_defines/local_android.json
```

**iOS simulator / Windows desktop + backend local:**

```bash
flutter run --dart-define-from-file=dart_defines/local_ios.json
```

**Điện thoại thật + backend local** — copy file mẫu rồi sửa IP (xem `ipconfig` /
`ifconfig`; điện thoại và máy tính phải cùng Wi-Fi):

```bash
cp dart_defines/local_device.example.json dart_defines/local_device.json
flutter run --dart-define-from-file=dart_defines/local_device.json
```

`flutter build apk|appbundle|windows` nhận cùng flag này — nhớ truyền
`--dart-define-from-file=dart_defines/production.json` khi build bản phát hành,
nếu không app sẽ rơi về backend local mặc định.

Dùng VS Code: chọn sẵn profile trong `.vscode/launch.json` —
`Sportico Production`, `Sportico Local Android Emulator`,
`Sportico Local iOS Simulator`, `Sportico Local Windows (127.0.0.1)`,
`Sportico Windows - Production`, `Sportico Local Physical Device (LAN)`.

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
- **DNS production lỗi** → dùng hostname regional mới
  `sportico-api-khoi-g3bpg4a3dnhehng8.japaneast-01.azurewebsites.net`
  (hostname cũ `sportico-api-khoi.azurewebsites.net` không còn phân giải);
  hoặc chuyển sang backend local bằng `--dart-define` như trên.

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
    shell/              # bottom navigation 5 tab của người dùng
    admin/              # khu vực quản trị (shell riêng, xem mục bên dưới)
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

## Khu vực quản trị (`/admin`)

Tài khoản có vai trò `admin` có shell riêng (`StatefulShellRoute.indexedStack`)
với 5 tab: **Tổng quan · Phê duyệt · Tài chính · Người dùng · Thêm**. Trên tablet
(≥ 720dp) bottom bar đổi thành `NavigationRail`, dùng chung logic.

| Tab | Nội dung | Endpoint |
|-----|----------|----------|
| Tổng quan | KPI + lọc theo khoảng ngày + lối tắt | `GET /api/admin/dashboard` |
| Phê duyệt | Gói tập · Bài viết · Tài khoản nhận tiền · Báo cáo đánh giá | `…/training-packages/pending`, `…/posts/pending`, `…/coach-payout-accounts/pending`, `…/review-reports` |
| Tài chính | Yêu cầu rút tiền (+ biên nhận) · Tỷ lệ hoa hồng | `…/withdrawal-requests*`, `…/platform-settings/commission` |
| Người dùng | Tìm kiếm/lọc, xem, tạo, sửa, ngừng hoạt động | `/api/admin/users` |
| Thêm | Cấu hình nền tảng, thông tin tài khoản, đăng xuất | — |

Nguyên tắc:

- **Phân quyền**: mọi route `/admin/*` được chặn ở router theo vai trò lấy từ
  `/api/users/me`. Tài khoản chỉ có `admin` vào thẳng `/admin/dashboard`; tài
  khoản đa vai trò vẫn giữ nguyên trải nghiệm learner/coach và vào khu vực quản
  trị từ tab Tài khoản.
- **Hành động theo trạng thái**: nút hiển thị đúng những gì backend chấp nhận
  (xem `WithdrawalActions`) — ví dụ yêu cầu đang `processing` chỉ có "Cập nhật
  trạng thái thanh toán".
- **`DELETE /api/admin/users/{id}` là ngừng hoạt động** (`status → inactive`),
  không xóa dữ liệu — UI ghi rõ điều này trong hộp thoại xác nhận.
- **Hoa hồng tính theo phần trăm 0–100** (`15` = 15%, backend tự chia 100), tối
  đa 2 chữ số thập phân, chỉ áp dụng cho đơn phát sinh sau khi lưu.
- **Dữ liệu nhạy cảm**: số tài khoản ngân hàng được che ở danh sách, chỉ hiện
  đầy đủ ở màn hình xác minh; không log token/số tài khoản/mã lệnh chi.
- State quản trị dùng provider `autoDispose` nên tự xóa khỏi bộ nhớ khi rời khu
  vực quản trị hoặc đăng xuất.

## Phạm vi phase 1 (quan trọng)

Cố ý **không** có trong bản mobile này:

- Thanh toán online PayOS (`POST /api/bookings/purchase/payos`) — chỉ có
  ghi danh thủ công; UI hiển thị "Thanh toán online chưa hỗ trợ trên mobile."
- Tạo yêu cầu rút tiền (`POST /api/coaches/me/withdrawal-requests`) — ví chỉ
  xem số dư/giao dịch; nút Rút tiền dẫn tới màn hình "sẽ hỗ trợ sau".
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
- **Các DTO quản trị chỉ trả về `coachId`/`reporterId` (UUID), không có tên.**
  Vì `CoachId` chính là `User.Id`, app phân giải danh tính qua
  `GET /api/admin/users/{id}` và cache theo id (`AdminIdentityCache`). Nếu
  backend nhúng sẵn tên/avatar vào các response này thì bỏ được N+1 request.
- **Không có `GET` theo id cho gói tập / bài viết / báo cáo / tài khoản nhận
  tiền ở API quản trị** (chỉ có danh sách `…/pending`). Màn hình chi tiết nhận
  entity từ danh sách qua `extra`; nếu mục không còn trong hàng chờ, màn hình
  báo rõ thay vì dựng dữ liệu giả.
- `TrainingPackageResponse` (hàng chờ duyệt) **không có ảnh** và không có tên
  HLV — UI chỉ hiển thị đúng những trường backend trả về.
- Chat/thông báo dùng polling nhẹ (chat 8s khi màn hình mở, dừng khi đóng)
  vì backend không có websocket.
"# sportico-mobile" 
