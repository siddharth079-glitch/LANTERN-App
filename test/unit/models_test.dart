import 'package:flutter_test/flutter_test.dart';
import 'package:lantern/features/sos/domain/models.dart';
import 'package:lantern/shared/widgets/status_chip.dart';

void main() {
  group('IncidentModel Serialization & Invariants', () {
    test('serializes and deserializes correctly with explicit location', () {
      final now = DateTime.utc(2026, 10, 9, 12, 30, 0);
      final incident = IncidentModel(
        incidentId: 'test-uuid-001',
        category: IncidentCategory.flood,
        createdAtUtc: now,
        latitude: 17.3850,
        longitude: 78.4867,
        locationAccuracyM: 4.2,
        locationCapturedAtUtc: now,
        peopleAffected: 3,
        description: 'Rising water on ground floor.',
        localState: IncidentDeliveryState.queuedLocal,
      );

      final map = incident.toMap();
      expect(map['incident_id'], 'test-uuid-001');
      expect(map['incident_type'], 'flood');
      expect(map['latitude'], 17.3850);
      expect(map['longitude'], 78.4867);
      expect(map['location_accuracy_m'], 4.2);
      expect(map['people_affected'], 3);
      expect(map['local_state'], 'queuedLocal');

      final deserialized = IncidentModel.fromMap(map);
      expect(deserialized.incidentId, incident.incidentId);
      expect(deserialized.category, IncidentCategory.flood);
      expect(deserialized.latitude, 17.3850);
      expect(deserialized.longitude, 78.4867);
      expect(deserialized.peopleAffected, 3);
      expect(deserialized.localState, IncidentDeliveryState.queuedLocal);
    });

    test('preserves explicit null location when GPS is unavailable', () {
      final now = DateTime.utc(2026, 10, 9, 12, 30, 0);
      final incident = IncidentModel(
        incidentId: 'test-uuid-no-loc',
        category: IncidentCategory.earthquake,
        createdAtUtc: now,
        latitude: null,
        longitude: null,
        locationAccuracyM: null,
        peopleAffected: 1,
        localState: IncidentDeliveryState.queuedLocal,
      );

      expect(incident.hasLocation, isFalse);
      final map = incident.toMap();
      expect(map['latitude'], isNull);
      expect(map['longitude'], isNull);

      final deserialized = IncidentModel.fromMap(map);
      expect(deserialized.hasLocation, isFalse);
      expect(deserialized.latitude, isNull);
    });
  });

  group('OutboxRecord Serialization', () {
    test('preserves idempotency key and transport fields', () {
      final now = DateTime.utc(2026, 10, 9, 12, 35, 0);
      final outbox = OutboxRecord(
        outboxId: 'outbox-001',
        incidentId: 'incident-001',
        payloadVersion: 1,
        idempotencyKey: 'idem-key-abc',
        state: 'queued',
        attemptCount: 2,
        nextAttemptAtUtc: now,
        transport: 'HTTPS',
      );

      final map = outbox.toMap();
      expect(map['idempotency_key'], 'idem-key-abc');
      expect(map['attempt_count'], 2);
      expect(map['transport'], 'HTTPS');

      final restored = OutboxRecord.fromMap(map);
      expect(restored.idempotencyKey, 'idem-key-abc');
      expect(restored.attemptCount, 2);
      expect(restored.state, 'queued');
    });
  });
}
