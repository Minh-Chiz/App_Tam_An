// Test Database Connection (SQL Server)
const { initDB, closeDB } = require('./config/database');

async function testConnection() {
    console.log('🧪 Testing SQL Server Database Connection...\n');

    try {
        const db = await initDB();
        console.log('\n✅ Connection successful!\n');

        console.log('Testing SQL Server query...');
        const result = await db.request().query('SELECT @@VERSION as version');
        console.log('SQL Server Version:', result.recordset[0].version.split('\n')[0]);

        const dbTest = await db.request().query('SELECT DB_NAME() as current_db');
        console.log('Current Database:', dbTest.recordset[0].current_db);

        const tables = await db.request().query(`
        SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_NAME
      `);

        console.log('\n📊 Tables in database:');
        tables.recordset.forEach(t => console.log('  -', t.TABLE_NAME));

        console.log('\n🎉 All tests passed!');

        await closeDB();
        process.exit(0);
    } catch (error) {
        console.error('\n❌ Connection failed!');
        console.error('Error:', error.message);
        console.error('\nTroubleshooting:');
        console.error('1. Make sure TCP/IP is enabled');
        console.error('2. Make sure SQL Server is running');
        console.error('3. Check .env configuration');
        process.exit(1);
    }
}

testConnection();
