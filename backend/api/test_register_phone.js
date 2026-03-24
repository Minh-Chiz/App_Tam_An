const axios = require('axios');

async function testRegister() {
    try {
        const res = await axios.post('http://localhost:3000/api/auth/register', {
            email: 'test_register_phone_' + Date.now() + '@gmail.com',
            password: 'password123',
            name: 'Test Phone User',
            phone_number: '0123456789'
        });
        console.log("Success:", res.data);
    } catch (err) {
        console.error("Error from backend:", err.response ? err.response.data : err.message);
    }
}

testRegister();
