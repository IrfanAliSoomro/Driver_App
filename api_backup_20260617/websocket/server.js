'use strict';

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { WebSocketServer } = require('ws');

function loadEnv() {
  const envPath = path.join(__dirname, '..', '.env');
  const env = {};
  if (!fs.existsSync(envPath)) return env;
  fs.readFileSync(envPath, 'utf8').split('\n').forEach((line) => {
    const t = line.trim();
    if (!t || t.startsWith('#') || !t.includes('=')) return;
    const i = t.indexOf('=');
    env[t.slice(0, i).trim()] = t.slice(i + 1).trim();
  });
  return env;
}

const env = loadEnv();
const HOST = env.WS_HOST || '127.0.0.1';
const PORT = parseInt(env.WS_PORT || '8081', 10);
const JWT_SECRET = env.JWT_SECRET || 'change-this-secret-key';
const WS_SECRET = env.WS_SECRET || 'change-this-ws-secret';

/** @type {Map<WebSocket, { userId?: string, subs: Set<string> }>} */
const clients = new Map();

function subKey(channel, group) {
  if (channel === 'chat' && group) return `chat:${group}`;
  return channel;
}

function base64UrlDecode(str) {
  const pad = '='.repeat((4 - (str.length % 4)) % 4);
  const b64 = (str + pad).replace(/-/g, '+').replace(/_/g, '/');
  return Buffer.from(b64, 'base64').toString('utf8');
}

function base64UrlEncode(buf) {
  return buf
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/** Verify JWT issued by PHP API (HS256) — compatible with Node 10+ */
function verifyToken(token) {
  try {
    const parts = String(token).split('.');
    if (parts.length !== 3) return null;

    const [header, payload, signature] = parts;
    const expected = base64UrlEncode(
      crypto.createHmac('sha256', JWT_SECRET).update(`${header}.${payload}`).digest()
    );
    if (signature !== expected) return null;

    const data = JSON.parse(base64UrlDecode(payload));
    if (!data.user_id) return null;
    if (!data.exp || data.exp < Math.floor(Date.now() / 1000)) return null;
    return data;
  } catch (e) {
    return null;
  }
}

function send(ws, obj) {
  if (ws.readyState === ws.OPEN) {
    ws.send(JSON.stringify(obj));
  }
}

function broadcast(predicate, event, payload) {
  const msg = JSON.stringify({ type: event, payload, ts: Date.now() });
  for (const [ws, meta] of clients) {
    if (ws.readyState !== ws.OPEN) continue;
    if (predicate(meta)) ws.send(msg);
  }
}

function handleBroadcast(body) {
  const { event, payload } = body;
  if (!event || !payload) return;

  switch (event) {
    case 'chat.message.new': {
      const group = payload.group;
      broadcast(
        (m) => m.subs.has(subKey('chat', group)),
        'chat.message.new',
        payload
      );
      break;
    }
    case 'chat.message.deleted': {
      const group = payload.group;
      broadcast(
        (m) => m.subs.has(subKey('chat', group)),
        'chat.message.deleted',
        payload
      );
      break;
    }
    case 'presence.counts':
      broadcast((m) => m.subs.has('presence'), 'presence.counts', payload);
      break;
    case 'price_alert.new':
    case 'price_alert.updated':
    case 'price_alert.deleted':
      broadcast((m) => m.subs.has('price_alerts'), event, payload);
      break;
    case 'notification': {
      const uid = payload.user_id;
      if (uid) {
        broadcast(
          (m) => m.userId === uid && m.subs.has('notifications'),
          'notification',
          payload
        );
      } else {
        broadcast((m) => m.subs.has('notifications'), 'notification', payload);
      }
      break;
    }
    default:
      broadcast(() => true, event, payload);
  }
}

function parseClientMessage(ws, raw) {
  let msg;
  try {
    msg = JSON.parse(raw);
  } catch (e) {
    send(ws, { type: 'error', message: 'Invalid JSON' });
    return;
  }

  const meta = clients.get(ws);
  if (!meta) return;

  switch (msg.type) {
    case 'auth': {
      const payload = verifyToken(msg.token);
      if (!payload || !payload.user_id) {
        send(ws, { type: 'error', message: 'Invalid or expired token' });
        return;
      }
      meta.userId = payload.user_id;
      send(ws, { type: 'authenticated', user_id: meta.userId });
      break;
    }
    case 'subscribe': {
      if (!meta.userId) {
        send(ws, { type: 'error', message: 'Authenticate first' });
        return;
      }
      const ch = msg.channel;
      if (ch === 'chat') {
        if (!msg.group) {
          send(ws, { type: 'error', message: 'group required for chat' });
          return;
        }
        meta.subs.add(subKey('chat', msg.group));
        send(ws, { type: 'subscribed', channel: 'chat', group: msg.group });
        return;
      }
      if (ch === 'presence' || ch === 'notifications' || ch === 'price_alerts') {
        meta.subs.add(ch);
        send(ws, { type: 'subscribed', channel: ch });
        return;
      }
      send(ws, { type: 'error', message: 'Unknown channel' });
      break;
    }
    case 'unsubscribe': {
      if (msg.channel === 'chat' && msg.group) {
        meta.subs.delete(subKey('chat', msg.group));
      } else if (msg.channel) {
        meta.subs.delete(msg.channel);
      }
      send(ws, { type: 'unsubscribed', channel: msg.channel, group: msg.group });
      break;
    }
    case 'ping':
      send(ws, { type: 'pong' });
      break;
    default:
      send(ws, { type: 'error', message: 'Unknown message type' });
  }
}

const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/internal/broadcast') {
    const secret = req.headers['x-ws-secret'];
    if (secret !== WS_SECRET) {
      res.writeHead(401);
      res.end('Unauthorized');
      return;
    }
    let body = '';
    req.on('data', (c) => (body += c));
    req.on('end', () => {
      try {
        handleBroadcast(JSON.parse(body));
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true }));
      } catch (e) {
        res.writeHead(400);
        res.end('Bad request');
      }
    });
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, clients: clients.size }));
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

const wss = new WebSocketServer({ server });

wss.on('connection', (ws, req) => {
  const meta = { userId: null, subs: new Set() };
  clients.set(ws, meta);

  const url = new URL(req.url || '/', 'http://localhost');
  const token = url.searchParams.get('token');
  if (token) {
    const payload = verifyToken(token);
    if (payload && payload.user_id) {
      meta.userId = payload.user_id;
      send(ws, { type: 'authenticated', user_id: meta.userId });
    }
  }

  send(ws, {
    type: 'connected',
    message: 'Send {"type":"auth","token":"<JWT>"} then subscribe to channels',
  });

  ws.on('message', (data) => parseClientMessage(ws, data.toString()));
  ws.on('close', () => clients.delete(ws));
});

server.listen(PORT, HOST, () => {
  console.log(`WebSocket server listening on ${HOST}:${PORT}`);
});
