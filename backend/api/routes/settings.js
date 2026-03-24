const express = require('express');
const { getDB } = require('../config/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Get user settings
router.get('/', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const db = getDB();

        const result = await db.request()
            .input('userId', userId)
            .query('SELECT * FROM UserSettings WHERE user_id = @userId');

        if (result.recordset.length === 0) {
            // Return default settings if not exists
            return res.json({
                success: true,
                data: {
                    theme_mode: 'light',
                    custom_emotions: [],
                    reminder_settings: {}
                }
            });
        }

        const settings = result.recordset[0];
        // Parse JSON fields
        try {
            settings.custom_emotions = JSON.parse(settings.custom_emotions || '[]');
            settings.reminder_settings = JSON.parse(settings.reminder_settings || '{}');
        } catch (e) {
            console.error('Error parsing settings JSON:', e);
        }

        res.json({
            success: true,
            data: settings
        });
    } catch (error) {
        console.error('Get settings error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching settings',
        });
    }
});

// Update user settings
router.put('/', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const { theme_mode, custom_emotions, reminder_settings } = req.body;
        const db = getDB();

        const customEmotionsStr = JSON.stringify(custom_emotions || []);
        const reminderSettingsStr = JSON.stringify(reminder_settings || {});

        await db.request()
            .input('userId', userId)
            .input('theme_mode', theme_mode || 'light')
            .input('custom_emotions', customEmotionsStr)
            .input('reminder_settings', reminderSettingsStr)
            .query(`
                IF EXISTS (SELECT 1 FROM UserSettings WHERE user_id = @userId)
                BEGIN
                    UPDATE UserSettings 
                    SET theme_mode = @theme_mode,
                        custom_emotions = @custom_emotions,
                        reminder_settings = @reminder_settings,
                        updated_at = GETDATE()
                    WHERE user_id = @userId
                END
                ELSE
                BEGIN
                    INSERT INTO UserSettings (user_id, theme_mode, custom_emotions, reminder_settings)
                    VALUES (@userId, @theme_mode, @custom_emotions, @reminder_settings)
                END
            `);

        res.json({
            success: true,
            message: 'Settings updated successfully',
        });
    } catch (error) {
        console.error('Update settings error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error updating settings',
        });
    }
});

module.exports = router;
