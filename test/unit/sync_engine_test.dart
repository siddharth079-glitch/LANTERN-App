import 'package:flutter_test/flutter_test.dart';
import 'package:lantern/core/sync/outbox_sync_engine.dart';
import 'package:lantern/features/sos/domain/models.dart';
import 'package:lantern/shared/widgets/status_chip.dart';

void main() {
  group('OutboxSyncEngine Logic Tests', () {
    test('computes exponential backoff with upper bound and jitter', () {
      final engine = OutboxSyncEngine();

      final attempt1Time = engine.computeNextAttempt(attemptCount: 1);
      final attempt2Time = engine.computeNextAttempt(attemptCount: 2);
      final attempt6Time = engine.computeNextAttempt(attemptCount: 6);

      final now = DateTime.now().toUtc();
      // Attempt 1 should be roughly 4-15 seconds in future
      expect(attempt1Time.isAfter(now), isTrue);
      expect(attempt2Time.isAfter(now), isTrue);
      // Attempt 6 backoff should be greater than Attempt 1
      expect(attempt6Time.isAfter(attempt1Time), isTrue);
      // Maximum bound check: should never exceed 360 seconds (6 minutes)
      expect(
        attempt6Time.difference(now).inSeconds,
        lessThanOrEqualTo(360),
      );
    });

    test('HttpIncidentTransport handles simulation modes properly', () async {
      const liveTransport = HttpIncidentTransport(
        simulateOffline: false,
        simulateSuccess: true,
        networkLatency: Duration(milliseconds: 10),
      );

      final incident = IncidentModel(
        incidentId: 'inc-999-uuid',
        category: IncidentCategory.medical,
        createdAtUtc: DateTime.now().toUtc(),
        localState: IncidentDeliveryState.queuedLocal,
      );

      final result = await liveTransport.sendIncident(
        incident: incident,
        idempotencyKey: 'inc-999-uuid',
      );

      expect(result.isSuccess, isTrue);
      expect(result.receiptId, startsWith('LNT-ACK-'));
      expect(result.canonicalStatus, 'SERVER_RECEIVED');
    });

    test('HttpIncidentTransport reports retryable failure on offline simulation', () async {
      const offlineTransport = HttpIncidentTransport(
        simulateOffline: true,
        simulateSuccess: true,
        networkLatency: Duration(milliseconds: 10),
      );

      final incident = IncidentModel(
        incidentId: 'inc-888-uuid',
        category: IncidentCategory.fire,
        createdAtUtc: DateTime.now().toUtc(),
        localState: IncidentDeliveryState.queuedLocal,
      );

      final result = await offlineTransport.sendIncident(
        incident: incident,
        idempotencyKey: 'inc-888-uuid',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isRetryable, isTrue);
      expect(result.errorCode, 'ERR_NO_ROUTE_TO_HOST');
    });
  });
}
