const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { getDB } = require('../config/database');
const authMiddleware = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const nodemailer = require('nodemailer');

const router = express.Router();

// Configure multer for avatar uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/avatars/');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, 'avatar-' + req.user.id + '-' + uniqueSuffix + path.extname(file.originalname));
    },
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 2 * 1024 * 1024 }, // 2MB limit
    fileFilter: (req, file, cb) => {
        const filetypes = /jpeg|jpg|png/;
        const mimetype = filetypes.test(file.mimetype);
        const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
        if (mimetype && extname) {
            return cb(null, true);
        }
        cb(new Error('Only .png, .jpg and .jpeg format allowed!'));
    },
});

// Update profile avatar
router.post('/profile/avatar', authMiddleware, upload.single('avatar'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'Please upload a file' });
        }

        const userId = req.user.id;
        const db = getDB();

        // Save relative path to database
        const avatarUrl = `/uploads/avatars/${req.file.filename}`;

        await db.request()
            .input('userId', userId)
            .input('avatarUrl', avatarUrl)
            .query('UPDATE Users SET avatar_url = @avatarUrl, updated_at = GETDATE() WHERE id = @userId');

        res.json({
            success: true,
            message: 'Avatar updated successfully',
            data: { avatar_url: avatarUrl },
        });
    } catch (error) {
        console.error('Avatar upload error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during avatar upload',
        });
    }
});

// Delete profile avatar
router.delete('/profile/avatar', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;
        const db = getDB();

        // Get current avatar_url
        const userResult = await db.request()
            .input('userId', userId)
            .query('SELECT avatar_url FROM Users WHERE id = @userId');

        if (userResult.recordset.length === 0) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const avatarUrl = userResult.recordset[0].avatar_url;

        if (avatarUrl) {
            // Delete physical file
            const filePath = path.join(__dirname, '../../', avatarUrl);
            try {
                await fs.unlink(filePath);
                console.log(`Deleted avatar file: ${filePath}`);
            } catch (err) {
                console.error(`Error deleting file ${filePath}:`, err);
                // Continue even if file is missing (perhaps already deleted or moved)
            }
        }

        // Update database
        await db.request()
            .input('userId', userId)
            .query('UPDATE Users SET avatar_url = NULL, updated_at = GETDATE() WHERE id = @userId');

        res.json({
            success: true,
            message: 'Avatar deleted successfully',
        });
    } catch (error) {
        console.error('Avatar deletion error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during avatar deletion',
        });
    }
});

// Register new user
router.post('/register', async (req, res) => {
    try {
        const { email, password, name, phone_number } = req.body;

        if (!email || !password || !name) {
            return res.status(400).json({
                success: false,
                message: 'Email, password, and name are required',
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Password must be at least 6 characters',
            });
        }

        const db = getDB();

        let user;

        // Check if user exists (by email or phone)
        const existing = await db.request()
            .input('email', email)
            .input('phone_number', phone_number || null)
            .query('SELECT id FROM Users WHERE email = @email OR (phone_number = @phone_number AND @phone_number IS NOT NULL)');
        
        if (existing.recordset.length > 0) {
            return res.status(400).json({ success: false, message: 'Email or Phone number already registered' });
        }

        // Hash password
        const passwordHash = await bcrypt.hash(password, 10);

        // Insert user and get ID
        const result = await db.request()
            .input('email', email)
            .input('password_hash', passwordHash)
            .input('name', name)
            .input('phone_number', phone_number || null)
            .query(`
                INSERT INTO Users (email, password_hash, name, phone_number) 
                OUTPUT INSERTED.id, INSERTED.email, INSERTED.name, INSERTED.avatar_url, INSERTED.phone_number
                VALUES (@email, @password_hash, @name, @phone_number)
            `);
        
        user = {
            id: result.recordset[0].id,
            email: result.recordset[0].email,
            name: result.recordset[0].name,
            phone_number: result.recordset[0].phone_number,
            avatar_url: result.recordset[0].avatar_url || null,
        };

        // Generate token
        const token = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_SECRET || 'your-secret-key',
            { expiresIn: '7d' }
        );

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            data: { user, token },
        });
    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during registration',
        });
    }
});

// Login user
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email/Phone and password are required',
            });
        }

        const db = getDB();

        let user;

        const result = await db.request()
            .input('identifier', email)
            .query('SELECT id, email, phone_number, password_hash, name, avatar_url FROM Users WHERE email = @identifier OR phone_number = @identifier');

        if (result.recordset.length === 0) {
            return res.status(401).json({ success: false, message: 'Invalid email/phone or password' });
        }
        user = result.recordset[0];

        // Check password
        const isValid = await bcrypt.compare(password, user.password_hash);
        if (!isValid) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password',
            });
        }

        // Generate token
        const token = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_SECRET || 'your-secret-key',
            { expiresIn: '7d' }
        );

        res.json({
            success: true,
            message: 'Login successful',
            data: {
                user: { 
                    id: user.id, 
                    email: user.email, 
                    name: user.name,
                    avatar_url: user.avatar_url || null 
                },
                token,
            },
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during login',
        });
    }
});

// Get profile
router.get('/profile', authMiddleware, async (req, res) => {
    try {
        const db = getDB();
        
        const result = await db.request()
            .input('userId', req.user.id)
            .query('SELECT id, email, phone_number, name, avatar_url, created_at FROM Users WHERE id = @userId');

        if (result.recordset.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        const userData = result.recordset[0];
        res.json({
            success: true,
            data: {
                user: {
                    id: userData.id,
                    email: userData.email,
                    phone_number: userData.phone_number,
                    name: userData.name,
                    avatar_url: userData.avatar_url || null,
                    created_at: userData.created_at,
                },
            },
        });
    } catch (error) {
        console.error('Profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
        });
    }
});

// Forgot Password
router.post('/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }

        const db = getDB();
        
        const existing = await db.request()
            .input('identifier', email)
            .query('SELECT id, email, name FROM Users WHERE email = @identifier OR phone_number = @identifier');
        
        if (existing.recordset.length === 0) {
            return res.status(404).json({ success: false, message: 'Email hoặc Số điện thoại không tồn tại' });
        }

        const user = existing.recordset[0];

        // Generate 6 digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        // Expiration = 15 minutes from now
        const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

        await db.request()
            .input('userId', user.id)
            .input('otp', otp)
            .input('expires_at', expiresAt)
            .query('UPDATE Users SET reset_otp = @otp, reset_otp_expires_at = @expires_at WHERE id = @userId');

        // Setup Nodemailer logic to send email
        // Require EMAIL_USER and EMAIL_PASS set in .env
        const transporter = nodemailer.createTransport({
            service: 'gmail', // Standard Gmail transport
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS, // Needs App Password if 2FA is on
            }
        });

        // Email HTML template
        const mailOptions = {
            from: `"Ứng dụng Tâm An" <${process.env.EMAIL_USER || 'no-reply@taman.com'}>`,
            to: user.email, // Sử dụng email thật của user từ DB
            subject: 'Khôi phục mật khẩu tài khoản Tâm An',
            html: `
            <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
                <h2 style="color: #6A1B9A;">Chào ${user.name},</h2>
                <p>Bạn vừa yêu cầu khôi phục mật khẩu cho ứng dụng Tâm An.</p>
                <p>Mã xác nhận (OTP) của bạn là:</p>
                <div style="font-size: 24px; font-weight: bold; background: #f3e5f5; color: #6A1B9A; padding: 15px; text-align: center; border-radius: 8px; letter-spacing: 5px; width: fit-content; margin: 20px 0;">
                    ${otp}
                </div>
                <p>Mã này có hiệu lực trong vòng <strong>15 phút</strong>. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
                <br/>
                <p>Trân trọng,<br/>Đội ngũ Tâm An</p>
            </div>
            `
        };

        // Try to send email (if configured)
        if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
            await transporter.sendMail(mailOptions);
            console.log(`[EMAIL SENT] OTP sent to ${email}`);
        } else {
            // Fallback for development if .env is not yet set
            console.warn(`[WARNING] EMAIL_USER/PASS not set! Mocking OTP for ${email}: ${otp}`);
        }

        res.json({
            success: true,
            message: 'OTP has been sent to your email.',
            data: {
                // If in production, you should completely remove mock_otp from here.
                // Keeping it for the user to copy during development if .env fails.
                mock_otp: (!process.env.EMAIL_USER) ? otp : null, 
            }
        });

    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({ success: false, message: 'Server error during forgot password' });
    }
});

// Reset Password
router.post('/reset-password', async (req, res) => {
    try {
        const { email, otp, new_password } = req.body;
        
        if (!email || !otp || !new_password) {
            return res.status(400).json({ success: false, message: 'Email, OTP, and new password are required' });
        }
        if (new_password.length < 6) {
            return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
        }

        const db = getDB();
        
        const result = await db.request()
            .input('identifier', email)
            .input('otp', otp)
            .query('SELECT id, reset_otp_expires_at FROM Users WHERE (email = @identifier OR phone_number = @identifier) AND reset_otp = @otp');
        
        if (result.recordset.length === 0) {
            return res.status(400).json({ success: false, message: 'Invalid or incorrect OTP' });
        }

        const user = result.recordset[0];
        
        if (new Date() > new Date(user.reset_otp_expires_at)) {
            return res.status(400).json({ success: false, message: 'OTP has expired' });
        }

        // OTP is correct and unexpired, hash new password
        const passwordHash = await bcrypt.hash(new_password, 10);
        
        await db.request()
            .input('userId', user.id)
            .input('passwordHash', passwordHash)
            .query('UPDATE Users SET password_hash = @passwordHash, reset_otp = NULL, reset_otp_expires_at = NULL, updated_at = GETDATE() WHERE id = @userId');

        res.json({
            success: true,
            message: 'Password has been reset successfully. You can now login with your new password.',
        });

    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({ success: false, message: 'Server error during password reset' });
    }
});

module.exports = router;
