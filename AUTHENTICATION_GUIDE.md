# Hướng dẫn Đăng ký và Đăng nhập

## 🎯 Tổng quan

Ứng dụng Tâm An giờ đây đã có chức năng đăng ký và đăng nhập hoàn chỉnh với backend SQL Server.

## 📝 Cách sử dụng

### 1. Khởi động Backend Server

Trước khi sử dụng app, bạn cần khởi động backend server:

```bash
# Di chuyển vào thư mục backend
cd d:/Mobile_app/tam_an/backend/api

# Cài đặt dependencies (chỉ cần làm 1 lần)
npm install

# Tạo file .env từ template (chỉ cần làm 1 lần)
cp .env.example .env

# Chỉnh sửa file .env với thông tin SQL Server của bạn
# DB_SERVER=localhost
# DB_USER=sa
# DB_PASSWORD=YourPassword
# JWT_SECRET=your-secret-key

# Khởi động server
npm run dev
```

Server sẽ chạy tại: `http://localhost:3000`

### 2. Cập nhật API URL trong Flutter

Mở file `lib/services/api_service.dart` và cập nhật `baseUrl`:

```dart
static const String baseUrl = 'http://YOUR_IP:3000/api';
```

**Lưu ý:**
- Nếu test trên **Android Emulator**: dùng `http://10.0.2.2:3000/api`
- Nếu test trên **iOS Simulator**: dùng `http://localhost:3000/api`
- Nếu test trên **thiết bị thật**: dùng IP của máy tính (ví dụ: `http://192.168.1.100:3000/api`)

### 3. Chạy Flutter App

```bash
# Di chuyển vào thư mục Flutter
cd d:/Mobile_app/tam_an

# Chạy app
flutter run
```

### 4. Đăng ký tài khoản mới

1. Mở app, bạn sẽ thấy màn hình **Đăng nhập**
2. Nhấn vào **"Chưa có tài khoản? Đăng ký"** ở dưới cùng
3. Nhập thông tin:
   - **Tên**: Tên của bạn (ví dụ: "Nguyễn Văn A")
   - **Email**: Email hợp lệ (ví dụ: "nguyenvana@example.com")
   - **Mật khẩu**: Tối thiểu 6 ký tự (ví dụ: "123456")
4. Nhấn **"Tạo tài khoản"**
5. Nếu thành công, bạn sẽ thấy thông báo "✅ Đăng ký thành công!" và tự động đăng nhập vào app

### 5. Đăng nhập

1. Nếu đã có tài khoản, ở màn hình **Đăng nhập**:
2. Nhập **Email** và **Mật khẩu** của bạn
3. Nhấn **"Đăng nhập"**
4. Nếu thành công, bạn sẽ vào màn hình chính của app

### 6. Sử dụng app

Sau khi đăng nhập, bạn có thể:
- ✅ Ghi nhận cảm xúc hàng ngày
- ✅ Thêm ngữ cảnh (địa điểm, hoạt động, người đi cùng)
- ✅ Viết ghi chú về cảm xúc
- ✅ Xem lịch sử cảm xúc
- ✅ Xem thống kê cảm xúc

## 🔐 Bảo mật

- Mật khẩu được mã hóa với **bcrypt** trước khi lưu vào database
- Sử dụng **JWT token** để xác thực
- Token được lưu an toàn trong **SharedPreferences**
- Token tự động được thêm vào mọi request đến server

## 🐛 Xử lý lỗi

### "Cannot connect to server"
- ✅ Kiểm tra backend server đang chạy
- ✅ Kiểm tra API URL trong `api_service.dart`
- ✅ Kiểm tra firewall không chặn port 3000

### "Email already registered"
- ✅ Email này đã được đăng ký trước đó
- ✅ Sử dụng email khác hoặc đăng nhập với email này

### "Invalid email or password"
- ✅ Kiểm tra lại email và mật khẩu
- ✅ Đảm bảo đã đăng ký tài khoản trước

### "Password must be at least 6 characters"
- ✅ Mật khẩu phải có ít nhất 6 ký tự

## 📊 Kiểm tra dữ liệu trong Database

Để xem tài khoản đã được lưu vào database:

```sql
-- Xem tất cả users
SELECT id, email, name, created_at FROM Users;

-- Xem emotions của một user
SELECT * FROM EmotionHistory WHERE user_id = 1 ORDER BY timestamp DESC;

-- Xem thống kê emotions
EXEC GetUserEmotionStats @user_id = 1, @days = 7;
```

## 🎨 Tính năng UI

### Màn hình Đăng ký
- ✨ Gradient background đẹp mắt
- ✨ Animations mượt mà (fade + slide)
- ✨ Form validation real-time
- ✨ Loading indicator khi đang xử lý
- ✨ Error messages rõ ràng
- ✨ Link quay lại đăng nhập

### Màn hình Đăng nhập
- ✨ Thiết kế tương tự register screen
- ✨ Glassmorphism effect
- ✨ Auto-login nếu đã có token
- ✨ Link đến register screen

## 🔄 Flow hoàn chỉnh

```
1. Mở app
   ↓
2. Kiểm tra token
   ↓
3a. Có token → Auto login → Home Screen
3b. Không có token → Login Screen
   ↓
4. Chọn "Đăng ký" → Register Screen
   ↓
5. Nhập thông tin → Submit
   ↓
6. Backend tạo user + JWT token
   ↓
7. Flutter lưu token → Navigate to Home
   ↓
8. Ghi nhận cảm xúc → Lưu vào database
   ↓
9. Xem lịch sử và thống kê
```

## 🎯 Test Cases

### Test 1: Đăng ký thành công
1. Mở app
2. Nhấn "Đăng ký"
3. Nhập: Tên="Test User", Email="test@example.com", Password="123456"
4. Nhấn "Tạo tài khoản"
5. **Expected**: Thông báo thành công, tự động đăng nhập

### Test 2: Đăng ký với email đã tồn tại
1. Đăng ký với email đã dùng
2. **Expected**: Lỗi "Email already registered"

### Test 3: Đăng ký với mật khẩu ngắn
1. Nhập password < 6 ký tự
2. **Expected**: Lỗi "Mật khẩu phải có ít nhất 6 ký tự"

### Test 4: Đăng nhập thành công
1. Nhập email và password đúng
2. **Expected**: Đăng nhập thành công, vào Home Screen

### Test 5: Đăng nhập sai mật khẩu
1. Nhập email đúng, password sai
2. **Expected**: Lỗi "Invalid email or password"

### Test 6: Auto-login
1. Đăng nhập thành công
2. Đóng app
3. Mở lại app
4. **Expected**: Tự động đăng nhập, không cần nhập lại

## 📱 Screenshots Flow

1. **Login Screen** → Nhấn "Đăng ký"
2. **Register Screen** → Nhập thông tin
3. **Loading** → Đang xử lý
4. **Success** → Thông báo thành công
5. **Home Screen** → Đã đăng nhập

## ✅ Checklist

- [x] Backend API hoạt động
- [x] Register screen với validation
- [x] Login screen với validation
- [x] JWT authentication
- [x] Token storage
- [x] Auto-login
- [x] Error handling
- [x] Loading states
- [x] Beautiful UI/UX
- [x] Navigation flow

## 🎉 Kết luận

Bây giờ bạn có thể:
1. ✅ Tự đăng ký tài khoản mới
2. ✅ Đăng nhập với tài khoản đã tạo
3. ✅ Tài khoản được lưu an toàn trong SQL Server
4. ✅ Tự động đăng nhập lại khi mở app
5. ✅ Sử dụng app để theo dõi cảm xúc

Chúc bạn có trải nghiệm tốt với ứng dụng Tâm An! 🌟
