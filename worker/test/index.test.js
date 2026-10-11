import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import worker from '../src/index.js';

const originalFetch = globalThis.fetch;
const secret = 'test-only-server-secret';

afterEach(() => {
  globalThis.fetch = originalFetch;
});

function environment(limit = async () => ({ success: true })) {
  return {
    OPENWEATHER_API_KEY: secret,
    WEATHER_RATE_LIMITER: { limit },
  };
}

function getRequest(path) {
  return new Request(`https://worker.example${path}`, {
    headers: { 'CF-Connecting-IP': '192.0.2.12' },
  });
}

test('forwards weather requests with the server-side key', async () => {
  let upstreamUrl;
  globalThis.fetch = async (url) => {
    upstreamUrl = new URL(url);
    return Response.json({ name: 'Kampala' });
  };

  const response = await worker.fetch(
    getRequest('/data/2.5/weather?q=Kampala&units=metric'),
    environment(),
  );

  assert.equal(response.status, 200);
  assert.equal(upstreamUrl.origin, 'https://api.openweathermap.org');
  assert.equal(upstreamUrl.pathname, '/data/2.5/weather');
  assert.equal(upstreamUrl.searchParams.get('q'), 'Kampala');
  assert.equal(upstreamUrl.searchParams.get('appid'), secret);
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), '*');
});

test('forwards geocoding requests through the key-protected upstream', async () => {
  let upstreamUrl;
  globalThis.fetch = async (url) => {
    upstreamUrl = new URL(url);
    return Response.json([{ name: 'Kampala' }]);
  };

  const response = await worker.fetch(
    getRequest('/geo/1.0/direct?q=Kampala&limit=5'),
    environment(),
  );

  assert.equal(response.status, 200);
  assert.equal(upstreamUrl.pathname, '/geo/1.0/direct');
  assert.equal(upstreamUrl.searchParams.get('q'), 'Kampala');
  assert.equal(upstreamUrl.searchParams.get('limit'), '5');
  assert.equal(upstreamUrl.searchParams.get('appid'), secret);
});

test('rejects client API keys and arbitrary proxy paths', async () => {
  let fetchCalled = false;
  globalThis.fetch = async () => {
    fetchCalled = true;
    return Response.json({});
  };

  const keyResponse = await worker.fetch(
    getRequest('/data/2.5/weather?q=Kampala&appid=client-key'),
    environment(),
  );
  const pathResponse = await worker.fetch(
    getRequest('/anything'),
    environment(),
  );

  assert.equal(keyResponse.status, 400);
  assert.equal(pathResponse.status, 404);
  assert.equal(fetchCalled, false);
});

test('validates coordinates and only proxies supported map tiles', async () => {
  const upstreamUrls = [];
  globalThis.fetch = async (url) => {
    upstreamUrls.push(new URL(url));
    return new Response('tile', {
      headers: { 'Content-Type': 'image/png' },
    });
  };

  const badCoordinates = await worker.fetch(
    getRequest('/data/2.5/weather?lat=95&lon=0'),
    environment(),
  );
  const validTile = await worker.fetch(
    getRequest('/map/temp_new/2/2/1.png'),
    environment(),
  );
  const invalidTile = await worker.fetch(
    getRequest('/map/unknown/2/2/1.png'),
    environment(),
  );

  assert.equal(badCoordinates.status, 400);
  assert.equal(validTile.status, 200);
  assert.equal(upstreamUrls[0].origin, 'https://tile.openweathermap.org');
  assert.equal(upstreamUrls[0].pathname, '/map/temp_new/2/2/1.png');
  assert.equal(upstreamUrls[0].searchParams.get('appid'), secret);
  assert.equal(invalidTile.status, 404);
  assert.equal(upstreamUrls.length, 1);
});

test('rate-limits clients before making upstream requests', async () => {
  let limitedKey;
  globalThis.fetch = async () => {
    assert.fail('The rate-limited request must not reach the upstream API.');
  };

  const response = await worker.fetch(
    getRequest('/data/2.5/weather?q=Kampala'),
    environment(async ({ key }) => {
      limitedKey = key;
      return { success: false };
    }),
  );

  assert.equal(limitedKey, '192.0.2.12');
  assert.equal(response.status, 429);
});

test('fails closed when the rate limiter or its client address is unavailable', async () => {
  const withoutAddress = await worker.fetch(
    new Request('https://worker.example/data/2.5/weather?q=Kampala'),
    environment(),
  );
  const withoutLimiter = await worker.fetch(
    getRequest('/data/2.5/weather?q=Kampala'),
    { OPENWEATHER_API_KEY: secret },
  );

  assert.equal(withoutAddress.status, 503);
  assert.equal(withoutLimiter.status, 503);
});

test('handles CORS preflight and reports a missing server API key', async () => {
  const preflight = await worker.fetch(
    new Request('https://worker.example/data/2.5/weather', {
      method: 'OPTIONS',
    }),
    {},
  );
  const missingKey = await worker.fetch(
    getRequest('/data/2.5/weather?q=Kampala'),
    { WEATHER_RATE_LIMITER: { limit: async () => ({ success: true }) } },
  );

  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers.get('Access-Control-Allow-Methods'), 'GET, OPTIONS');
  assert.equal(missingKey.status, 503);
});
