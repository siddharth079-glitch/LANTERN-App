/**
 * Automated Test Suite for LANTERN Operations Backend
 * Tests: SOS Creation, Idempotency, Priority Engine, Status Transitions, Dispatch
 */

const test = require('node:test');
const assert = require('node:assert');
const http = require('node:http');

const BASE_URL = 'http://127.0.0.1:3000';

function postJson(path, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = http.request(`${BASE_URL}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
        ...headers,
      },
    }, (res) => {
      let resBody = '';
      res.on('data', chunk => resBody += chunk);
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, data: JSON.parse(resBody) });
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function getJson(path) {
  return new Promise((resolve, reject) => {
    http.get(`${BASE_URL}${path}`, (res) => {
      let resBody = '';
      res.on('data', chunk => resBody += chunk);
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, data: JSON.parse(resBody) });
      });
    }).on('error', reject);
  });
}

function patchJson(path, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = http.request(`${BASE_URL}${path}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    }, (res) => {
      let resBody = '';
      res.on('data', chunk => resBody += chunk);
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, data: JSON.parse(resBody) });
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

test('Test 1: Health check returns HEALTHY and service info', async () => {
  const res = await getJson('/v1/health');
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.data.status, 'HEALTHY');
  assert.strictEqual(res.data.service, 'LANTERN Central Gateway');
});

test('Test 2: Create SOS incident and verify priority calculation', async () => {
  const key = `IDEM-TEST-${Date.now()}`;
  const res = await postJson('/v1/incidents', {
    clientIncidentId: 'CLIENT-E2E-1',
    emergencyType: 'trapped',
    severity: 'CRITICAL',
    description: 'Structural collapse with trapped survivors.',
    latitude: 17.3850,
    longitude: 78.4867,
    accuracy: 10,
  }, { 'Idempotency-Key': key });

  assert.strictEqual(res.statusCode, 201);
  assert.strictEqual(res.data.isDuplicate, false);
  assert.strictEqual(res.data.canonicalStatus, 'SERVER_RECEIVED');
  assert.strictEqual(res.data.incident.priority, 'CRITICAL');
  assert.ok(res.data.incident.priority_score >= 80, 'Critical score should be >= 80');

  // Test 3: Idempotent replay with same idempotency key
  const replayRes = await postJson('/v1/incidents', {
    clientIncidentId: 'CLIENT-E2E-1',
    emergencyType: 'trapped',
    severity: 'CRITICAL',
  }, { 'Idempotency-Key': key });

  assert.strictEqual(replayRes.statusCode, 200);
  assert.strictEqual(replayRes.data.isDuplicate, true);
  assert.strictEqual(replayRes.data.incident.incident_id, res.data.incident.incident_id);

  // Test 4: Acknowledge incident
  const ackRes = await patchJson(`/v1/incidents/${res.data.incident.incident_id}/status`, {
    status: 'ACKNOWLEDGED',
    actor: 'TEST_DISPATCHER',
    reason: 'Test triage acknowledgement',
  });
  assert.strictEqual(ackRes.statusCode, 200);
  assert.strictEqual(ackRes.data.incident.status, 'ACKNOWLEDGED');

  // Test 5: Assign rescue unit
  const assignRes = await postJson(`/v1/incidents/${res.data.incident.incident_id}/assign`, {
    responder_id: 'RSP-01',
    etaMinutes: 8,
  });
  assert.strictEqual(assignRes.statusCode, 200);
  assert.strictEqual(assignRes.data.incident.status, 'ASSIGNED');
  assert.strictEqual(assignRes.data.incident.responder_id, 'RSP-01');

  // Test 6: Resolve incident
  const resolveRes = await patchJson(`/v1/incidents/${res.data.incident.incident_id}/status`, {
    status: 'RESOLVED',
    actor: 'COMMAND_CHIEF',
    reason: 'All survivors extracted safely.',
  });
  assert.strictEqual(resolveRes.statusCode, 200);
  assert.strictEqual(resolveRes.data.incident.status, 'RESOLVED');
});

test('Test 7: Shelters endpoint returns seeded emergency locations', async () => {
  const res = await getJson('/v1/shelters');
  assert.strictEqual(res.statusCode, 200);
  assert.ok(res.data.shelters.length >= 4, 'Should contain at least 4 seeded shelters');
});

test('Test 8: Responders endpoint returns operational fleet', async () => {
  const res = await getJson('/v1/responders');
  assert.strictEqual(res.statusCode, 200);
  assert.ok(res.data.responders.length >= 4, 'Should contain at least 4 seeded responders');
});

test('Test 9: Peer-relayed SOS packet ingestion preserves relay metadata and event history', async () => {
  const key = `IDEM-RELAY-${Date.now()}`;
  const res = await postJson('/v1/incidents', {
    clientIncidentId: 'CLIENT-OFFLINE-SURVIVOR-99',
    emergencyType: 'flood',
    severity: 'HIGH',
    description: 'Relayed via nearby phone. Phone A has no internet.',
    latitude: 17.3615,
    longitude: 78.4746,
    accuracy: 15,
    isRelayed: true,
    relayedBy: 'NODE-PHONE-B-GATEWAY',
    relayHops: 2,
    relayPath: ['NODE-PHONE-A-OFFLINE', 'NODE-PHONE-B-GATEWAY'],
    relaySummary: 'Transferred via offline radio to Phone B, which gained cellular internet.',
  }, { 'Idempotency-Key': key });

  assert.strictEqual(res.statusCode, 201);
  assert.strictEqual(res.data.incident.is_relayed, 1);
  assert.strictEqual(res.data.incident.relayed_by, 'NODE-PHONE-B-GATEWAY');
  assert.strictEqual(res.data.incident.relay_hops, 2);
  assert.ok(res.data.incident.relay_path.includes('NODE-PHONE-A-OFFLINE'));
});

