const http = require('http');

async function testAuth() {
  const baseUrl = 'http://164.52.197.176/api/auths';
  const email = 'testuser1234@example.com';
  const phone = '+919988776655';
  const password = 'StrongPassword123!';

  console.log('Testing Signup...');
  const signupRes = await fetch(`${baseUrl}/signup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, phone, password })
  });
  
  const signupData = await signupRes.json();
  console.log('Signup Res:', signupData);

  // Now the login attempt should fail if phone is not verified
  console.log('\nTesting Login before verification...');
  const loginRes = await fetch(`${baseUrl}/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  const loginData = await loginRes.json();
  console.log('Login Res:', loginData);
}

testAuth().catch(console.error);
