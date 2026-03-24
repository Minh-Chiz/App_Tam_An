require('dotenv').config({ path: '../.env' });
const sql = require('mssql');

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_DATABASE,
    options: {
        encrypt: true,
        trustServerCertificate: true
    }
};

async function runMigration() {
    try {
        console.log('Connecting to database...');
        await sql.connect(config);

        console.log('Creating Challenges table...');
        await sql.query(`
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Challenges' and xtype='U')
            BEGIN
                CREATE TABLE Challenges (
                    id INT IDENTITY(1,1) PRIMARY KEY,
                    title NVARCHAR(255) NOT NULL,
                    description NVARCHAR(MAX) NOT NULL,
                    duration_days INT NOT NULL,
                    reward_points INT NOT NULL DEFAULT 50,
                    badge_icon NVARCHAR(50) DEFAULT '🏅',
                    is_active BIT DEFAULT 1,
                    created_at DATETIME DEFAULT GETDATE()
                )
            END
        `);

        console.log('Creating UserChallenges table...');
        await sql.query(`
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='UserChallenges' and xtype='U')
            BEGIN
                CREATE TABLE UserChallenges (
                    id INT IDENTITY(1,1) PRIMARY KEY,
                    user_id INT NOT NULL FOREIGN KEY REFERENCES Users(id),
                    challenge_id INT NOT NULL FOREIGN KEY REFERENCES Challenges(id),
                    start_date DATETIME NOT NULL DEFAULT GETDATE(),
                    last_checkin_date DATE NULL,
                    current_progress INT NOT NULL DEFAULT 0,
                    target_progress INT NOT NULL,
                    status VARCHAR(20) DEFAULT 'in_progress', -- in_progress, completed, failed
                    completed_at DATETIME NULL,
                    CONSTRAINT UQ_UserChallenge UNIQUE(user_id, challenge_id)
                )
            END
        `);

        // Insert seed challenges
        console.log('Inserting seed challenges...');
        await sql.query(`
            IF NOT EXISTS (SELECT * FROM Challenges)
            BEGIN
                INSERT INTO Challenges (title, description, duration_days, reward_points, badge_icon)
                VALUES 
                (N'Biết ơn mỗi ngày', N'Hãy viết ra 3 điều bạn cảm thấy biết ơn vào mỗi buổi sáng. Giúp cải thiện góc nhìn tích cực.', 7, 100, N'🙏'),
                (N'Thanh lọc kỹ thuật số', N'Dành 30 phút mỗi ngày hoàn toàn tắt điện thoại và các thiết bị điện tử. Thư giãn mắt và tâm trí.', 7, 150, N'📵'),
                (N'Thiền định cơ bản', N'Dành 10 phút ngồi yên tĩnh, tập trung vào hơi thở mỗi ngày.', 14, 300, N'🧘'),
                (N'Ngủ đủ giấc', N'Đi ngủ trước 11h đêm và đảm bảo ngủ đủ 7-8 tiếng liên tục.', 7, 200, N'😴'),
                (N'Thói quen tích cực', N'Ghi lại ít nhất một cảm xúc Tích Cực (Vui, Hào hứng...) mỗi ngày trên app.', 21, 500, N'🌟')
            END
        `);

        console.log('Migration completed successfully!');
    } catch (err) {
        console.error('Migration failed:', err);
    } finally {
        sql.close();
    }
}

runMigration();
