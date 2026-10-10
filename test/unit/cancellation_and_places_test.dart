import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lantern/core/database/database_helper.dart';
import 'package:lantern/core/sync/outbox_sync_engine.dart';
import 'package:lantern/features/map/data/places_repository.dart';
import 'package:lantern/features/sos/domain/models.dart';
import 'package:lantern/shared/widgets/status_chip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Incident Cancellation & Database Invariants', () {
    test('cancelIncident transitions local state and records event', () async {
      final db = DatabaseHelper.instance;
      final nowUtc = DateTime.now().toUtc();
      final testId = 'TEST-CANCEL-${DateTime.now().microsecondsSinceEpoch}';

      final incident = IncidentModel(
        incidentId: testId,
        category: IncidentCategory.fire,
        createdAtUtc: nowUtc,
        localState: IncidentDeliveryState.queuedLocal,
      );

      final outbox = OutboxRecord(
        outboxId: 'OUTBOX-${DateTime.now().microsecondsSinceEpoch}',
        incidentId: testId,
        payloadVersion: 1,
        idempotencyKey: testId,
        state: 'queued',
        attemptCount: 0,
      );

      final initialEvent = IncidentEventRecord(
        eventId: 'EVT-${DateTime.now().microsecondsSinceEpoch}',
        incidentId: testId,
        eventType: 'SAVED_LOCAL_FIRST',
        occurredAtUtc: nowUtc,
        source: 'LOCAL_DEVICE',
        verified: true,
        safeSummary: 'Saved locally for unit test',
      );

      final created = await db.createIncidentTransactional(
        incident: incident,
        outbox: outbox,
        initialEvent: initialEvent,
      );
      expect(created, isTrue);

      // Cancel the incident
      await db.cancelIncident(testId);

      final fetched = await db.getIncidentById(testId);
      expect(fetched, isNotNull);
      expect(fetched!.localState, equals(IncidentDeliveryState.cancelled));

      final events = await db.getEventsForIncident(testId);
      expect(events.any((e) => e.eventType == 'CANCELLED_BY_USER'), isTrue);
    });

    test('IncidentDeliveryState contains cancelled with proper labels', () {
      const state = IncidentDeliveryState.cancelled;
      expect(state.label, equals('Cancelled'));
      expect(state.descriptiveStatus, contains('cancelled by citizen'));
    });
  });

  group('OutboxSyncEngine Stream & Events', () {
    test('onSyncEvent broadcasts during transmission', () async {
      final syncEngine = OutboxSyncEngine(
        transport: const HttpIncidentTransport(
          simulateOffline: false,
          simulateSuccess: true,
          networkLatency: Duration(milliseconds: 50),
        ),
      );

      final emittedEvents = <String>[];
      final sub = syncEngine.onSyncEvent.listen(emittedEvents.add);

      await syncEngine.triggerSyncCycle();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(emittedEvents.contains('SYNC_CYCLE_FINISHED'), isTrue);
      await sub.cancel();
      syncEngine.dispose();
    });
  });

  group('PlacesRepository & Emergency Relief Facilities', () {
    test('loads default places and supports category filtering', () async {
      final repo = PlacesRepository();
      await repo.seedDefaultPlacesIfEmpty();

      final allPlaces = await repo.getPlaces();
      expect(allPlaces.length, greaterThanOrEqualTo(5));

      final shelters = await repo.getPlaces(category: 'shelter');
      expect(shelters.every((p) => p.category == 'shelter'), isTrue);
      expect(shelters.length, greaterThanOrEqualTo(2));

      final hospitals = await repo.getPlaces(category: 'hospital');
      expect(hospitals.every((p) => p.category == 'hospital'), isTrue);
    });
  });
}
