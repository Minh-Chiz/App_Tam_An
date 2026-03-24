require('dotenv').config();
const nodemailer = require('nodemailer');

console.log("Testing email with user:", process.env.EMAIL_USER);
console.log("Password length:", process.env.EMAIL_PASS ? process.env.EMAIL_PASS.length : 0);

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    }
});

const mailOptions = {
    from: `"Ứng dụng Tâm An" <${process.env.EMAIL_USER}>`,
    to: process.env.EMAIL_USER, // self-send test
    subject: 'Test Code Của Agent',
    text: 'Nếu bạn nhận được tin nhắn này, cấu hình Email đã chính xác 100%'
};

transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
        console.error('❌ BUG GMAIL:', error.message);
        process.exit(1);
    } else {
        console.log('✅ GMAIL THÀNH CÔNG:', info.response);
        process.exit(0);
    }
});
