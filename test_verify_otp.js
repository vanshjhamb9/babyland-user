const http = require('http');

const data = JSON.stringify({
  email: "testnewfirebase123@gmail.com",
  code: "123456",
});

const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/auth/verify-otp',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = http.request(options, res => {
  console.log(`statusCode: ${res.statusCode}`);
  let responseData = '';
  res.on('data', chunk => {
    responseData += chunk;
  });
  res.on('end', () => {
    console.log('\nResponse Data:', responseData);
  });
});

req.on('error', error => {
  console.error(error);
});

req.write(data);
req.end();
