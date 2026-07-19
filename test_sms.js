async function triggerOTP() {
  const apiKey = 'AIzaSyDdepgOWXZqL0r04QMH96ka-cIieEqqZ8c';
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=${apiKey}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phoneNumber: '+916283075131' })
  });
  const data = await response.json();
  console.log('Firebase Response:', data);
}

triggerOTP().catch(console.error);
