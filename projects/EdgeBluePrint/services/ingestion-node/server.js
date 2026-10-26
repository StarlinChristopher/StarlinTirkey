const fs = require('fs');
const http = require('http');
const { Pool } = require('pg');

const API_TOKEN = fs.readFileSync('/run/secrets/telemetry_api_token', 'utf8').trim();
const pool = new Pool({
  host: process.env.SQL_HOST || 'sql-db',
  port: Number(process.env.SQL_PORT || 5432),
  database: process.env.POSTGRES_DB || 'telemetry_db',
  user: process.env.POSTGRES_USER || 'edge_user',
  password: fs.readFileSync('/run/secrets/postgres_password', 'utf8').trim(),
  max: 10,
  idleTimeoutMillis: 30000,
});

function log(level, message, fields = {}) {
  console.log(JSON.stringify({ timestamp: new Date().toISOString(), level, message, ...fields }));
}

function validatePayload(data) {
  return Boolean(data && typeof data === 'object' && typeof data.sensorId === 'string' && data.sensorId.length > 0 && data.sensorId.length <= 128 && typeof data.temperature === 'number' && Number.isFinite(data.temperature));
}

async function checkDatabase() {
  await pool.query('SELECT 1');
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ status: 'ok' }));
  }

  if (req.method === 'GET' && req.url === '/ready') {
    try {
      await checkDatabase();
      res.writeHead(200, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify({ status: 'ready' }));
    } catch (error) {
      log('error', 'database readiness check failed', { error: error.message });
      res.writeHead(503, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify({ status: 'not_ready' }));
    }
  }

  if (req.method !== 'POST' || req.url !== '/telemetry') {
    res.writeHead(404);
    return res.end();
  }

  if ((req.headers.authorization || '') !== `Bearer ${API_TOKEN}`) {
    res.writeHead(401, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Unauthorized' }));
  }
  if (req.headers['content-type'] !== 'application/json') {
    res.writeHead(415, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Content-Type must be application/json' }));
  }

  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
    if (body.length > 32768) req.destroy();
  });
  req.on('end', async () => {
    try {
      const payload = JSON.parse(body);
      const allowedKeys = ['sensorId', 'temperature'];
      const hasUnknownKeys = Object.keys(payload).some(key => !allowedKeys.includes(key));
      if (!validatePayload(payload) || hasUnknownKeys) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        return res.end(JSON.stringify({ error: 'Malformed telemetry schema' }));
      }

      await pool.query('INSERT INTO telemetry (sensor_id, temperature) VALUES ($1, $2)', [payload.sensorId, payload.temperature]);
      log('info', 'telemetry accepted', { sensorId: payload.sensorId });
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ACCEPTED', timestamp: Date.now() }));
    } catch (error) {
      log('error', 'telemetry request failed', { error: error.message });
      res.writeHead(error instanceof SyntaxError ? 400 : 503, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: error instanceof SyntaxError ? 'Invalid JSON payload' : 'Telemetry temporarily unavailable' }));
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => log('info', 'ingestion engine started', { port: PORT }));
process.on('SIGTERM', async () => { await pool.end(); server.close(() => process.exit(0)); });
