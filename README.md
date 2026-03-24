# Tâm An - Ứng dụng theo dõi cảm xúc

Ứng dụng mobile giúp bạn theo dõi và quản lý cảm xúc hàng ngày với backend SQL Server.

## 🚀 Tính năng

- ✅ Đăng ký / Đăng nhập với JWT authentication
- 📊 Theo dõi cảm xúc hàng ngày
- 📝 Thêm ngữ cảnh và ghi chú
- 📈 Thống kê và phân tích cảm xúc
- 📅 Lịch sử cảm xúc theo thời gian

## 🛠️ Công nghệ sử dụng

### Frontend (Flutter)
- Flutter SDK
- Provider (State management)
- Dio (HTTP client)
- Google Fonts
- Shared Preferences

### Backend (Node.js)
- Express.js
- SQL Server (mssql package)
- JWT Authentication
- Bcrypt (Password hashing)

## 📋 Yêu cầu hệ thống

- Flutter SDK >= 3.10.3
- Node.js >= 16.x
- SQL Server (Local hoặc Azure SQL)
- Android Studio / VS Code

## ⚙️ Cài đặt

### 1. Setup SQL Server Database

**Bước 1:** Chạy SQL script để tạo database

```bash
# Sử dụng SQL Server Management Studio hoặc sqlcmd
sqlcmd -S localhost -U sa -P YourPassword -i backend/database/schema.sql
```

Hoặc mở file `backend/database/schema.sql` trong SQL Server Management Studio và chạy script.

### 2. Setup Backend API

**Bước 1:** Cài đặt dependencies

```bash
cd backend/api
npm install
```

**Bước 2:** Tạo file `.env` từ template

```bash
cp .env.example .env
```

**Bước 3:** Cập nhật thông tin SQL Server trong `.env`

```env
DB_SERVER=localhost
DB_PORT=1433
DB_DATABASE=TamAnDB
DB_USER=sa
DB_PASSWORD=YourPassword
JWT_SECRET=your-secret-key-change-this
```

**Bước 4:** Chạy server

```bash
# Development mode (với auto-reload)
npm run dev

# Production mode
npm start
```

Server sẽ chạy tại: `http://localhost:3000`

### 3. Setup Flutter App

**Bước 1:** Cài đặt dependencies

```bash
cd d:/Mobile_app/tam_an
flutter pub get
```

**Bước 2:** Cập nhật API URL

Mở file `lib/services/api_service.dart` và cập nhật `baseUrl`:

```dart
static const String baseUrl = 'http://YOUR_IP:3000/api';
// Ví dụ: 'http://192.168.1.100:3000/api' cho testing trên thiết bị thật
// Hoặc: 'http://10.0.2.2:3000/api' cho Android emulator
```

**Bước 3:** Chạy ứng dụng

```bash
flutter run
```

## 🧪 Testing

### Test Backend API

**Health Check:**
```bash
curl http://localhost:3000/health
```

**Register:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}'
```

**Login:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### Test Flutter App

1. Chạy backend server
2. Chạy Flutter app
3. Đăng ký tài khoản mới
4. Đăng nhập
5. Tạo emotion entry
6. Xem dashboard và history

## 📁 Cấu trúc dự án

```
tam_an/
├── backend/
│   ├── database/
│   │   └── schema.sql          # SQL Server schema
│   └── api/
│       ├── config/
│       │   └── database.js     # Database config
│       ├── middleware/
│       │   └── auth.js         # JWT middleware
│       ├── routes/
│       │   ├── auth.js         # Auth routes
│       │   └── emotions.js     # Emotion routes
│       ├── .env.example        # Environment template
│       ├── package.json
│       └── server.js           # Main server
│
└── lib/
    ├── models/
    │   ├── user.dart
    │   └── emotion.dart
    ├── services/
    │   ├── api_service.dart
    │   ├── auth_service.dart
    │   └── emotion_service.dart
    ├── providers/
    │   ├── auth_provider.dart
    │   └── emotion_provider.dart
    ├── screens/
    │   ├── login_screen.dart
    │   ├── emotion_checkin_screen.dart
    │   ├── context_tag_screen.dart
    │   └── ...
    ├── theme/
    │   └── app_theme.dart
    └── main.dart
```

## 🔐 Security

- Passwords được hash với bcrypt (10 salt rounds)
- JWT tokens cho authentication
- Protected routes yêu cầu valid token
- Input validation trên cả client và server

## 🐛 Troubleshooting

### Backend không kết nối được SQL Server

- Kiểm tra SQL Server đang chạy
- Kiểm tra thông tin connection trong `.env`
- Kiểm tra firewall settings
- Kiểm tra SQL Server authentication mode (Mixed Mode)

### Flutter không kết nối được backend

- Kiểm tra backend server đang chạy
- Kiểm tra API URL trong `api_service.dart`
- Với Android emulator: sử dụng `10.0.2.2` thay vì `localhost`
- Với thiết bị thật: sử dụng IP của máy chạy backend

### CORS errors

- Backend đã cấu hình CORS, nhưng nếu vẫn gặp lỗi, kiểm tra `server.js`

## 📝 API Endpoints

### Authentication
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/login` - Đăng nhập
- `GET /api/auth/profile` - Lấy profile (protected)

### Emotions
- `POST /api/emotions` - Tạo emotion entry (protected)
- `GET /api/emotions` - Lấy danh sách emotions (protected)
- `GET /api/emotions/:id` - Lấy emotion by ID (protected)
- `GET /api/emotions/stats/summary` - Lấy thống kê (protected)
- `GET /api/emotions/range/dates` - Lấy emotions theo date range (protected)

## 👥 Contributors

Phát triển bởi team Tâm An

## 📄 License

MIT License
