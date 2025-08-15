import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 10 }, // Ramp up to 10 users
    { duration: '5m', target: 10 }, // Stay at 10 users
    { duration: '2m', target: 50 }, // Ramp up to 50 users
    { duration: '5m', target: 50 }, // Stay at 50 users
    { duration: '2m', target: 0 },  // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
    http_req_failed: ['rate<0.1'],    // Error rate must be below 10%
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://stylehub.local';

export default function () {
  // Test homepage
  const homeResponse = http.get(`${BASE_URL}/`);
  check(homeResponse, {
    'homepage status is 200': (r) => r.status === 200,
    'homepage loads fast': (r) => r.timings.duration < 1000,
  });

  sleep(1);

  // Test products API
  const productsResponse = http.get(`${BASE_URL}/api/products`);
  check(productsResponse, {
    'products API status is 200': (r) => r.status === 200,
    'products API loads fast': (r) => r.timings.duration < 500,
  });

  sleep(1);

  // Test user registration
  const userData = {
    username: `user_${Date.now()}`,
    email: `user_${Date.now()}@example.com`,
    password: 'password123',
  };

  const registerResponse = http.post(`${BASE_URL}/api/users/register`, JSON.stringify(userData), {
    headers: { 'Content-Type': 'application/json' },
  });

  check(registerResponse, {
    'registration status is 201': (r) => r.status === 201,
    'registration response time': (r) => r.timings.duration < 1000,
  });

  sleep(2);
}
