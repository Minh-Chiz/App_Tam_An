-- =============================================
-- Tâm An Database Schema
-- SQL Server Database Setup
-- =============================================

-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TamAnDB')
BEGIN
    CREATE DATABASE TamAnDB;
END
GO

USE TamAnDB;
GO

-- =============================================
-- Table: Users
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        id INT IDENTITY(1,1) PRIMARY KEY,
        email NVARCHAR(255) NOT NULL UNIQUE,
        password_hash NVARCHAR(255) NOT NULL,
        name NVARCHAR(100) NOT NULL,
        avatar_url NVARCHAR(MAX),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        INDEX idx_email (email)
    );
END
GO

-- =============================================
-- Table: Emotions
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Emotions')
BEGIN
    CREATE TABLE Emotions (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        emotion_type NVARCHAR(50) NOT NULL, -- 'Vui', 'Bình thường', 'Buồn', 'Căng thẳng'
        intensity INT DEFAULT 5, -- 1-10 scale
        timestamp DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
        INDEX idx_user_timestamp (user_id, timestamp DESC)
    );
END
GO

-- =============================================
-- Table: Contexts
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Contexts')
BEGIN
    CREATE TABLE Contexts (
        id INT IDENTITY(1,1) PRIMARY KEY,
        emotion_id INT NOT NULL,
        location NVARCHAR(100), -- 'Ở nhà', 'Công ty', 'Trường học', etc.
        activity NVARCHAR(100), -- 'Học', 'Code', 'Làm việc', etc.
        company NVARCHAR(100), -- 'Một mình', 'Bạn bè', 'Gia đình', etc.
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (emotion_id) REFERENCES Emotions(id) ON DELETE CASCADE,
        INDEX idx_emotion (emotion_id)
    );
END
GO

-- =============================================
-- Table: Notes
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Notes')
BEGIN
    CREATE TABLE Notes (
        id INT IDENTITY(1,1) PRIMARY KEY,
        emotion_id INT NOT NULL,
        note_text NVARCHAR(MAX),
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (emotion_id) REFERENCES Emotions(id) ON DELETE CASCADE,
        INDEX idx_emotion (emotion_id)
    );
END
GO

-- =============================================
-- Table: UserSettings
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserSettings')
BEGIN
    CREATE TABLE UserSettings (
        user_id INT PRIMARY KEY,
        theme_mode NVARCHAR(20) DEFAULT 'light',
        custom_emotions NVARCHAR(MAX) DEFAULT '[]', -- JSON array of strings
        reminder_settings NVARCHAR(MAX) DEFAULT '{}', -- JSON object matching Flutter model
        updated_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
    );
END
GO

-- =============================================
-- View: EmotionHistory
-- Complete emotion entries with context and notes
-- =============================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'EmotionHistory')
    DROP VIEW EmotionHistory;
GO

CREATE VIEW EmotionHistory AS
SELECT 
    e.id as emotion_id,
    e.user_id,
    e.emotion_type,
    e.intensity,
    e.timestamp,
    c.location,
    c.activity,
    c.company,
    n.note_text,
    u.name as user_name,
    u.email as user_email
FROM Emotions e
LEFT JOIN Contexts c ON e.id = c.emotion_id
LEFT JOIN Notes n ON e.id = n.emotion_id
INNER JOIN Users u ON e.user_id = u.id;
GO

-- =============================================
-- Stored Procedure: GetUserEmotionStats
-- Get emotion statistics for a user
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetUserEmotionStats')
    DROP PROCEDURE GetUserEmotionStats;
GO

CREATE PROCEDURE GetUserEmotionStats
    @user_id INT,
    @days INT = 7
 AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @start_date DATETIME2 = DATEADD(DAY, -@days, GETDATE());
    
    SELECT 
        emotion_type,
        COUNT(*) as count,
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) as percentage,
        AVG(intensity) as avg_intensity
    FROM Emotions
    WHERE user_id = @user_id 
        AND timestamp >= @start_date
    GROUP BY emotion_type
    ORDER BY count DESC;
END
GO

-- =============================================
-- Stored Procedure: GetUserEmotionsByDateRange
-- Get emotions for a specific date range
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetUserEmotionsByDateRange')
    DROP PROCEDURE GetUserEmotionsByDateRange;
GO

CREATE PROCEDURE GetUserEmotionsByDateRange
    @user_id INT,
    @start_date DATETIME2,
    @end_date DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT *
    FROM EmotionHistory
    WHERE user_id = @user_id
        AND timestamp >= @start_date
        AND timestamp <= @end_date
    ORDER BY timestamp DESC;
END
GO

-- =============================================
-- Insert Sample Data (for testing)
-- =============================================
-- Note: Password is 'test123' hashed with bcrypt
IF NOT EXISTS (SELECT * FROM Users WHERE email = 'test@example.com')
BEGIN
    INSERT INTO Users (email, password_hash, name)
    VALUES ('test@example.com', '$2b$10$YourHashedPasswordHere', 'Test User');
END
GO

PRINT 'Database schema updated successfully!';
PRINT 'Tables: Users, Emotions, Contexts, Notes, UserSettings';
PRINT 'Views: EmotionHistory';
PRINT 'Stored Procedures: GetUserEmotionStats, GetUserEmotionsByDateRange';
GO
