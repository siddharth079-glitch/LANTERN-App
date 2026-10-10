/**
 * LANTERN Disaster Response Platform
 * Central Operations Backend & Rescue Synchronization Engine
 * Port: 3000 (HTTP + WebSockets)
 */

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { DatabaseSync } = require('node:sqlite');
const { WebSocketServer } = require('ws');

const PORT = process.env.PORT || 3000;
const DB_PATH = path.join(__dirname, 'data', 'lantern_central.db');

// Ensure data directory exists
if (!fs.existsSync(path.dirname(DB_PATH))) {
  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
}

// Initialize SQLite database
const db = new DatabaseSync(DB_PATH);

// Create database schema
db.exec(`
  CREATE TABLE IF NOT EXISTS incidents (
    incident_id TEXT PRIMARY KEY,
    client_incident_id TEXT,
    idempotency_key TEXT UNIQUE,
    emergency_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    description TEXT,
    latitude REAL,
    longitude REAL,
    accuracy_meters REAL,
    status TEXT NOT NULL,
    priority TEXT NOT NULL,
    priority_score INTEGER NOT NULL,
    responder_id TEXT,
    responder_name TEXT,
    vehicle_id TEXT,
    is_relayed INTEGER DEFAULT 0,
    relayed_by TEXT,
    relay_hops INTEGER DEFAULT 0,
    relay_path TEXT,
    relay_summary TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE INDEX IF NOT EXISTS idx_incidents_status ON incidents(status);
  CREATE INDEX IF NOT EXISTS idx_incidents_priority ON incidents(priority_score DESC);
  CREATE INDEX IF NOT EXISTS idx_incidents_idempotency ON incidents(idempotency_key);

  CREATE TABLE IF NOT EXISTS incident_events (
    event_id TEXT PRIMARY KEY,
    incident_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    actor TEXT NOT NULL,
    details TEXT NOT NULL,
    occurred_at TEXT NOT NULL,
    FOREIGN KEY(incident_id) REFERENCES incidents(incident_id)
  );

  CREATE INDEX IF NOT EXISTS idx_events_incident ON incident_events(incident_id);

  CREATE TABLE IF NOT EXISTS responders (
    responder_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    unit TEXT NOT NULL,
    role TEXT NOT NULL,
    status TEXT NOT NULL,
    vehicle_id TEXT,
    phone TEXT
  );

  CREATE TABLE IF NOT EXISTS shelters (
    shelter_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    capacity INTEGER NOT NULL,
    current_occupancy INTEGER NOT NULL,
    status TEXT NOT NULL,
    amenities TEXT NOT NULL,
    contact_phone TEXT
  );
`);

// Safe column migrations for existing databases
try { db.exec(`ALTER TABLE incidents ADD COLUMN is_relayed INTEGER DEFAULT 0;`); } catch (_) {}
try { db.exec(`ALTER TABLE incidents ADD COLUMN relayed_by TEXT;`); } catch (_) {}
try { db.exec(`ALTER TABLE incidents ADD COLUMN relay_hops INTEGER DEFAULT 0;`); } catch (_) {}
try { db.exec(`ALTER TABLE incidents ADD COLUMN relay_path TEXT;`); } catch (_) {}
try { db.exec(`ALTER TABLE incidents ADD COLUMN relay_summary TEXT;`); } catch (_) {}

// Seed initial responders and shelters if empty
const responderCount = db.prepare('SELECT COUNT(*) as count FROM responders').get().count;
if (responderCount === 0) {
  const insertResponder = db.prepare(`
    INSERT INTO responders (responder_id, name, unit, role, status, vehicle_id, phone)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);
  insertResponder.run('RSP-01', 'Captain Marcus Vance', 'Fire & Rescue Station 4', 'Incident Commander', 'AVAILABLE', 'ENGINE-4', '+1-555-0192');
  insertResponder.run('RSP-02', 'Dr. Sarah Lin', 'Disaster Medical Unit A', 'Field Triage Lead', 'AVAILABLE', 'MED-AMB-02', '+1-555-0188');
  insertResponder.run('RSP-03', 'Officer Dev Patel', 'Swift Water Search & Rescue', 'Technical Specialist', 'AVAILABLE', 'BOAT-RESCUE-1', '+1-555-0174');
  insertResponder.run('RSP-04', 'Elena Rostova', 'Civil Protection Team Gamma', 'Logistics Coordinator', 'AVAILABLE', 'TRANS-TRUCK-8', '+1-555-0145');
}

const shelterCount = db.prepare('SELECT COUNT(*) as count FROM shelters').get().count;
if (shelterCount === 0) {
  const insertShelter = db.prepare(`
    INSERT INTO shelters (shelter_id, name, type, latitude, longitude, capacity, current_occupancy, status, amenities, contact_phone)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertShelter.run('SHL-01', 'City Stadium Relief Complex', 'Primary Evacuation Center', 17.3850, 78.4867, 1200, 480, 'OPEN', 'Power Backup, Medical Bay, Potable Water, Rations', '+1-555-9001');
  insertShelter.run('SHL-02', 'North Hills Community High School', 'Secondary Safe Haven', 17.4120, 78.4980, 500, 210, 'OPEN', 'Emergency Food, Blankets, First Aid Station', '+1-555-9002');
  insertShelter.run('SHL-03', 'St. Jude Red Cross Field Hospital', 'Medical Triage Center', 17.3620, 78.4650, 350, 290, 'OPEN', 'ICU Beds, Oxygen Supplies, Trauma Surgeons', '+1-555-9003');
  insertShelter.run('SHL-04', 'West District Fire Brigade Hall', 'Temporary Distribution Node', 17.3990, 78.4420, 250, 80, 'OPEN', 'Dry Rations, Radio Communications Hub, Generator', '+1-555-9004');
}

// Priority Calculation Engine
function computePriority(severity, emergencyType, accuracy) {
  let score = 0;

  // Base score from severity
  const sev = (severity || '').toUpperCase();
  if (sev === 'CRITICAL') score += 50;
  else if (sev === 'HIGH') score += 35;
  else if (sev === 'MODERATE' || sev === 'MEDIUM') score += 20;
  else score += 10;

  // Category life-safety weighting
  const type = (emergencyType || '').toLowerCase();
  if (type.includes('medical') || type.includes('trapped') || type.includes('structural') || type.includes('injury')) {
    score += 30;
  } else if (type.includes('flood') || type.includes('fire') || type.includes('hazard')) {
    score += 20;
  } else if (type.includes('missing')) {
    score += 15;
  } else {
    score += 10;
  }

  // Location telemetry confidence bonus
  if (typeof accuracy === 'number' && accuracy > 0 && accuracy <= 20) {
    score += 5;
  }

  // Tier categorization
  let tier = 'LOW';
  if (score >= 70) tier = 'CRITICAL';
  else if (score >= 50) tier = 'HIGH';
  else if (score >= 30) tier = 'MEDIUM';

  return { score, tier };
}

// WebSocket Server initialization
const server = http.createServer(handleRequest);
const wss = new WebSocketServer({ server, path: '/ws' });

const clients = new Set();
wss.on('connection', (ws) => {
  clients.add(ws);
  ws.send(JSON.stringify({ type: 'SYSTEM_CONNECTED', message: 'Connected to LANTERN Central Live Ops Feed', timestamp: new Date().toISOString() }));

  ws.on('close', () => clients.delete(ws));
  ws.on('error', () => clients.delete(ws));
});

function broadcast(eventType, payload) {
  const msg = JSON.stringify({ type: eventType, payload, timestamp: new Date().toISOString() });
  for (const client of clients) {
    if (client.readyState === 1) { // OPEN
      client.send(msg);
    }
  }
}

// HTTP Request Handler
function handleRequest(req, res) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Idempotency-Key, X-Requested-With');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname;

  // 1. Health check
  if (pathname === '/v1/health' && req.method === 'GET') {
    const totalIncidents = db.prepare('SELECT COUNT(*) as c FROM incidents').get().c;
    const activeIncidents = db.prepare("SELECT COUNT(*) as c FROM incidents WHERE status NOT IN ('RESOLVED', 'CANCELLED')").get().c;
    sendJson(res, 200, {
      status: 'HEALTHY',
      service: 'LANTERN Central Gateway',
      uptimeSeconds: process.uptime(),
      connectedSockets: clients.size,
      totalIncidents,
      activeIncidents,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  // 2. Incident Creation (Idempotent SOS report)
  if (pathname === '/v1/incidents' && req.method === 'POST') {
    readBody(req, (err, body) => {
      if (err) return sendJson(res, 400, { error: 'Invalid JSON request payload' });

      const idempotencyKey = req.headers['idempotency-key'] || body.idempotencyKey || body.idempotency_key;
      if (!idempotencyKey) {
        return sendJson(res, 400, { error: 'Missing required Idempotency-Key header or field' });
      }

      // Check if already processed (Idempotent protection)
      const existing = db.prepare('SELECT * FROM incidents WHERE idempotency_key = ?').get(idempotencyKey);
      if (existing) {
        const events = db.prepare('SELECT * FROM incident_events WHERE incident_id = ? ORDER BY occurred_at ASC').all(existing.incident_id);
        return sendJson(res, 200, {
          isDuplicate: true,
          receipt_id: `LNT-ACK-${existing.incident_id}`,
          incident: existing,
          events,
          message: 'Idempotent replay: Incident already registered in database.',
        });
      }

      // Generate server incident ID
      const timestamp = Date.now();
      const serverIncidentId = `LNT-${timestamp.toString(36).toUpperCase()}-${Math.floor(1000 + Math.random() * 9000)}`;
      const nowUtc = new Date().toISOString();

      const { score, tier } = computePriority(body.severity, body.emergencyType || body.emergency_type, body.accuracy);

      const isRelayed = Boolean(body.isRelayed || body.is_relayed || body.relayedBy);
      const relayedBy = body.relayedBy || body.relayed_by || null;
      const relayHops = Number(body.relayHops || body.relay_hops || (isRelayed ? 1 : 0));
      const relayPath = body.relayPath ? JSON.stringify(body.relayPath) : (relayedBy ? `["${relayedBy}"]` : null);
      const relaySummary = body.relaySummary || (isRelayed ? `Forwarded by peer ${relayedBy} via local radio` : null);

      const insertStmt = db.prepare(`
        INSERT INTO incidents (
          incident_id, client_incident_id, idempotency_key, emergency_type, severity,
          description, latitude, longitude, accuracy_meters, status, priority,
          priority_score, is_relayed, relayed_by, relay_hops, relay_path, relay_summary,
          created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);

      insertStmt.run(
        serverIncidentId,
        body.clientIncidentId || body.client_incident_id || serverIncidentId,
        idempotencyKey,
        body.emergencyType || body.emergency_type || 'unspecified_emergency',
        body.severity || 'HIGH',
        body.description || '',
        typeof body.latitude === 'number' ? body.latitude : null,
        typeof body.longitude === 'number' ? body.longitude : null,
        typeof body.accuracy === 'number' ? body.accuracy : (typeof body.accuracyMeters === 'number' ? body.accuracyMeters : null),
        'SERVER_RECEIVED',
        tier,
        score,
        isRelayed ? 1 : 0,
        relayedBy,
        relayHops,
        relayPath,
        relaySummary,
        nowUtc,
        nowUtc
      );

      // Log initial event in audit trail
      const eventId = `EVT-INIT-${timestamp}`;
      const insertEvent = db.prepare(`
        INSERT INTO incident_events (event_id, incident_id, event_type, actor, details, occurred_at)
        VALUES (?, ?, ?, ?, ?, ?)
      `);
      insertEvent.run(
        eventId,
        serverIncidentId,
        'SERVER_RECEIVED',
        'CENTRAL_DISPATCH_GATEWAY',
        `Beacon registered durably. Priority calculated as ${tier} (${score} pts).`,
        nowUtc
      );

      if (isRelayed) {
        db.prepare(`
          INSERT INTO incident_events (event_id, incident_id, event_type, actor, details, occurred_at)
          VALUES (?, ?, ?, ?, ?, ?)
        `).run(
          `EVT-RELAY-${timestamp}`,
          serverIncidentId,
          'PEER_RELAY_GATEWAY_DELIVERED',
          relayedBy || 'OFFLINE_RADIO_PEER',
          `Delivered to gateway via offline peer relay (Hops: ${relayHops}). Original survivor beacon originated when phone lacked cellular/internet connection.`,
          nowUtc
        );
      }

      const createdIncident = db.prepare('SELECT * FROM incidents WHERE incident_id = ?').get(serverIncidentId);
      const events = db.prepare('SELECT * FROM incident_events WHERE incident_id = ?').all(serverIncidentId);

      // Broadcast new incident to all dashboard monitors
      broadcast('INCIDENT_CREATED', { incident: createdIncident, event: events[0] });

      return sendJson(res, 201, {
        isDuplicate: false,
        receipt_id: `LNT-ACK-${serverIncidentId}`,
        canonicalStatus: 'SERVER_RECEIVED',
        incident: createdIncident,
        events,
      });
    });
    return;
  }

  // 3. List Incidents (Dashboard & Sync)
  if (pathname === '/v1/incidents' && req.method === 'GET') {
    const statusFilter = parsedUrl.searchParams.get('status');
    let query = 'SELECT * FROM incidents';
    const params = [];

    if (statusFilter && statusFilter !== 'ALL') {
      query += ' WHERE status = ?';
      params.push(statusFilter);
    }
    query += ' ORDER BY priority_score DESC, created_at DESC';

    const incidents = db.prepare(query).all(...params);
    return sendJson(res, 200, { count: incidents.length, incidents });
  }

  // 4. Incident Detail by ID
  const incidentMatch = pathname.match(/^\/v1\/incidents\/([a-zA-Z0-9_-]+)$/);
  if (incidentMatch && req.method === 'GET') {
    const id = incidentMatch[1];
    const incident = db.prepare('SELECT * FROM incidents WHERE incident_id = ? OR client_incident_id = ?').get(id, id);
    if (!incident) return sendJson(res, 404, { error: 'Incident not found' });

    const events = db.prepare('SELECT * FROM incident_events WHERE incident_id = ? ORDER BY occurred_at ASC').all(incident.incident_id);
    return sendJson(res, 200, { incident, events });
  }

  // 5. Update Status (Acknowledge, Resolve, Cancel)
  const statusMatch = pathname.match(/^\/v1\/incidents\/([a-zA-Z0-9_-]+)\/status$/);
  if (statusMatch && req.method === 'PATCH') {
    const id = statusMatch[1];
    readBody(req, (err, body) => {
      if (err || !body.status) return sendJson(res, 400, { error: 'Missing target status' });

      const incident = db.prepare('SELECT * FROM incidents WHERE incident_id = ? OR client_incident_id = ?').get(id, id);
      if (!incident) return sendJson(res, 404, { error: 'Incident not found' });

      const nowUtc = new Date().toISOString();
      const newStatus = body.status.toUpperCase();
      const actor = body.actor || 'RESCUE_DISPATCHER';
      const reason = body.reason || `Status updated to ${newStatus}`;

      db.prepare('UPDATE incidents SET status = ?, updated_at = ? WHERE incident_id = ?').run(newStatus, nowUtc, incident.incident_id);

      const eventId = `EVT-${Date.now()}`;
      db.prepare(`
        INSERT INTO incident_events (event_id, incident_id, event_type, actor, details, occurred_at)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run(eventId, incident.incident_id, newStatus, actor, reason, nowUtc);

      const updated = db.prepare('SELECT * FROM incidents WHERE incident_id = ?').get(incident.incident_id);
      const events = db.prepare('SELECT * FROM incident_events WHERE incident_id = ? ORDER BY occurred_at ASC').all(incident.incident_id);

      broadcast('INCIDENT_STATUS_CHANGED', { incident: updated, newStatus });

      return sendJson(res, 200, { incident: updated, events });
    });
    return;
  }

  // 6. Assign Responder & Vehicle
  const assignMatch = pathname.match(/^\/v1\/incidents\/([a-zA-Z0-9_-]+)\/assign$/);
  if (assignMatch && req.method === 'POST') {
    const id = assignMatch[1];
    readBody(req, (err, body) => {
      if (err || !body.responder_id) return sendJson(res, 400, { error: 'Missing responder_id' });

      const incident = db.prepare('SELECT * FROM incidents WHERE incident_id = ? OR client_incident_id = ?').get(id, id);
      if (!incident) return sendJson(res, 404, { error: 'Incident not found' });

      const responder = db.prepare('SELECT * FROM responders WHERE responder_id = ?').get(body.responder_id);
      const responderName = responder ? responder.name : (body.responder_name || 'Assigned Unit');
      const vehicleId = responder ? responder.vehicle_id : (body.vehicle_id || 'VEHICLE-UNIT');
      const nowUtc = new Date().toISOString();

      db.prepare(`
        UPDATE incidents 
        SET responder_id = ?, responder_name = ?, vehicle_id = ?, status = 'ASSIGNED', updated_at = ?
        WHERE incident_id = ?
      `).run(body.responder_id, responderName, vehicleId, nowUtc, incident.incident_id);

      if (responder) {
        db.prepare("UPDATE responders SET status = 'DISPATCHED' WHERE responder_id = ?").run(body.responder_id);
      }

      const eventId = `EVT-ASSIGN-${Date.now()}`;
      db.prepare(`
        INSERT INTO incident_events (event_id, incident_id, event_type, actor, details, occurred_at)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run(eventId, incident.incident_id, 'RESPONDER_ASSIGNED', 'TACTICAL_OPERATIONS', `Dispatched ${responderName} with ${vehicleId}. Estimated ETA: ${body.etaMinutes || 12} mins.`, nowUtc);

      const updated = db.prepare('SELECT * FROM incidents WHERE incident_id = ?').get(incident.incident_id);
      broadcast('INCIDENT_ASSIGNED', { incident: updated, responderName, vehicleId });

      return sendJson(res, 200, { incident: updated });
    });
    return;
  }

  // 7. Shelters API
  if (pathname === '/v1/shelters' && req.method === 'GET') {
    const shelters = db.prepare('SELECT * FROM shelters').all();
    return sendJson(res, 200, { count: shelters.length, shelters });
  }

  // 8. Responders API
  if (pathname === '/v1/responders' && req.method === 'GET') {
    const responders = db.prepare('SELECT * FROM responders').all();
    return sendJson(res, 200, { count: responders.length, responders });
  }

  // 9. Static File Serving (Rescue Dashboard)
  let filePath = path.join(__dirname, 'public', pathname === '/' ? 'dashboard/index.html' : pathname);
  if (pathname === '/dashboard' || pathname === '/dashboard/') {
    filePath = path.join(__dirname, 'public', 'dashboard', 'index.html');
  }

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath).toLowerCase();
    const mimeTypes = {
      '.html': 'text/html',
      '.css': 'text/css',
      '.js': 'application/javascript',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.svg': 'image/svg+xml',
    };
    res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
    fs.createReadStream(filePath).pipe(res);
    return;
  }

  sendJson(res, 404, { error: 'Not found', path: pathname });
}

function readBody(req, callback) {
  let data = '';
  req.on('data', chunk => data += chunk);
  req.on('end', () => {
    try {
      callback(null, data ? JSON.parse(data) : {});
    } catch (e) {
      callback(e);
    }
  });
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

server.listen(PORT, '0.0.0.0', () => {
  console.log(`=======================================================`);
  console.log(`[LANTERN Central Ops Server] Running on http://0.0.0.0:${PORT}`);
  console.log(`[WebSocket Stream] ws://0.0.0.0:${PORT}/ws`);
  console.log(`[Rescue Dashboard] http://localhost:${PORT}/dashboard`);
  console.log(`=======================================================`);
});
