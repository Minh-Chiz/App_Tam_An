const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
    try {
        // Get token from header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            console.log('❌ Auth failed: No token provided');
            return res.status(401).json({
                success: false,
                message: 'No token provided',
            });
        }

        const token = authHeader.substring(7); // Remove 'Bearer ' prefix

        // Verify token
        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
            
            // Add user info to request
            req.user = {
                id: decoded.userId,
                email: decoded.email,
            };

            next();
        } catch (error) {
            console.log('❌ Auth failed: Token error:', error.name, error.message);
            if (error.name === 'JsonWebTokenError') {
                return res.status(401).json({
                    success: false,
                    message: 'Invalid token',
                });
            }
            if (error.name === 'TokenExpiredError') {
                return res.status(401).json({
                    success: false,
                    message: 'Token expired',
                });
            }
            throw error;
        }
    } catch (error) {
        console.error('❌ Auth error (Internal):', error);
        return res.status(500).json({
            success: false,
            message: 'Authentication error',
        });
    }
};

module.exports = authMiddleware;
