const apiOrigin = 'https://api.openweathermap.org';
const tileOrigin = 'https://tile.openweathermap.org';
const jsonHeaders = { 'Content-Type': 'application/json; charset=utf-8' };
const allowedWeatherPaths = new Set([
  '/data/2.5/weather',
  '/data/2.5/forecast',
  '/geo/1.0/direct',
]);
const allowedTileLayers = new Set([
  'precipitation_new',
  'clouds_new',
  'temp_new',
  'wind_new',
]);

function response(body, status, headers = {}) {
  return new Response(body, {
    status,
    headers: {
      ...jsonHeaders,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      ...headers,
    },
  });
}

function error(message, status) {
  return response(JSON.stringify({ error: message }), status, {
    'Cache-Control': 'no-store',
  });
}

function validateWeatherQuery(path, searchParams) {
  const isGeocoding = path === '/geo/1.0/direct';
  const allowedParameters = isGeocoding
    ? new Set(['q', 'limit'])
    : new Set(['q', 'lat', 'lon', 'units']);

  for (const name of searchParams.keys()) {
    if (!allowedParameters.has(name)) return null;
  }

  const parameters = new Map();
  for (const name of allowedParameters) {
    const values = searchParams.getAll(name);
    if (values.length > 1) return null;
    if (values.length === 1) parameters.set(name, values[0]);
  }

  if (isGeocoding) {
    const query = parameters.get('q');
    const limit = Number(parameters.get('limit') ?? '5');
    if (
      !query ||
      query.trim().length < 2 ||
      query.length > 100 ||
      !Number.isInteger(limit) ||
      limit < 1 ||
      limit > 5
    ) {
      return null;
    }
    parameters.set('limit', String(limit));
    return parameters;
  }

  const query = parameters.get('q');
  const latitude = parameters.get('lat');
  const longitude = parameters.get('lon');
  const hasCoordinates = latitude !== undefined && longitude !== undefined;
  const hasCity = query !== undefined;
  if (hasCity === hasCoordinates) return null;
  if (latitude !== undefined && !hasCoordinates) return null;
  if (longitude !== undefined && !hasCoordinates) return null;
  if (query !== undefined && (query.trim().length === 0 || query.length > 100)) {
    return null;
  }
  if (hasCoordinates) {
    const lat = Number(latitude);
    const lon = Number(longitude);
    if (!Number.isFinite(lat) || lat < -90 || lat > 90) return null;
    if (!Number.isFinite(lon) || lon < -180 || lon > 180) return null;
  }
  if (parameters.has('units') && parameters.get('units') !== 'metric') {
    return null;
  }
  parameters.set('units', 'metric');
  return parameters;
}

function tileRoute(pathname) {
  const match =
    /^\/map\/([a-z_]+)\/(\d{1,2})\/(\d+)\/(\d+)\.png$/.exec(pathname);
  if (!match || !allowedTileLayers.has(match[1])) return null;

  const zoom = Number(match[2]);
  const x = Number(match[3]);
  const y = Number(match[4]);
  if (!Number.isInteger(zoom) || zoom < 0 || zoom > 18) return null;
  const tileCount = 2 ** zoom;
  if (!Number.isSafeInteger(x) || !Number.isSafeInteger(y)) return null;
  if (x < 0 || x >= tileCount || y < 0 || y >= tileCount) return null;
  return match[0];
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return response(null, 204);
    }
    if (request.method !== 'GET') {
      return error('Method not allowed.', 405);
    }

    const requestUrl = new URL(request.url);
    if (requestUrl.href.length > 2048) {
      return error('Request URL is too long.', 414);
    }

    const tilePath = tileRoute(requestUrl.pathname);
    const isTile = tilePath !== null;
    if (!isTile && !allowedWeatherPaths.has(requestUrl.pathname)) {
      return error('Endpoint not found.', 404);
    }
    if (!isTile && requestUrl.searchParams.has('appid')) {
      return error('API credentials must not be sent by the client.', 400);
    }
    if (isTile && requestUrl.search) {
      return error('Tile requests do not accept query parameters.', 400);
    }

    if (!env.OPENWEATHER_API_KEY) {
      return error('Weather service is not configured.', 503);
    }

    const clientIp = request.headers.get('CF-Connecting-IP');
    if (!clientIp || !env.WEATHER_RATE_LIMITER) {
      return error('Weather service rate limiting is not configured.', 503);
    }
    let rateLimit;
    try {
      rateLimit = await env.WEATHER_RATE_LIMITER.limit({ key: clientIp });
    } catch {
      return error('Weather service rate limiting is unavailable.', 503);
    }
    if (!rateLimit.success) {
      return error('Too many requests. Please try again shortly.', 429);
    }

    let upstreamUrl;
    if (isTile) {
      upstreamUrl = new URL(tilePath, tileOrigin);
    } else {
      const parameters = validateWeatherQuery(
        requestUrl.pathname,
        requestUrl.searchParams,
      );
      if (!parameters) {
        return error('Invalid weather request parameters.', 400);
      }
      upstreamUrl = new URL(requestUrl.pathname, apiOrigin);
      for (const [name, value] of parameters) {
        upstreamUrl.searchParams.set(name, value);
      }
    }
    upstreamUrl.searchParams.set('appid', env.OPENWEATHER_API_KEY);

    let upstream;
    try {
      upstream = await fetch(upstreamUrl, {
        headers: { Accept: isTile ? 'image/png' : 'application/json' },
      });
    } catch {
      return error('Weather provider is unavailable.', 502);
    }

    const headers = {
      'Cache-Control':
        upstream.status === 200
          ? isTile
            ? 'public, max-age=1800'
            : requestUrl.pathname === '/geo/1.0/direct'
              ? 'public, max-age=3600'
              : 'public, max-age=60'
          : 'no-store',
    };
    const contentType = upstream.headers.get('Content-Type');
    if (contentType) headers['Content-Type'] = contentType;

    return response(upstream.body, upstream.status, headers);
  },
};
