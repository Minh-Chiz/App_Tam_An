const axios = require('axios');
const fs = require('fs');

async function testFlow() {
  const baseUrl = 'http://localhost:3000/api';
  const testUser = {
    email: `test_${Date.now()}@example.com`,
    password: 'password123',
    name: 'Test User'
  };

  try {
    console.log('1. Registering test user...');
    const registerRes = await axios.post(`${baseUrl}/auth/register`, testUser);
    console.log('✅ Registration successful');
    const token = registerRes.data.data.token;

    console.log('2. Testing authenticated request (emotions)...');
    const emotionsRes = await axios.get(`${baseUrl}/emotions`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('✅ Emotions request successful [', emotionsRes.status, ']');

    console.log('3. Testing dashboard stats...');
    const statsRes = await axios.get(`${baseUrl}/emotions/stats/dashboard`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('✅ Dashboard stats request successful [', statsRes.status, ']');
    
    console.log('\n🎉 Backend is working correctly with tokens!');
  } catch (error) {
    console.error('❌ Test failed:', error.response ? error.response.data : error.message);
    process.exit(1);
  }
}

testFlow();
