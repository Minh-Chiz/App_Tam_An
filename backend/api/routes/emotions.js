const express = require('express');
const { getDB } = require('../config/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Create emotion
router.post('/', authMiddleware, async (req, res) => {
    try {
        const { emotion_type, intensity, location, activity, company, note_text } = req.body;
        const userId = req.user.id;

        if (!emotion_type) {
            return res.status(400).json({
                success: false,
                message: 'Emotion type is required',
            });
        }

        const db = getDB();
        let emotion;

        const request = db.request()
            .input('userId', userId)
            .input('emotion_type', emotion_type)
            .input('intensity', intensity || 5)
            .input('location', location || null)
            .input('activity', activity || null)
            .input('company', company || null)
            .input('note_text', note_text || null);

        const result = await request.query(`
            DECLARE @InsertedEmotion TABLE (id INT);
            
            INSERT INTO Emotions (user_id, emotion_type, intensity) 
            OUTPUT INSERTED.id INTO @InsertedEmotion
            VALUES (@userId, @emotion_type, @intensity);

            DECLARE @EmotionId INT = (SELECT TOP 1 id FROM @InsertedEmotion);

            IF (@location IS NOT NULL OR @activity IS NOT NULL OR @company IS NOT NULL)
            BEGIN
                INSERT INTO Contexts (emotion_id, location, activity, company)
                VALUES (@EmotionId, @location, @activity, @company);
            END

            IF (@note_text IS NOT NULL)
            BEGIN
                INSERT INTO Notes (emotion_id, note_text)
                VALUES (@EmotionId, @note_text);
            END

            SELECT e.id, e.user_id, e.emotion_type, e.intensity, e.timestamp,
                   c.location, c.activity, c.company, n.note_text
            FROM Emotions e
            LEFT JOIN Contexts c ON e.id = c.emotion_id
            LEFT JOIN Notes n ON e.id = n.emotion_id
            WHERE e.id = @EmotionId;
        `);

        emotion = result.recordset[0];

        res.status(201).json({
            success: true,
            message: 'Emotion entry created successfully',
            data: emotion,
        });
    } catch (error) {
        console.error('Create emotion error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error creating emotion entry',
        });
    }
});

// Get emotions
router.get('/', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const { limit = 50, offset = 0 } = req.query;

        const db = getDB();
        let emotions = [];

        const result = await db.request()
            .input('userId', userId)
            .input('limit', parseInt(limit))
            .input('offset', parseInt(offset))
            .query(`
              SELECT e.id as emotion_id, e.user_id, e.emotion_type, e.intensity, e.timestamp,
                     c.location, c.activity, c.company, n.note_text,
                     u.name as user_name, u.email as user_email
              FROM Emotions e
              LEFT JOIN Contexts c ON e.id = c.emotion_id
              LEFT JOIN Notes n ON e.id = n.emotion_id
              INNER JOIN Users u ON e.user_id = u.id
              WHERE e.user_id = @userId
              ORDER BY e.timestamp DESC
              OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
            `);
        emotions = result.recordset;

        res.json({
            success: true,
            data: { emotions, count: emotions.length },
        });
    } catch (error) {
        console.error('Get emotions error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching emotions',
        });
    }
});

// Get stats
router.get('/stats/summary', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const { days = 7 } = req.query;

        const db = getDB();
        let stats = [];

        const result = await db.request()
            .input('userId', userId)
            .input('days', parseInt(days))
            .query(`
              SELECT emotion_type,
                     COUNT(*) as count,
                     ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage,
                     AVG(CAST(intensity AS FLOAT)) as avg_intensity
              FROM Emotions
              WHERE user_id = @userId 
                AND timestamp >= DATEADD(day, -@days, GETDATE())
              GROUP BY emotion_type
              ORDER BY count DESC
            `);
        stats = result.recordset;

        res.json({
            success: true,
            data: { stats, period_days: parseInt(days) },
        });
    } catch (error) {
        console.error('Get stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching statistics',
        });
    }
});

// Get dashboard stats
router.get('/stats/dashboard', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const { days = 30 } = req.query;

        const db = getDB();

        let totalEntries = 0;
        let emotionDistribution = [];
        let weeklyEmotions = [];

        const totalResult = await db.request().input('userId', userId).input('days', parseInt(days))
            .query(`SELECT COUNT(*) as total FROM Emotions WHERE user_id = @userId AND timestamp >= DATEADD(day, -@days, GETDATE())`);
        totalEntries = totalResult.recordset[0].total;

        const distributionResult = await db.request().input('userId', userId).input('days', parseInt(days))
            .query(`
              SELECT emotion_type, COUNT(*) as count, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
              FROM Emotions WHERE user_id = @userId AND timestamp >= DATEADD(day, -@days, GETDATE())
              GROUP BY emotion_type ORDER BY count DESC
            `);
        emotionDistribution = distributionResult.recordset;

        const weeklyResult = await db.request().input('userId', userId)
            .query(`
              WITH DailyEmotions AS (
                SELECT CAST(timestamp AS DATE) as date, emotion_type,
                  CASE DATEPART(dw, timestamp) WHEN 1 THEN 'CN' WHEN 2 THEN 'T2' WHEN 3 THEN 'T3' WHEN 4 THEN 'T4' WHEN 5 THEN 'T5' WHEN 6 THEN 'T6' WHEN 7 THEN 'T7' END as day_of_week,
                  ROW_NUMBER() OVER(PARTITION BY CAST(timestamp AS DATE) ORDER BY timestamp DESC) as rn
                FROM Emotions WHERE user_id = @userId AND timestamp >= DATEADD(day, -7, GETDATE())
              )
              SELECT date, emotion_type, day_of_week FROM DailyEmotions WHERE rn = 1 ORDER BY date DESC
            `);
        // Format dates simply as 'YYYY-MM-DD'
        weeklyEmotions = weeklyResult.recordset.map(row => {
            const d = new Date(row.date);
            d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
            return {
                date: d.toISOString().split('T')[0],
                emotion_type: row.emotion_type,
                day_of_week: row.day_of_week
            };
        });

        // Generate insights
        let insightMessage = 'Bắt đầu ghi nhật ký để nhận phân tích!';
        let mostCommonEmotion = 'Bình thường';

        if (emotionDistribution.length > 0) {
            mostCommonEmotion = emotionDistribution[0].emotion_type;
            const topPercentage = emotionDistribution[0].percentage;

            if (mostCommonEmotion === 'Vui' && topPercentage > 50) {
                insightMessage = `Tuyệt vời! Bạn có ${topPercentage}% thời gian cảm thấy vui vẻ. Hãy tiếp tục duy trì!`;
            } else if (mostCommonEmotion === 'Căng thẳng' && topPercentage > 40) {
                insightMessage = `Bạn đang có ${topPercentage}% thời gian căng thẳng. Hãy dành thời gian thư giãn nhé!`;
            } else if (mostCommonEmotion === 'Buồn' && topPercentage > 30) {
                insightMessage = `Có ${topPercentage}% thời gian bạn cảm thấy buồn. Hãy chia sẻ với người thân!`;
            } else {
                insightMessage = `Cảm xúc chủ đạo của bạn là "${mostCommonEmotion}". Hãy tiếp tục theo dõi!`;
            }
        }

        res.json({
            success: true,
            data: {
                total_entries: totalEntries,
                emotion_distribution: emotionDistribution,
                weekly_emotions: weeklyEmotions,
                insights: {
                    most_common_emotion: mostCommonEmotion,
                    message: insightMessage,
                },
            },
        });
    } catch (error) {
        console.error('Get dashboard stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching dashboard statistics',
        });
    }
});

// Get emotions by specific date
router.get('/date/:date', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const { date } = req.params;

        const db = getDB();
        let emotions = [];

        const result = await db.request()
            .input('userId', userId)
            .input('date', date)
            .query(`
              SELECT e.id, e.user_id, e.emotion_type, e.intensity, e.timestamp,
                     c.location, c.activity, c.company, n.note_text
              FROM Emotions e
              LEFT JOIN Contexts c ON e.id = c.emotion_id
              LEFT JOIN Notes n ON e.id = n.emotion_id
              WHERE e.user_id = @userId 
                AND CAST(e.timestamp AS DATE) = CAST(@date AS DATE)
              ORDER BY e.timestamp ASC
            `);
        emotions = result.recordset;

        res.json({
            success: true,
            data: {
                date,
                emotions,
                total_count: emotions.length,
            },
        });
    } catch (error) {
        console.error('Get emotions by date error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching emotions by date',
        });
    }
});

// Get calendar dates with emotions
router.get('/calendar/:year/:month', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const { year, month } = req.params;

        const db = getDB();
        let dates = [];

        const result = await db.request()
            .input('userId', userId)
            .input('year', parseInt(year))
            .input('month', parseInt(month))
            .query(`
              SELECT DISTINCT CAST(timestamp AS DATE) as date
              FROM Emotions
              WHERE user_id = @userId
                AND YEAR(timestamp) = @year
                AND MONTH(timestamp) = @month
              ORDER BY date
            `);
        // Format to 'YYYY-MM-DD' since mssql DATE objects might serialize differently
        dates = result.recordset.map(row => {
           const d = new Date(row.date);
           d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
           return d.toISOString().split('T')[0];
        });

        res.json({
            success: true,
            data: {
                year: parseInt(year),
                month: parseInt(month),
                dates_with_emotions: dates,
            },
        });
    } catch (error) {
        console.error('Get calendar dates error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching calendar dates',
        });
    }
});

// Get monthly insights (comprehensive: emotions + notes + context)
router.get('/insights/monthly', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const { year, month } = req.query;

        const db = getDB();

        let emotionBreakdown = {};
        let intensityMap = {};
        let totalEntries = 0;
        let mostCommonEmotion = 'Bình thường';
        let allNotes = [];
        let notesByEmotion = {};
        let topContexts = [];
        let weeklyTrendResult = [];

        const request = db.request()
            .input('userId', userId)
            .input('year', parseInt(year))
            .input('month', parseInt(month));

        // 1. Get emotion breakdown with average intensity
        const breakdownResult = await request.query(`
            SELECT emotion_type, COUNT(*) as count, ROUND(AVG(CAST(intensity AS FLOAT)), 2) as avg_intensity
            FROM Emotions
            WHERE user_id = @userId
              AND YEAR(timestamp) = @year
              AND MONTH(timestamp) = @month
            GROUP BY emotion_type
            ORDER BY count DESC
        `);
        breakdownResult.recordset.forEach(row => {
            emotionBreakdown[row.emotion_type] = row.count;
            intensityMap[row.emotion_type] = {
                average: row.avg_intensity,
                count: row.count
            };
            totalEntries += row.count;
        });
        if (breakdownResult.recordset.length > 0) {
            mostCommonEmotion = breakdownResult.recordset[0].emotion_type;
        }

        // 2. Get all notes for the month
        const notesResult = await request.query(`
            SELECT e.emotion_type, n.note_text
            FROM Emotions e
            INNER JOIN Notes n ON e.id = n.emotion_id
            WHERE e.user_id = @userId
              AND YEAR(e.timestamp) = @year
              AND MONTH(e.timestamp) = @month
              AND n.note_text IS NOT NULL
              AND n.note_text != ''
            ORDER BY e.timestamp DESC
        `);
        notesResult.recordset.forEach(row => {
            allNotes.push(row.note_text);
            if (!notesByEmotion[row.emotion_type]) {
                notesByEmotion[row.emotion_type] = [];
            }
            notesByEmotion[row.emotion_type].push(row.note_text);
        });

        // 3. Get top activities and locations
        const contextResult = await request.query(`
            SELECT TOP 5 CAST(c.activity AS NVARCHAR(MAX)) as activity, CAST(c.location AS NVARCHAR(MAX)) as location, COUNT(*) as count
            FROM Emotions e
            INNER JOIN Contexts c ON e.id = c.emotion_id
            WHERE e.user_id = @userId
              AND YEAR(e.timestamp) = @year
              AND MONTH(e.timestamp) = @month
              AND (NULLIF(CAST(c.activity AS NVARCHAR(MAX)), '') IS NOT NULL 
                   OR NULLIF(CAST(c.location AS NVARCHAR(MAX)), '') IS NOT NULL)
            GROUP BY CAST(c.activity AS NVARCHAR(MAX)), CAST(c.location AS NVARCHAR(MAX))
            ORDER BY count DESC
        `);
        contextResult.recordset.forEach(row => {
           const parts = [];
           if (row.activity) parts.push(row.activity);
           if (row.location) parts.push(row.location);
           if (parts.length > 0) {
               topContexts.push({ context: parts.join(' tại '), count: row.count });
           }
        });

        // 4. Analyze emotion trend
        const wtResult = await request.query(`
            SELECT 
              CASE 
                WHEN DAY(timestamp) <= 7 THEN 1
                WHEN DAY(timestamp) <= 14 THEN 2
                WHEN DAY(timestamp) <= 21 THEN 3
                ELSE 4
              END as week_num,
              emotion_type,
              COUNT(*) as count
            FROM Emotions
            WHERE user_id = @userId
              AND YEAR(timestamp) = @year
              AND MONTH(timestamp) = @month
            GROUP BY 
              CASE 
                WHEN DAY(timestamp) <= 7 THEN 1
                WHEN DAY(timestamp) <= 14 THEN 2
                WHEN DAY(timestamp) <= 21 THEN 3
                ELSE 4
              END, emotion_type
            ORDER BY week_num
        `);
        weeklyTrendResult = wtResult.recordset;

        // Calculate positive ratio per week to detect trend direction
        const weeklyPositive = {};
        const weeklyTotal = {};
        weeklyTrendResult.forEach(row => {
            const week = row.week_num;
            const emotion = row.emotion_type;
            const count = row.count;
            weeklyTotal[week] = (weeklyTotal[week] || 0) + count;
            if (emotion === 'Vui' || emotion === 'Vui vẻ' || emotion === 'Bình thường') {
                weeklyPositive[week] = (weeklyPositive[week] || 0) + count;
            }
        });
        
        const weeks = Object.keys(weeklyTotal).sort();
        let trend = 'stable';
        if (weeks.length >= 2) {
            const firstWeekRatio = (weeklyPositive[weeks[0]] || 0) / (weeklyTotal[weeks[0]] || 1);
            const lastWeekRatio = (weeklyPositive[weeks[weeks.length - 1]] || 0) / (weeklyTotal[weeks[weeks.length - 1]] || 1);
            if (lastWeekRatio - firstWeekRatio > 0.15) {
                trend = 'improving';
            } else if (firstWeekRatio - lastWeekRatio > 0.15) {
                trend = 'declining';
            }
        }

        // 5. Generate comprehensive suggestions
        const suggestions = [];
        const positiveEmotions = ['Vui', 'Vui vẻ'];
        const negativeEmotions = ['Buồn', 'Căng thẳng', 'Lo âu', 'Giận dữ'];

        const positiveCount = positiveEmotions.reduce((sum, e) => sum + (emotionBreakdown[e] || 0), 0);
        const negativeCount = negativeEmotions.reduce((sum, e) => sum + (emotionBreakdown[e] || 0), 0);
        const neutralCount = (emotionBreakdown['Bình thường'] || 0);
        const positiveRatio = totalEntries > 0 ? positiveCount / totalEntries : 0;
        const negativeRatio = totalEntries > 0 ? negativeCount / totalEntries : 0;

        // Overall assessment
        if (totalEntries === 0) {
            suggestions.push('📝 Chưa có dữ liệu trong tháng này. Hãy bắt đầu ghi nhật ký cảm xúc!');
        } else {
            // a) Emotion-based analysis
            if (positiveRatio > 0.6) {
                suggestions.push(`🎉 Tháng rất tích cực! ${Math.round(positiveRatio * 100)}% cảm xúc vui vẻ (${positiveCount}/${totalEntries} lần)`);
            } else if (positiveRatio > 0.4) {
                suggestions.push(`⚖️ Cảm xúc khá cân bằng: ${positiveCount} tích cực, ${negativeCount} tiêu cực, ${neutralCount} bình thường`);
            } else if (negativeRatio > 0.5) {
                suggestions.push(`💙 Tháng có nhiều thử thách: ${Math.round(negativeRatio * 100)}% cảm xúc tiêu cực. Hãy dành thời gian cho bản thân`);
            } else {
                suggestions.push(`📊 Tổng hợp: ${positiveCount} tích cực, ${neutralCount} bình thường, ${negativeCount} tiêu cực`);
            }

            // b) Intensity analysis
            const overallAvgIntensity = Object.values(intensityMap).length > 0
                ? Object.entries(intensityMap).reduce((sum, [, v]) => sum + v, 0) / Object.values(intensityMap).length
                : 5;

            if (overallAvgIntensity >= 7) {
                suggestions.push('🔥 Cường độ cảm xúc cao trong tháng — bạn đang trải qua nhiều cảm xúc mạnh mẽ');
            } else if (overallAvgIntensity <= 3) {
                suggestions.push('😌 Cường độ cảm xúc nhẹ — tháng khá bình yên');
            }

            // c) Note-based analysis  
            if (allNotes.length > 0) {
                suggestions.push(`📖 Bạn đã viết ${allNotes.length} ghi chú trong tháng`);

                // Find recurring themes/keywords in notes
                const allText = allNotes.join(' ').toLowerCase();
                const themes = [];

                const themeKeywords = {
                    'công việc/học tập': ['công việc', 'làm việc', 'học', 'thi', 'dự án', 'deadline', 'họp', 'sếp', 'đồng nghiệp', 'lớp', 'trường'],
                    'gia đình': ['gia đình', 'bố', 'mẹ', 'ba', 'má', 'anh', 'chị', 'em', 'con', 'vợ', 'chồng', 'nhà'],
                    'bạn bè': ['bạn bè', 'bạn', 'gặp nhau', 'cafe', 'đi chơi', 'nhóm'],
                    'sức khỏe': ['sức khỏe', 'mệt', 'ốm', 'bệnh', 'ngủ', 'tập thể dục', 'thể thao', 'đau'],
                    'tài chính': ['tiền', 'lương', 'chi tiêu', 'tiết kiệm', 'mua', 'nợ'],
                    'tình cảm': ['yêu', 'nhớ', 'thương', 'cô đơn', 'hẹn hò', 'người yêu'],
                };

                for (const [theme, keywords] of Object.entries(themeKeywords)) {
                    const matchCount = keywords.filter(kw => allText.includes(kw)).length;
                    if (matchCount >= 2) {
                        themes.push(theme);
                    }
                }

                if (themes.length > 0) {
                    suggestions.push(`🔍 Chủ đề nổi bật trong ghi chú: ${themes.join(', ')}`);
                }

                // Notes per emotion category
                const noteEmotionSummary = [];
                for (const [emotion, notes] of Object.entries(notesByEmotion)) {
                    if (notes.length >= 2) {
                        noteEmotionSummary.push(`${emotion} (${notes.length} ghi chú)`);
                    }
                }
                if (noteEmotionSummary.length > 0) {
                    suggestions.push(`✍️ Ghi chú nhiều nhất khi: ${noteEmotionSummary.join(', ')}`);
                }
            } else {
                suggestions.push('💡 Hãy viết ghi chú kèm cảm xúc để có đánh giá sâu hơn');
            }

            // d) Context-based suggestions
            if (topContexts.length > 0) {
                const contextStr = topContexts.slice(0, 3).map(c => c.context).join(', ');
                suggestions.push(`📍 Hoạt động/địa điểm thường gặp: ${contextStr}`);
            }

            // e) Trend-based suggestion
            if (trend === 'improving') {
                suggestions.push('📈 Xu hướng tích cực: cảm xúc cuối tháng tốt hơn đầu tháng!');
            } else if (trend === 'declining') {
                suggestions.push('📉 Cảm xúc giảm dần về cuối tháng. Hãy tìm cách thư giãn và nghỉ ngơi');
            }
        }

        res.json({
            success: true,
            data: {
                month: parseInt(month),
                year: parseInt(year),
                total_entries: totalEntries,
                most_common_emotion: mostCommonEmotion,
                trend,
                suggestions,
                emotion_breakdown: emotionBreakdown,
                average_intensity: intensityMap,
                notes_count: allNotes.length,
                top_contexts: topContexts,
            },
        });
    } catch (error) {
        console.error('Get monthly insights error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching monthly insights',
        });
    }
});

// Full analysis (all-time) - comprehensive emotion analysis
router.get('/stats/full-analysis', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const db = getDB();

        let totalEntries = 0;
        let firstEntry = null;
        let lastEntry = null;
        let emotionDistribution = [];
        let averageIntensity = {};
        let recentTotal = 0, recentPositive = 0;
        let prevTotal = 0, prevPositive = 0;
        let topContexts = [];
        let allNotes = [];

        const request = db.request().input('userId', userId);

        // 1. Total entries & date range
        const totalResult = await request.query(`SELECT COUNT(*) as _count, MIN(timestamp) as _min, MAX(timestamp) as _max FROM Emotions WHERE user_id = @userId`);
        totalEntries = totalResult.recordset[0]._count;
        firstEntry = totalResult.recordset[0]._min;
        lastEntry = totalResult.recordset[0]._max;

        if (totalEntries === 0) {
            return res.json({
                success: true,
                data: {
                    total_entries: 0,
                    emotional_score: 0,
                    emotion_distribution: [],
                    average_intensity: {},
                    trend: 'stable',
                    suggestions: ['📝 Chưa có dữ liệu. Hãy bắt đầu ghi nhật ký cảm xúc!'],
                    top_contexts: [],
                    notes_count: 0,
                    themes: [],
                    first_entry: null,
                    last_entry: null,
                    monthly_data: {},
                },
            });
        }

        // 2. Emotion distribution
        const distResult = await request.query(`
            SELECT emotion_type, COUNT(*) as count,
                   ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
            FROM Emotions WHERE user_id = @userId
            GROUP BY emotion_type ORDER BY count DESC
        `);
        emotionDistribution = distResult.recordset;

        // 3. Average intensity per emotion with counts
        const intensityResult = await request.query(`
            SELECT emotion_type, 
                   ROUND(AVG(CAST(intensity AS FLOAT)), 2) as avg_intensity,
                   COUNT(*) as entry_count
            FROM Emotions WHERE user_id = @userId
            GROUP BY emotion_type
        `);
        
        averageIntensity = {};
        intensityResult.recordset.forEach(row => {
            averageIntensity[row.emotion_type] = {
                average: row.avg_intensity,
                count: row.entry_count
            };
        });

        // 4. Trend
        const positiveEmotions = ['Vui', 'Vui vẻ'];
        const recentResult = await request.query(`
            SELECT emotion_type, COUNT(*) as count
            FROM Emotions WHERE user_id = @userId
              AND timestamp >= DATEADD(day, -30, GETDATE())
            GROUP BY emotion_type
        `);
        recentResult.recordset.forEach(row => {
            recentTotal += row.count;
            if (positiveEmotions.includes(row.emotion_type)) recentPositive += row.count;
        });

        const previousResult = await request.query(`
            SELECT emotion_type, COUNT(*) as count
            FROM Emotions WHERE user_id = @userId
              AND timestamp >= DATEADD(day, -60, GETDATE())
              AND timestamp < DATEADD(day, -30, GETDATE())
            GROUP BY emotion_type
        `);
        previousResult.recordset.forEach(row => {
            prevTotal += row.count;
            if (positiveEmotions.includes(row.emotion_type)) prevPositive += row.count;
        });

        // 5. Top contexts
        const contextResult = await request.query(`
            SELECT TOP 5 CAST(c.activity AS NVARCHAR(MAX)) as activity, CAST(c.location AS NVARCHAR(MAX)) as location, COUNT(*) as count
            FROM Emotions e
            INNER JOIN Contexts c ON e.id = c.emotion_id
            WHERE e.user_id = @userId
              AND (NULLIF(CAST(c.activity AS NVARCHAR(MAX)), '') IS NOT NULL 
                   OR NULLIF(CAST(c.location AS NVARCHAR(MAX)), '') IS NOT NULL)
            GROUP BY CAST(c.activity AS NVARCHAR(MAX)), CAST(c.location AS NVARCHAR(MAX))
            ORDER BY count DESC
        `);
        contextResult.recordset.forEach(row => {
            const parts = [];
            if (row.activity) parts.push(row.activity);
            if (row.location) parts.push(row.location);
            if (parts.length > 0) {
                topContexts.push({ context: parts.join(' tại '), count: row.count });
            }
        });

        // 6. Notes
        const notesResult = await request.query(`
            SELECT n.note_text FROM Emotions e
            INNER JOIN Notes n ON e.id = n.emotion_id
            WHERE e.user_id = @userId AND n.note_text IS NOT NULL AND n.note_text != ''
        `);
        notesResult.recordset.forEach(row => allNotes.push(row.note_text));

        const recentRatio = recentTotal > 0 ? recentPositive / recentTotal : 0;
        const prevRatio = prevTotal > 0 ? prevPositive / prevTotal : 0;
        let trend = 'stable';
        if (prevTotal > 0) {
            if (recentRatio - prevRatio > 0.15) trend = 'improving';
            else if (prevRatio - recentRatio > 0.15) trend = 'declining';
        }

        const themes = [];
        if (allNotes.length > 0) {
            const allText = allNotes.join(' ').toLowerCase();
            const themeKeywords = {
                'Công việc/Học tập': ['công việc', 'làm việc', 'học', 'thi', 'dự án', 'deadline', 'họp', 'sếp'],
                'Gia đình': ['gia đình', 'bố', 'mẹ', 'ba', 'má', 'anh', 'chị', 'em', 'con', 'nhà'],
                'Bạn bè': ['bạn bè', 'bạn', 'gặp nhau', 'cafe', 'đi chơi', 'nhóm'],
                'Sức khỏe': ['sức khỏe', 'mệt', 'ốm', 'bệnh', 'ngủ', 'tập thể dục', 'đau'],
                'Tài chính': ['tiền', 'lương', 'chi tiêu', 'tiết kiệm', 'mua', 'nợ'],
                'Tình cảm': ['yêu', 'nhớ', 'thương', 'c cô đơn', 'hẹn hò', 'người yêu'],
            };
            for (const [theme, keywords] of Object.entries(themeKeywords)) {
                const matchCount = keywords.filter(kw => allText.includes(kw)).length;
                if (matchCount >= 2) themes.push(theme);
            }
        }

        // 7. Emotional score (0-100)
        let positiveCount = 0, neutralCount = 0, negativeCount = 0;
        emotionDistribution.forEach(d => {
            if (positiveEmotions.includes(d.emotion_type)) positiveCount += d.count;
            else if (d.emotion_type === 'Bình thường') neutralCount += d.count;
            else negativeCount += d.count;
        });
        const emotionalScore = Math.round(
            (positiveCount * 100 + neutralCount * 60 + negativeCount * 20) / totalEntries
        );

        // 8. Monthly trend data (last 6 months)
        const monthlyResult = await request.query(`
            SELECT FORMAT(timestamp, 'yyyy-MM') as month,
                   emotion_type, COUNT(*) as count
            FROM Emotions WHERE user_id = @userId
              AND timestamp >= DATEADD(month, -6, GETDATE())
            GROUP BY FORMAT(timestamp, 'yyyy-MM'), emotion_type
            ORDER BY FORMAT(timestamp, 'yyyy-MM')
        `);

        const monthlyData = {};
        if (monthlyResult.recordset.length > 0) {
            monthlyResult.recordset.forEach(row => {
                if (!monthlyData[row.month]) monthlyData[row.month] = {};
                monthlyData[row.month][row.emotion_type] = row.count;
            });
        }

        // 9. Generate suggestions
        const suggestions = [];
        const positiveRatio = positiveCount / totalEntries;
        const negativeRatio = negativeCount / totalEntries;

        if (positiveRatio > 0.6) {
            suggestions.push(`🎉 Tuyệt vời! ${Math.round(positiveRatio * 100)}% cảm xúc của bạn là tích cực (${positiveCount}/${totalEntries} lần ghi nhận)`);
        } else if (positiveRatio > 0.4) {
            suggestions.push(`⚖️ Cảm xúc khá cân bằng: ${positiveCount} tích cực, ${negativeCount} tiêu cực, ${neutralCount} bình thường`);
        } else if (negativeRatio > 0.5) {
            suggestions.push(`💙 Bạn đã trải qua ${Math.round(negativeRatio * 100)}% cảm xúc tiêu cực. Hãy dành thời gian cho bản thân`);
        } else {
            suggestions.push(`📊 Tổng hợp: ${positiveCount} tích cực, ${neutralCount} bình thường, ${negativeCount} tiêu cực`);
        }

        if (trend === 'improving') {
            suggestions.push('📈 Xu hướng tích cực: 30 ngày gần đây tốt hơn trước!');
        } else if (trend === 'declining') {
            suggestions.push('📉 Cảm xúc có xu hướng giảm gần đây. Hãy tìm cách thư giãn');
        }

        if (allNotes.length > 0) {
            suggestions.push(`📖 Bạn đã viết ${allNotes.length} ghi chú kèm cảm xúc`);
        } else {
            suggestions.push('💡 Hãy viết ghi chú kèm cảm xúc để có phân tích sâu hơn');
        }

        if (themes.length > 0) {
            suggestions.push(`🔍 Chủ đề nổi bật: ${themes.join(', ')}`);
        }

        if (topContexts.length > 0) {
            const ctx = topContexts.slice(0, 3).map(c => c.context).join(', ');
            suggestions.push(`📍 Hoạt động thường gặp: ${ctx}`);
        }

        if (emotionDistribution.length > 0) {
            const dominant = emotionDistribution[0].emotion_type;
            if (dominant === 'Căng thẳng' || dominant === 'Lo âu') {
                suggestions.push('🧘 Gợi ý: Thử thiền định, hít thở sâu hoặc đi dạo để giảm căng thẳng');
            } else if (dominant === 'Buồn') {
                suggestions.push('💕 Gợi ý: Chia sẻ với người thân hoặc viết nhật ký để giải tỏa cảm xúc');
            } else if (dominant === 'Giận dữ') {
                suggestions.push('🌿 Gợi ý: Tập thể dục hoặc nghe nhạc thư giãn khi cảm thấy tức giận');
            } else if (positiveEmotions.includes(dominant)) {
                suggestions.push('✨ Tiếp tục duy trì thói quen tích cực và ghi nhận những khoảnh khắc vui vẻ!');
            }
        }

        res.json({
            success: true,
            data: {
                total_entries: totalEntries,
                emotional_score: emotionalScore,
                emotion_distribution: emotionDistribution,
                average_intensity: averageIntensity,
                trend,
                suggestions,
                top_contexts: topContexts,
                notes_count: allNotes.length,
                themes,
                first_entry: firstEntry,
                last_entry: lastEntry,
                monthly_data: monthlyData,
            },
        });
    } catch (error) {
        console.error('Full analysis error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching full analysis',
        });
    }
});

// Get streak, points, and achievements
router.get('/stats/streak', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const db = getDB();

        // 1. Get all distinct dates with entries (sorted descending)
        const datesResult = await db.request()
            .input('userId', userId)
            .query(`
                SELECT DISTINCT CAST(timestamp AS DATE) as date
                FROM Emotions
                WHERE user_id = @userId
                ORDER BY date DESC
            `);

        const dates = datesResult.recordset.map(row => {
            const d = new Date(row.date);
            d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
            return d.toISOString().split('T')[0];
        });

        // 2. Calculate current streak
        let currentStreak = 0;
        if (dates.length > 0) {
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const yesterday = new Date(today);
            yesterday.setDate(yesterday.getDate() - 1);

            const todayStr = today.toISOString().split('T')[0];
            const yesterdayStr = yesterday.toISOString().split('T')[0];

            // Streak must start from today or yesterday
            if (dates[0] === todayStr || dates[0] === yesterdayStr) {
                currentStreak = 1;
                for (let i = 1; i < dates.length; i++) {
                    const prevDate = new Date(dates[i - 1]);
                    const currDate = new Date(dates[i]);
                    const diffDays = (prevDate - currDate) / (1000 * 60 * 60 * 24);
                    if (diffDays === 1) {
                        currentStreak++;
                    } else {
                        break;
                    }
                }
            }
        }

        // 3. Calculate longest streak
        let longestStreak = 0;
        if (dates.length > 0) {
            const sortedAsc = [...dates].reverse();
            let tempStreak = 1;
            for (let i = 1; i < sortedAsc.length; i++) {
                const prevDate = new Date(sortedAsc[i - 1]);
                const currDate = new Date(sortedAsc[i]);
                const diffDays = (currDate - prevDate) / (1000 * 60 * 60 * 24);
                if (diffDays === 1) {
                    tempStreak++;
                } else {
                    longestStreak = Math.max(longestStreak, tempStreak);
                    tempStreak = 1;
                }
            }
            longestStreak = Math.max(longestStreak, tempStreak);
        }

        // 4. Get total entries & notes count
        const totalResult = await db.request()
            .input('userId', userId)
            .query(`SELECT COUNT(*) as count FROM Emotions WHERE user_id = @userId`);
        const totalEntries = totalResult.recordset[0].count;

        const notesResult = await db.request()
            .input('userId', userId)
            .query(`
                SELECT COUNT(*) as count FROM Notes n
                INNER JOIN Emotions e ON n.emotion_id = e.id
                WHERE e.user_id = @userId AND n.note_text IS NOT NULL AND n.note_text != ''
            `);
        const totalNotes = notesResult.recordset[0].count;

        // 5. Get distinct emotion types count
        const distinctResult = await db.request()
            .input('userId', userId)
            .query(`SELECT COUNT(DISTINCT emotion_type) as count FROM Emotions WHERE user_id = @userId`);
        const distinctEmotions = distinctResult.recordset[0].count;

        const totalDays = dates.length;

        // 6. Calculate points
        // 10 points per entry, 5 bonus per note, streak bonuses
        let points = totalEntries * 10 + totalNotes * 5;
        if (currentStreak >= 7) points += 50;
        if (currentStreak >= 30) points += 200;
        if (currentStreak >= 100) points += 500;
        points += currentStreak * 2; // 2 extra points per streak day

        // 7. Achievements
        const achievements = [
            {
                id: 'first_entry',
                title: 'Khởi đầu',
                description: 'Ghi nhận cảm xúc lần đầu tiên',
                icon: '🌱',
                required: 1,
                current: totalEntries,
                unlocked: totalEntries >= 1,
            },
            {
                id: 'streak_3',
                title: 'Ba ngày liên tục',
                description: 'Duy trì chuỗi 3 ngày liên tiếp',
                icon: '🔥',
                required: 3,
                current: Math.max(currentStreak, longestStreak),
                unlocked: longestStreak >= 3,
            },
            {
                id: 'streak_7',
                title: 'Một tuần kiên trì',
                description: 'Duy trì chuỗi 7 ngày liên tiếp',
                icon: '⭐',
                required: 7,
                current: Math.max(currentStreak, longestStreak),
                unlocked: longestStreak >= 7,
            },
            {
                id: 'streak_30',
                title: 'Tháng kỷ lục',
                description: 'Duy trì chuỗi 30 ngày liên tiếp',
                icon: '🏆',
                required: 30,
                current: Math.max(currentStreak, longestStreak),
                unlocked: longestStreak >= 30,
            },
            {
                id: 'streak_100',
                title: 'Bách nhật',
                description: 'Duy trì chuỗi 100 ngày liên tiếp',
                icon: '👑',
                required: 100,
                current: Math.max(currentStreak, longestStreak),
                unlocked: longestStreak >= 100,
            },
            {
                id: 'entries_10',
                title: '10 ghi nhận',
                description: 'Ghi nhận cảm xúc 10 lần',
                icon: '📝',
                required: 10,
                current: totalEntries,
                unlocked: totalEntries >= 10,
            },
            {
                id: 'entries_50',
                title: '50 ghi nhận',
                description: 'Ghi nhận cảm xúc 50 lần',
                icon: '📚',
                required: 50,
                current: totalEntries,
                unlocked: totalEntries >= 50,
            },
            {
                id: 'entries_100',
                title: 'Trăm cảm xúc',
                description: 'Ghi nhận cảm xúc 100 lần',
                icon: '💯',
                required: 100,
                current: totalEntries,
                unlocked: totalEntries >= 100,
            },
            {
                id: 'note_writer',
                title: 'Nhà văn',
                description: 'Viết 10 ghi chú chi tiết',
                icon: '✍️',
                required: 10,
                current: totalNotes,
                unlocked: totalNotes >= 10,
            },
            {
                id: 'journal_master',
                title: 'Bậc thầy nhật ký',
                description: 'Viết 50 ghi chú chi tiết',
                icon: '🎓',
                required: 50,
                current: totalNotes,
                unlocked: totalNotes >= 50,
            },
            {
                id: 'diverse',
                title: 'Đa dạng cảm xúc',
                description: 'Ghi nhận ít nhất 4 loại cảm xúc khác nhau',
                icon: '🌈',
                required: 4,
                current: distinctEmotions,
                unlocked: distinctEmotions >= 4,
            },
        ];

        const unlockedCount = achievements.filter(a => a.unlocked).length;

        res.json({
            success: true,
            data: {
                current_streak: currentStreak,
                longest_streak: longestStreak,
                total_days: totalDays,
                total_entries: totalEntries,
                total_notes: totalNotes,
                points,
                unlocked_count: unlockedCount,
                total_achievements: achievements.length,
                achievements,
            },
        });
    } catch (error) {
        console.error('Get streak error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching streak data',
        });
    }
});

// Get Monthly Wrapped Story Data
router.get('/stats/monthly-wrapped', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        let { year, month } = req.query;
        
        const now = new Date();
        if (!year) year = now.getFullYear();
        if (!month) month = now.getMonth() + 1; // JS months are 0-indexed

        const db = getDB();
        
        const request = db.request()
            .input('userId', userId)
            .input('year', parseInt(year))
            .input('month', parseInt(month));

        // 1. Total distinct days and total entries
        const countResult = await request.query(`
            SELECT 
                COUNT(*) as total_entries,
                COUNT(DISTINCT CAST(timestamp AS DATE)) as total_days
            FROM Emotions
            WHERE user_id = @userId
              AND YEAR(timestamp) = @year
              AND MONTH(timestamp) = @month
        `);
        
        const totalEntries = countResult.recordset[0].total_entries || 0;
        const totalDays = countResult.recordset[0].total_days || 0;

        // 2. Emotion distribution for most frequent and positive ratio
        const distResult = await request.query(`
            SELECT emotion_type, COUNT(*) as count
            FROM Emotions
            WHERE user_id = @userId
              AND YEAR(timestamp) = @year
              AND MONTH(timestamp) = @month
            GROUP BY emotion_type
            ORDER BY count DESC
        `);
        
        const emotionDistribution = distResult.recordset;
        let mostCommonEmotion = 'Không có';
        if (emotionDistribution.length > 0) {
            mostCommonEmotion = emotionDistribution[0].emotion_type;
        }

        // Calculate positive ratio
        const positiveEmotions = ['Vui', 'Vui vẻ', 'Hào hứng', 'Bình yên', 'Tự hào', 'Biết ơn', 'Yêu thương', 'Hy vọng'];
        let positiveCount = 0;
        emotionDistribution.forEach(row => {
            if (positiveEmotions.includes(row.emotion_type)) {
                positiveCount += row.count;
            }
        });
        const positivePercentage = totalEntries > 0 ? Math.round((positiveCount / totalEntries) * 100) : 0;

        // 3. Total notes written
        const notesResult = await request.query(`
            SELECT COUNT(*) as total_notes
            FROM Emotions e
            JOIN Notes n ON e.id = n.emotion_id
            WHERE e.user_id = @userId
              AND YEAR(e.timestamp) = @year
              AND MONTH(e.timestamp) = @month
        `);
        const totalNotes = notesResult.recordset[0].total_notes || 0;

        res.json({
            success: true,
            data: {
                month: parseInt(month),
                year: parseInt(year),
                total_entries: totalEntries,
                total_days: totalDays,
                most_common_emotion: mostCommonEmotion,
                positive_percentage: positivePercentage,
                total_notes: totalNotes,
                emotion_distribution: emotionDistribution
            }
        });
    } catch (error) {
        console.error('Get monthly wrapped error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching monthly wrapped data',
        });
    }
});

module.exports = router;
