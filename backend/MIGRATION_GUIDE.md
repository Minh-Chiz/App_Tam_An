# 🔄 Hướng Dẫn Hoàn Tất Migration SQL Server

## ✅ Đã Hoàn Thành

- [x] Tạo database schema (TamAnDB)
- [x] Cập nhật `.env` với Windows Authentication
- [x] Cập nhật `database.js` để kết nối SQL Server
- [x] Cài đặt package `mssql`

## 📝 Bước Tiếp Theo: Chạy SQL Script

### 1. Chạy Schema SQL

**Cách 1: Dùng SSMS (Khuyên dùng)**
1. Mở SQL Server Management Studio
2. Connect với Windows Authentication
   - Server: `localhost\SQLEXPRESS`
3. File → Open → File
4. Chọn: `d:\Mobile_app\tam_an\backend\database\schema.sql`
5. Nhấn F5 để Execute
6. Kiểm tra: Database `TamAnDB` xuất hiện trong Object Explorer

**Cách 2: Dùng sqlcmd**
```cmd
sqlcmd -S localhost\SQLEXPRESS -E -i "d:\Mobile_app\tam_an\backend\database\schema.sql"
```

### 2. Test Kết Nối

Chạy lệnh sau để test:

```cmd
cd d:\Mobile_app\tam_an\backend\api
node -e "const {initDB} = require('./config/database'); initDB().then(() => console.log('Success!')).catch(e => console.error(e));"
```

**Kết quả mong đợi:**
```
🔌 Connecting to SQL Server...
   Server: localhost\SQLEXPRESS
   Database: TamAnDB
   Auth: Windows Authentication
✅ Connected to SQL Server
🗄️  Database: TamAnDB
Success!
```

### 3. Cập Nhật Route Files

Tôi đã chuẩn bị sẵn các file route đã được convert sang SQL Server syntax.

**Các file cần thay thế:**
- `routes/auth.js` - Authentication routes
- `routes/emotions.js` - Emotion tracking routes

Bạn muốn tôi:
- [ ] Tự động thay thế tất cả route files
- [ ] Hướng dẫn từng file một để bạn hiểu cách convert

## 🐛 Troubleshooting

### Lỗi: "Login failed"
- Kiểm tra SQL Server đang chạy: `Get-Service MSSQL*`
- Restart SQL Server nếu cần

### Lỗi: "Cannot open database"
- Database chưa được tạo
- Chạy lại schema.sql

### Lỗi: "Connection timeout"
- Kiểm tra server name trong `.env`
- Thử đổi `localhost\SQLEXPRESS` thành `.\SQLEXPRESS`

## 📞 Tiếp Theo

Sau khi chạy schema.sql thành công, cho tôi biết để tôi tiếp tục cập nhật route files!
