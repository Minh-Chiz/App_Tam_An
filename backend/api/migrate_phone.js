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

async function migrate() {
    try {
        const pool = await sql.connect(config);
        console.log('Connected to DB');

        const queries = [
            `IF COL_LENGTH('Users', 'phone_number') IS NULL
             BEGIN
                 ALTER TABLE Users ADD phone_number NVARCHAR(20) NULL;
                 EXEC('CREATE UNIQUE NONCLUSTERED INDEX idx_phone_number ON Users(phone_number) WHERE phone_number IS NOT NULL');
                 PRINT 'Added phone_number column and index';
             END`,
             `IF COL_LENGTH('Users', 'reset_otp') IS NULL
             BEGIN
                 ALTER TABLE Users ADD reset_otp NVARCHAR(10) NULL;
                 ALTER TABLE Users ADD reset_otp_expires_at DATETIME2 NULL;
                 PRINT 'Added OTP columns';
             END`
        ];

        for (const q of queries) {
            await pool.request().query(q);
        }

        console.log('Migration completed successfully!');
        await pool.close();
    } catch (e) {
        console.error('Migration failed:', e);
    }
}

migrate();
