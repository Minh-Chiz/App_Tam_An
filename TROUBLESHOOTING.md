# 🚨 Khắc phục lỗi "Cannot connect to server"

## ❌ Lỗi bạn đang gặp

```
❌ Error: The connection errored: The XMLHttpRequest onError callback was called.
```

**Nguyên nhân:** Backend server chưa được khởi động!

## ✅ Giải pháp - Làm theo các bước sau:

### Bước 1: Khởi động Backend Server

**Mở Terminal/Command Prompt mới** và chạy:

```bash
# Di chuyển vào thư mục backend
cd d:\Mobile_app\tam_an\backend\api

# Kiểm tra xem đã cài dependencies chưa
# Nếu chưa có thư mục node_modules, chạy:
npm install

# Tạo file .env nếu chưa có
# Copy từ .env.example
copy .env.example .env

# Khởi động server
npm run dev
```

**Kết quả mong đợi:**

```
=================================
🚀 Tâm An API Server
📡 Server running on port 3000
🌍 Environment: development
🗄️  Database: TamAnDB
=================================
```

### Bước 2: Kiểm tra Backend đang chạy

Mở browser và truy cập: `http://localhost:3000/health`

**Kết quả mong đợi:**
```json
{
  "success": true,
  "message": "Tâm An API is running",
  "timestamp": "..."
}
```

### Bước 3: Cấu hình API URL trong Flutter

**Quan trọng:** Bạn đang test trên thiết bị nào?

#### 🖥️ Nếu test trên **Android Emulator**:

Mở file `lib/services/api_service.dart` và sửa dòng 5:

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

#### 📱 Nếu test trên **iOS Simulator**:

```dart
static const String baseUrl = 'http://localhost:3000/api';
```

#### 📲 Nếu test trên **thiết bị thật** (Android/iOS):

1. Kiểm tra IP của máy tính:
   ```bash
   ipconfig
   # Tìm IPv4 Address, ví dụ: 192.168.1.100
   ```

2. Sửa API URL:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:3000/api';
   ```

### Bước 4: Hot Reload Flutter App

Sau khi sửa API URL:

1. Lưu file `api_service.dart`
2. Trong terminal Flutter, nhấn `r` để hot reload
3. Hoặc nhấn `R` để hot restart

### Bước 5: Test lại đăng ký

1. Mở app
2. Nhấn "Đăng ký"
3. Nhập thông tin
4. Nhấn "Tạo tài khoản"

**Kết quả mong đợi:**
- ✅ Thông báo "Đăng ký thành công!"
- ✅ Tự động đăng nhập vào app

## 🔍 Troubleshooting

### Vẫn lỗi "Cannot connect to server"?

**Kiểm tra 1:** Backend có đang chạy không?
```bash
# Trong terminal backend, bạn phải thấy:
🚀 Tâm An API Server
📡 Server running on port 3000
```

**Kiểm tra 2:** Test backend bằng curl hoặc browser
```bash
curl http://localhost:3000/health
```

**Kiểm tra 3:** Firewall có chặn không?
- Windows: Cho phép Node.js qua Windows Firewall
- Antivirus: Tạm tắt để test

**Kiểm tra 4:** API URL đúng chưa?
- Android Emulator: `http://10.0.2.2:3000/api`
- iOS Simulator: `http://localhost:3000/api`
- Thiết bị thật: `http://YOUR_IP:3000/api`

### Lỗi "Database connection failed"?

Backend chạy nhưng không kết nối được SQL Server:

1. Kiểm tra SQL Server đang chạy
2. Kiểm tra file `.env` có đúng thông tin:
   ```env
   DB_SERVER=localhost
   DB_USER=sa
   DB_PASSWORD=YourPassword
   DB_DATABASE=TamAnDB
   ```
3. Kiểm tra đã chạy `schema.sql` chưa

### Lỗi "npm: command not found"?

Bạn chưa cài Node.js:
1. Download Node.js từ: https://nodejs.org/
2. Cài đặt Node.js
3. Restart terminal
4. Chạy lại `npm install`

## 📝 Checklist

- [ ] Backend server đang chạy (port 3000)
- [ ] Test `http://localhost:3000/health` thành công
- [ ] Đã sửa API URL trong `api_service.dart`
- [ ] Đã hot reload/restart Flutter app
- [ ] SQL Server đang chạy và có database TamAnDB

## 🎯 Quick Fix Commands

```bash
# Terminal 1: Start Backend
cd d:\Mobile_app\tam_an\backend\api
npm run dev

# Terminal 2: Run Flutter
cd d:\Mobile_app\tam_an
flutter run

# Browser: Test Backend
http://localhost:3000/health
```

## 💡 Lưu ý

- **Luôn khởi động backend TRƯỚC** khi chạy Flutter app
- Backend phải chạy **liên tục** khi bạn sử dụng app
- Nếu tắt backend, app sẽ không thể đăng ký/đăng nhập

## 🆘 Vẫn không được?

Gửi cho tôi:
1. Output của terminal backend
2. Output của terminal Flutter
3. Thiết bị bạn đang test (Emulator/Simulator/Real device)
4. API URL bạn đang dùng trong `api_service.dart`
