require('dotenv').config();
const sql = require('mssql');

// SQL Server configuration
const mssqlConfig = {
  server: process.env.DB_SERVER || 'localhost\\SQLEXPRESS',
  database: process.env.DB_DATABASE || 'TamAnDB',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : undefined,
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true,
  },
};

let mssqlPool = null;

// Initialize database based on type
const initDB = async () => {
  try {
    console.log('🗄️  Using SQL Server database');
    console.log('   Server:', mssqlConfig.server);
    console.log('   Database:', mssqlConfig.database);

    mssqlPool = await sql.connect(mssqlConfig);
    
    console.log('✅ Connected to SQL Server');

    return mssqlPool;
  } catch (error) {
    console.error('❌ Database initialization failed:', error.originalError?.message || error);
    throw error;
  }
};

// Get database instance
const getDB = () => {
  if (!mssqlPool || !mssqlPool.connected) {
    throw new Error('SQL Server not connected');
  }
  return mssqlPool;
};

// Close database connection
const closeDB = async () => {
  if (mssqlPool) {
    await mssqlPool.close();
    console.log('🔌 SQL Server connection closed');
  }
};

module.exports = {
  initDB,
  getDB,
  closeDB,
  sql, // Export for SQL Server queries
};
