import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../features/sos/domain/models.dart';
import '../../shared/widgets/status_chip.dart';

class DatabaseHelper {
  static Database? _database;
  static DatabaseHelper? _instance;

  // In-memory web fallback stores (used when running preview in browser on localhost)
  final Map<String, IncidentModel> _webIncidents = {};
  final Map<String, OutboxRecord> _webOutbox = {};
  final List<IncidentEventRecord> _webEvents = [];
  final Map<String, CachedPlaceRecord> _webPlaces = {};

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  // Allow injecting custom Database instance (e.g., for in-memory unit tests)
  static void setMockDatabase(Database db) {
    _database = db;
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'lantern_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS incidents (
        incident_id TEXT PRIMARY KEY,
        incident_type TEXT NOT NULL,
        created_at_utc TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        location_accuracy_m REAL,
        location_captured_at_utc TEXT,
        people_affected INTEGER,
        description_encrypted_or_minimized TEXT,
        local_state TEXT NOT NULL,
        server_state TEXT,
        last_server_update_utc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS outbox (
        outbox_id TEXT PRIMARY KEY,
        incident_id TEXT NOT NULL,
        payload_version INTEGER NOT NULL,
        idempotency_key TEXT UNIQUE NOT NULL,
        state TEXT NOT NULL,
        attempt_count INTEGER NOT NULL,
        next_attempt_at_utc TEXT,
        last_attempt_at_utc TEXT,
        last_error_code TEXT,
        lease_until_utc TEXT,
        transport TEXT,
        FOREIGN KEY (incident_id) REFERENCES incidents (incident_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS incident_events (
        event_id TEXT PRIMARY KEY,
        incident_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        occurred_at_utc TEXT NOT NULL,
        source TEXT NOT NULL,
        verified INTEGER NOT NULL,
        safe_summary TEXT NOT NULL,
        server_sequence INTEGER,
        FOREIGN KEY (incident_id) REFERENCES incidents (incident_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_places (
        place_id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        source TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        availability_status TEXT,
        metadata_json TEXT
      )
    ''');

    // Indexes for fast lookup of outbox state and incident timeline
    await db.execute('CREATE INDEX IF NOT EXISTS idx_outbox_state ON outbox(state)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_incident ON incident_events(incident_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_places_category ON cached_places(category)');
  }

  /// FR-02: Single atomic transaction for incident + outbox record
  Future<bool> createIncidentTransactional({
    required IncidentModel incident,
    required OutboxRecord outbox,
    required IncidentEventRecord initialEvent,
  }) async {
    if (kIsWeb) {
      _webIncidents[incident.incidentId] = incident;
      _webOutbox[outbox.outboxId] = outbox;
      _webEvents.add(initialEvent);
      return true;
    }

    final db = await database;
    try {
      await db!.transaction((txn) async {
        await txn.insert(
          'incidents',
          incident.toMap(),
          conflictAlgorithm: ConflictAlgorithm.fail,
        );
        await txn.insert(
          'outbox',
          outbox.toMap(),
          conflictAlgorithm: ConflictAlgorithm.fail,
        );
        await txn.insert(
          'incident_events',
          initialEvent.toMap(),
          conflictAlgorithm: ConflictAlgorithm.fail,
        );
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<IncidentModel>> getAllIncidents() async {
    if (kIsWeb) {
      final list = _webIncidents.values.toList();
      list.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      return list;
    }

    final db = await database;
    final results = await db!.query(
      'incidents',
      orderBy: 'created_at_utc DESC',
    );
    return results.map((m) => IncidentModel.fromMap(m)).toList();
  }

  Future<IncidentModel?> getIncidentById(String incidentId) async {
    if (kIsWeb) {
      return _webIncidents[incidentId];
    }

    final db = await database;
    final results = await db!.query(
      'incidents',
      where: 'incident_id = ?',
      whereArgs: [incidentId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return IncidentModel.fromMap(results.first);
  }

  Future<void> updateIncidentState({
    required String incidentId,
    required IncidentDeliveryState localState,
    String? serverState,
    DateTime? lastServerUpdateUtc,
  }) async {
    if (kIsWeb) {
      final existing = _webIncidents[incidentId];
      if (existing != null) {
        _webIncidents[incidentId] = existing.copyWith(
          localState: localState,
          serverState: serverState,
          lastServerUpdateUtc: lastServerUpdateUtc,
        );
      }
      return;
    }

    final db = await database;
    final values = <String, dynamic>{
      'local_state': localState.name,
    };
    if (serverState != null) values['server_state'] = serverState;
    if (lastServerUpdateUtc != null) {
      values['last_server_update_utc'] = lastServerUpdateUtc.toIso8601String();
    }

    await db!.update(
      'incidents',
      values,
      where: 'incident_id = ?',
      whereArgs: [incidentId],
    );
  }

  Future<void> cancelIncident(String incidentId) async {
    final now = DateTime.now().toUtc();
    final nowStr = now.toIso8601String();

    if (kIsWeb) {
      final existing = _webIncidents[incidentId];
      if (existing != null) {
        _webIncidents[incidentId] = existing.copyWith(
          localState: IncidentDeliveryState.cancelled,
          lastServerUpdateUtc: now,
        );
      }
      for (final key in _webOutbox.keys) {
        if (_webOutbox[key]?.incidentId == incidentId) {
          final old = _webOutbox[key]!;
          _webOutbox[key] = OutboxRecord(
            outboxId: old.outboxId,
            incidentId: old.incidentId,
            payloadVersion: old.payloadVersion,
            idempotencyKey: old.idempotencyKey,
            state: 'cancelled',
            attemptCount: old.attemptCount,
            transport: old.transport,
          );
        }
      }
      _webEvents.add(
        IncidentEventRecord(
          eventId: 'EVT-CANCEL-${now.millisecondsSinceEpoch}',
          incidentId: incidentId,
          eventType: 'CANCELLED_BY_USER',
          occurredAtUtc: now,
          source: 'LOCAL_DEVICE',
          verified: true,
          safeSummary: 'SOS distress request safely cancelled by citizen on this device.',
        ),
      );
      return;
    }

    final db = await database;
    await db!.transaction((txn) async {
      await txn.update(
        'incidents',
        {
          'local_state': IncidentDeliveryState.cancelled.name,
          'last_server_update_utc': nowStr,
        },
        where: 'incident_id = ?',
        whereArgs: [incidentId],
      );
      await txn.update(
        'outbox',
        {'state': 'cancelled'},
        where: 'incident_id = ?',
        whereArgs: [incidentId],
      );
      await txn.insert(
        'incident_events',
        IncidentEventRecord(
          eventId: 'EVT-CANCEL-${now.millisecondsSinceEpoch}',
          incidentId: incidentId,
          eventType: 'CANCELLED_BY_USER',
          occurredAtUtc: now,
          source: 'LOCAL_DEVICE',
          verified: true,
          safeSummary: 'SOS distress request safely cancelled by citizen on this device.',
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> logIncidentEvent(IncidentEventRecord event) async {
    if (kIsWeb) {
      _webEvents.add(event);
      return;
    }

    final db = await database;
    await db!.insert(
      'incident_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<IncidentEventRecord>> getEventsForIncident(String incidentId) async {
    if (kIsWeb) {
      final filtered = _webEvents.where((e) => e.incidentId == incidentId).toList();
      filtered.sort((a, b) => a.occurredAtUtc.compareTo(b.occurredAtUtc));
      return filtered;
    }

    final db = await database;
    final results = await db!.query(
      'incident_events',
      where: 'incident_id = ?',
      whereArgs: [incidentId],
      orderBy: 'occurred_at_utc ASC',
    );
    return results.map((m) => IncidentEventRecord.fromMap(m)).toList();
  }

  /// Claim eligible outbox records using lease lock (FR-03)
  Future<List<OutboxRecord>> claimPendingOutboxRecords({
    required Duration leaseDuration,
    int limit = 5,
  }) async {
    final now = DateTime.now().toUtc();
    final leaseExpiry = now.add(leaseDuration);

    if (kIsWeb) {
      final claimed = <OutboxRecord>[];
      for (final record in _webOutbox.values) {
        if (claimed.length >= limit) break;
        if (record.state == 'queued' ||
            (record.state == 'leased' &&
                record.leaseUntilUtc != null &&
                record.leaseUntilUtc!.isBefore(now))) {
          final updated = OutboxRecord(
            outboxId: record.outboxId,
            incidentId: record.incidentId,
            payloadVersion: record.payloadVersion,
            idempotencyKey: record.idempotencyKey,
            state: 'leased',
            attemptCount: record.attemptCount,
            nextAttemptAtUtc: record.nextAttemptAtUtc,
            lastAttemptAtUtc: record.lastAttemptAtUtc,
            lastErrorCode: record.lastErrorCode,
            leaseUntilUtc: leaseExpiry,
            transport: record.transport,
          );
          _webOutbox[record.outboxId] = updated;
          claimed.add(updated);
        }
      }
      return claimed;
    }

    final db = await database;
    return await db!.transaction((txn) async {
      final rows = await txn.rawQuery('''
        SELECT * FROM outbox
        WHERE state = 'queued'
           OR (state = 'leased' AND lease_until_utc IS NOT NULL AND lease_until_utc < ?)
        ORDER BY attempt_count ASC
        LIMIT ?
      ''', [now.toIso8601String(), limit]);

      final claimed = <OutboxRecord>[];
      for (final row in rows) {
        final record = OutboxRecord.fromMap(row);
        await txn.update(
          'outbox',
          {
            'state': 'leased',
            'lease_until_utc': leaseExpiry.toIso8601String(),
          },
          where: 'outbox_id = ?',
          whereArgs: [record.outboxId],
        );
        claimed.add(record);
      }
      return claimed;
    });
  }

  Future<void> markOutboxSent({
    required String outboxId,
    required String incidentId,
  }) async {
    final now = DateTime.now().toUtc();

    if (kIsWeb) {
      final record = _webOutbox[outboxId];
      if (record != null) {
        _webOutbox[outboxId] = OutboxRecord(
          outboxId: record.outboxId,
          incidentId: record.incidentId,
          payloadVersion: record.payloadVersion,
          idempotencyKey: record.idempotencyKey,
          state: 'sent',
          attemptCount: record.attemptCount,
          lastAttemptAtUtc: now,
          transport: record.transport,
        );
      }
      final incident = _webIncidents[incidentId];
      if (incident != null) {
        _webIncidents[incidentId] = incident.copyWith(
          localState: IncidentDeliveryState.serverReceived,
          serverState: 'ACKNOWLEDGED',
          lastServerUpdateUtc: now,
        );
      }
      return;
    }

    final db = await database;
    final nowStr = now.toIso8601String();
    await db!.transaction((txn) async {
      await txn.update(
        'outbox',
        {
          'state': 'sent',
          'last_attempt_at_utc': nowStr,
          'lease_until_utc': null,
        },
        where: 'outbox_id = ?',
        whereArgs: [outboxId],
      );
      await txn.update(
        'incidents',
        {
          'local_state': IncidentDeliveryState.serverReceived.name,
          'server_state': 'ACKNOWLEDGED',
          'last_server_update_utc': nowStr,
        },
        where: 'incident_id = ?',
        whereArgs: [incidentId],
      );
    });
  }

  Future<void> markOutboxRetry({
    required String outboxId,
    required int nextAttemptCount,
    required DateTime nextAttemptUtc,
    required String errorCode,
  }) async {
    final now = DateTime.now().toUtc();

    if (kIsWeb) {
      final record = _webOutbox[outboxId];
      if (record != null) {
        _webOutbox[outboxId] = OutboxRecord(
          outboxId: record.outboxId,
          incidentId: record.incidentId,
          payloadVersion: record.payloadVersion,
          idempotencyKey: record.idempotencyKey,
          state: 'queued',
          attemptCount: nextAttemptCount,
          nextAttemptAtUtc: nextAttemptUtc,
          lastAttemptAtUtc: now,
          lastErrorCode: errorCode,
          transport: record.transport,
        );
      }
      return;
    }

    final db = await database;
    await db!.update(
      'outbox',
      {
        'state': 'queued',
        'attempt_count': nextAttemptCount,
        'next_attempt_at_utc': nextAttemptUtc.toIso8601String(),
        'last_attempt_at_utc': now.toIso8601String(),
        'last_error_code': errorCode,
        'lease_until_utc': null,
      },
      where: 'outbox_id = ?',
      whereArgs: [outboxId],
    );
  }

  // Places caching
  Future<void> upsertCachedPlaces(List<CachedPlaceRecord> places) async {
    if (kIsWeb) {
      for (final p in places) {
        _webPlaces[p.placeId] = p;
      }
      return;
    }

    final db = await database;
    final batch = db!.batch();
    for (final p in places) {
      batch.insert(
        'cached_places',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CachedPlaceRecord>> getCachedPlaces({String? category}) async {
    if (kIsWeb) {
      if (category != null && category.isNotEmpty) {
        return _webPlaces.values.where((p) => p.category == category).toList();
      }
      return _webPlaces.values.toList();
    }

    final db = await database;
    final List<Map<String, dynamic>> results;
    if (category != null && category.isNotEmpty) {
      results = await db!.query(
        'cached_places',
        where: 'category = ?',
        whereArgs: [category],
      );
    } else {
      results = await db!.query('cached_places');
    }
    return results.map((m) => CachedPlaceRecord.fromMap(m)).toList();
  }
}
