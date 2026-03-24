# Hướng dẫn Cài đặt và Kết nối SQL Server

## 📋 Kiểm tra SQL Server

### Bước 1: Kiểm tra SQL Server đã cài đặt chưa

Chạy lệnh sau trong PowerShell:

```powershell
Get-Service -Name MSSQL*
```

**Nếu thấy service như `MSSQLSERVER` hoặc `MSSQL$SQLEXPRESS`:**
- ✅ SQL Server đã được cài đặt
- Kiểm tra Status: phải là **Running**

**Nếu không thấy service nào:**
- ❌ SQL Server chưa được cài đặt
- Cần cài đặt SQL Server Express (miễn phí)

## 🔧 Cài đặt SQL Server Express (Nếu chưa có)

### Tải SQL Server Express

1. Truy cập: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
2. Chọn **Download now** ở phần **Express**
3. Chạy file installer

### Cài đặt

1. Chọn **Basic** installation
2. Chấp nhận license terms
3. Chọn thư mục cài đặt (mặc định OK)
4. Đợi cài đặt hoàn tất (5-10 phút)
5. **Quan trọng:** Ghi nhớ **Instance name** (thường là `SQLEXPRESS`)

### Cài đặt SQL Server Management Studio (SSMS) - Optional nhưng khuyên dùng

1. Sau khi cài SQL Server, installer sẽ hỏi có muốn cài SSMS không
2. Hoặc tải tại: https://aka.ms/ssmsfullsetup
3. SSMS giúp quản lý database dễ dàng hơn

## 🔐 Cấu hình SQL Server Authentication

### Bước 1: Bật SQL Server Authentication Mode

1. Mở **SQL Server Management Studio (SSMS)**
2. Connect với **Windows Authentication**
   - Server name: `localhost\SQLEXPRESS` (hoặc `localhost`)
   - Authentication: **Windows Authentication**
3. Right-click vào server → **Properties**
4. Chọn **Security** → Chọn **SQL Server and Windows Authentication mode**
5. Click **OK**

### Bước 2: Tạo SQL Login

1. Trong SSMS, mở **Security** → **Logins**
2. Right-click **Logins** → **New Login**
3. Nhập:
   - Login name: `sa` (hoặc tên khác)
   - Chọn **SQL Server authentication**
   - Password: Nhập password mạnh (ví dụ: `YourStrongPass123!`)
   - Bỏ tick **Enforce password policy** (để test dễ hơn)
4. Chọn **Server Roles** → Tick **sysadmin**
5. Click **OK**

### Bước 3: Enable TCP/IP

1. Mở **SQL Server Configuration Manager**
   - Tìm trong Start Menu: "SQL Server Configuration Manager"
2. Mở **SQL Server Network Configuration** → **Protocols for SQLEXPRESS**
3. Right-click **TCP/IP** → **Enable**
4. Right-click **TCP/IP** → **Properties**
5. Tab **IP Addresses** → Kéo xuống **IPALL**
   - **TCP Port**: Nhập `1433`
6. Click **OK**

### Bước 4: Restart SQL Server

1. Trong **SQL Server Configuration Manager**
2. Chọn **SQL Server Services**
3. Right-click **SQL Server (SQLEXPRESS)** → **Restart**

## 🗄️ Tạo Database

### Option 1: Dùng SSMS (Dễ hơn)

1. Mở SSMS
2. Connect với SQL authentication:
   - Server: `localhost\SQLEXPRESS` hoặc `localhost,1433`
   - Authentication: **SQL Server Authentication**
   - Login: `sa`
   - Password: password bạn đã tạo
3. Click **New Query**
4. Copy và chạy script từ file `backend/database/schema.sql`

### Option 2: Dùng sqlcmd

```cmd
sqlcmd -S localhost,1433 -U sa -P YourPassword -i d:\Mobile_app\tam_an\backend\database\schema.sql
```

## ⚙️ Cấu hình Backend

### Bước 1: Cập nhật package.json

File `backend/api/package.json` cần có `mssql`:

```json
{
  "dependencies": {
    "express": "^4.18.2",
    "mssql": "^10.0.1",
    "bcrypt": "^5.1.1",
    "jsonwebtoken": "^9.0.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "body-parser": "^1.20.2"
  }
}
```

### Bước 2: Tạo file .env

Trong `backend/api/.env`:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# SQL Server Configuration
DB_SERVER=localhost
DB_PORT=1433
DB_DATABASE=TamAnDB
DB_USER=sa
DB_PASSWORD=YourStrongPass123!

# JWT Secret
JWT_SECRET=your-secret-key-change-this-in-production
JWT_EXPIRES_IN=7d
```

**Quan trọng:** Thay `YourStrongPass123!` bằng password thực tế của bạn!

### Bước 3: Test kết nối

Tạo file test `backend/api/test-connection.js`:

```javascript
const sql = require('mssql');
require('dotenv').config();

const config = {
  server: process.env.DB_SERVER || 'localhost',
  port: parseInt(process.env.DB_PORT) || 1433,
  database: process.env.DB_DATABASE || 'TamAnDB',
  user: process.env.DB_USER || 'sa',
  password: process.env.DB_PASSWORD,
  options: {
    encrypt: true,
    trustServerCertificate: true,
    enableArithAbort: true,
  },
};

async function testConnection() {
  try {
    console.log('Testing connection with config:', {
      server: config.server,
      port: config.port,
      database: config.database,
      user: config.user,
    });
    
    const pool = await sql.connect(config);
    console.log('✅ Connected to SQL Server successfully!');
    
    const result = await pool.request().query('SELECT @@VERSION as version');
    console.log('SQL Server version:', result.recordset[0].version);
    
    await pool.close();
  } catch (err) {
    console.error('❌ Connection failed:', err.message);
  }
}

testConnection();
```

Chạy test:

```cmd
cd d:\Mobile_app\tam_an\backend\api
node test-connection.js
```

**Kết quả mong đợi:**
```
✅ Connected to SQL Server successfully!
SQL Server version: Microsoft SQL Server 2022...
```

## 🐛 Troubleshooting

### Lỗi: "Login failed for user 'sa'"

- Kiểm tra password trong `.env` đúng chưa
- Kiểm tra SQL Server Authentication mode đã bật chưa
- Restart SQL Server sau khi thay đổi

### Lỗi: "Could not connect (sequence)"

- Kiểm tra SQL Server đang chạy: `Get-Service MSSQL*`
- Kiểm tra TCP/IP đã enable chưa
- Kiểm tra port 1433 có đúng không

### Lỗi: "Cannot open database 'TamAnDB'"

- Database chưa được tạo
- Chạy script `schema.sql` trong SSMS

### Lỗi: "Network error"

- Firewall có thể đang chặn port 1433
- Thêm rule cho SQL Server trong Windows Firewall

## ✅ Checklist

- [ ] SQL Server đã cài đặt
- [ ] SQL Server đang chạy (Status: Running)
- [ ] SQL Authentication mode đã bật
- [ ] User `sa` đã tạo với password
- [ ] TCP/IP đã enable trên port 1433
- [ ] SQL Server đã restart
- [ ] Database `TamAnDB` đã tạo (chạy schema.sql)
- [ ] File `.env` đã cấu hình đúng
- [ ] Test connection thành công

## 🚀 Khởi động Backend

Sau khi hoàn tất các bước trên:

```cmd
cd d:\Mobile_app\tam_an\backend\api
npm install
npm run dev
```

**Kết quả mong đợi:**
```
✅ Connected to SQL Server
🚀 Tâm An API Server
📡 Server running on port 3000
🗄️  Database: TamAnDB
```
