# Tâm An Backend API

Backend API server cho ứng dụng Tâm An sử dụng Node.js, Express và SQL Server.

## Cài đặt

### 1. Cài đặt Dependencies

```bash
cd backend/api
npm install
```

### 2. Cấu hình Database

Tạo file `.env` từ `.env.example`:

```bash
cp .env.example .env
```

Cập nhật thông tin SQL Server trong file `.env`:

```env
DB_SERVER=localhost
DB_PORT=1433
DB_DATABASE=TamAnDB
DB_USER=sa
DB_PASSWORD=YourPassword
JWT_SECRET=your-secret-key
```

### 3. Tạo Database Schema

Chạy SQL script để tạo database:

```bash
# Sử dụng SQL Server Management Studio hoặc sqlcmd
sqlcmd -S localhost -U sa -P YourPassword -i ../database/schema.sql
```

### 4. Chạy Server

Development mode (với auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

Server sẽ chạy tại: `http://localhost:3000`

## API Endpoints

### Authentication

**Register**
```
POST /api/auth/register
Body: { "email": "user@example.com", "password": "password123", "name": "User Name" }
```

**Login**
```
POST /api/auth/login
Body: { "email": "user@example.com", "password": "password123" }
```

**Get Profile** (Protected)
```
GET /api/auth/profile
Headers: { "Authorization": "Bearer <token>" }
```

### Emotions

**Create Emotion Entry** (Protected)
```
POST /api/emotions
Headers: { "Authorization": "Bearer <token>" }
Body: {
  "emotion_type": "Vui",
  "intensity": 8,
  "location": "Ở nhà",
  "activity": "Code",
  "company": "Một mình",
  "note_text": "Hoàn thành project thành công!"
}
```

**Get Emotions** (Protected)
```
GET /api/emotions?limit=50&offset=0
Headers: { "Authorization": "Bearer <token>" }
```

**Get Emotion by ID** (Protected)
```
GET /api/emotions/:id
Headers: { "Authorization": "Bearer <token>" }
```

**Get Statistics** (Protected)
```
GET /api/emotions/stats/summary?days=7
Headers: { "Authorization": "Bearer <token>" }
```

**Get Emotions by Date Range** (Protected)
```
GET /api/emotions/range/dates?start_date=2024-01-01&end_date=2024-01-31
Headers: { "Authorization": "Bearer <token>" }
```

## Testing

Test với curl:

```bash
# Health check
curl http://localhost:3000/health

# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

## Cấu trúc thư mục

```
backend/api/
├── config/
│   └── database.js       # Database configuration
├── middleware/
│   └── auth.js          # JWT authentication middleware
├── routes/
│   ├── auth.js          # Authentication routes
│   └── emotions.js      # Emotion routes
├── .env.example         # Environment variables template
├── package.json         # Dependencies
└── server.js           # Main server file
```
