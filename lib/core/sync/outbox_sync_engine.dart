import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/sos/domain/models.dart';
import '../../shared/widgets/status_chip.dart';
import '../database/database_helper.dart';

class TransportResult {
  final bool isSuccess;
  final String? receiptId;
  final String? canonicalStatus;
  final String? errorCode;
  final String? errorMessage;
  final bool isRetryable;

  const TransportResult.success({
    required this.receiptId,
    this.canonicalStatus = 'SERVER_RECEIVED',
  })  : isSuccess = true,
        errorCode = null,
        errorMessage = null,
        isRetryable = false;

  const TransportResult.failure({
    required this.errorCode,
    required this.errorMessage,
    this.isRetryable = true,
  })  : isSuccess = false,
        receiptId = null,
        canonicalStatus = null;
}

abstract class IncidentTransport {
  Future<TransportResult> sendIncident({
    required IncidentModel incident,
    required String idempotencyKey,
  });

  Future<List<Map<String, dynamic>>> fetchServerIncidents();
}

/// Production Live HTTP / REST Transport using Dio
class LiveHttpIncidentTransport implements IncidentTransport {
  final Dio _dio;
  String baseUrl;

  LiveHttpIncidentTransport({
    Dio? dio,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? _getDefaultBaseUrl(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 6),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  static String _getDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    // On Android devices, 10.0.2.2 points to host loopback for emulators,
    // and physical phones connect to LAN host IP 192.168.137.62:3000.
    return 'http://192.168.137.62:3000';
  }

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }

  @override
  Future<TransportResult> sendIncident({
    required IncidentModel incident,
    required String idempotencyKey,
  }) async {
    try {
      final events = await DatabaseHelper.instance.getEventsForIncident(incident.incidentId);
      final relayEvent = events.cast<IncidentEventRecord?>().firstWhere(
        (e) => e?.eventType == 'PEER_RELAY_RECEIVED',
        orElse: () => null,
      );

      final payload = <String, dynamic>{
        'clientIncidentId': incident.incidentId,
        'idempotencyKey': idempotencyKey,
        'emergencyType': incident.category.key,
        'severity': incident.peopleAffected > 2 ? 'CRITICAL' : 'HIGH',
        'description': incident.description,
        'latitude': incident.latitude,
        'longitude': incident.longitude,
        'accuracy': incident.locationAccuracyM,
      };

      if (relayEvent != null) {
        payload['isRelayed'] = true;
        payload['relayedBy'] = relayEvent.source.replaceFirst('PEER_', '');
        payload['relaySummary'] = relayEvent.safeSummary;
      }

      final response = await _dio.post(
        '$baseUrl/v1/incidents',
        data: payload,
        options: Options(
          headers: {
            'Idempotency-Key': idempotencyKey,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final receipt = data['receipt_id']?.toString() ?? 'LNT-ACK-${incident.incidentId}';
        final status = data['canonicalStatus']?.toString() ?? 'SERVER_RECEIVED';

        return TransportResult.success(
          receiptId: receipt,
          canonicalStatus: status,
        );
      }

      return TransportResult.failure(
        errorCode: 'ERR_HTTP_${response.statusCode}',
        errorMessage: 'Server responded with status code ${response.statusCode}',
        isRetryable: (response.statusCode ?? 500) >= 500,
      );
    } on DioException catch (e) {
      final isConnectionIssue = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;

      return TransportResult.failure(
        errorCode: e.type.name,
        errorMessage: isConnectionIssue
            ? 'Gateway unreachable. Stored in encrypted offline outbox for automatic sync.'
            : (e.message ?? 'Network transport error'),
        isRetryable: true,
      );
    } catch (e) {
      return TransportResult.failure(
        errorCode: 'ERR_UNKNOWN_TRANSPORT',
        errorMessage: e.toString(),
        isRetryable: true,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchServerIncidents() async {
    try {
      final response = await _dio.get('$baseUrl/v1/incidents');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['incidents'] ?? [];
        return raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }
}

/// Simulated Staging / Live Transport fallback
class HttpIncidentTransport implements IncidentTransport {
  final bool simulateOffline;
  final bool simulateSuccess;
  final Duration networkLatency;

  const HttpIncidentTransport({
    this.simulateOffline = false,
    this.simulateSuccess = true,
    this.networkLatency = const Duration(milliseconds: 600),
  });

  @override
  Future<TransportResult> sendIncident({
    required IncidentModel incident,
    required String idempotencyKey,
  }) async {
    await Future.delayed(networkLatency);

    if (simulateOffline) {
      return const TransportResult.failure(
        errorCode: 'ERR_NO_ROUTE_TO_HOST',
        errorMessage: 'Network packet dropped: No internet or radio path to LANTERN gateway.',
        isRetryable: true,
      );
    }

    if (!simulateSuccess) {
      return const TransportResult.failure(
        errorCode: 'ERR_SERVER_BUSY_503',
        errorMessage: 'LANTERN gateway high load (503). Retrying with exponential backoff.',
        isRetryable: true,
      );
    }

    final generatedReceipt = 'LNT-ACK-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}-${incident.incidentId.substring(0, min(6, incident.incidentId.length))}';

    return TransportResult.success(
      receiptId: generatedReceipt,
      canonicalStatus: 'SERVER_RECEIVED',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchServerIncidents() async => [];
}

class OutboxSyncEngine {
  final DatabaseHelper _db;
  IncidentTransport _transport;
  final Random _random = Random();
  bool _isSyncing = false;
  StreamSubscription? _connectivitySub;
  final StreamController<String> _eventController = StreamController<String>.broadcast();
  Timer? _periodicSyncTimer;

  Future<bool> Function({
    required IncidentModel incident,
    required String idempotencyKey,
  })? onFallbackPeerRelay;

  Stream<String> get onSyncEvent => _eventController.stream;
  IncidentTransport get transport => _transport;

  OutboxSyncEngine({
    DatabaseHelper? db,
    IncidentTransport? transport,
    bool autoStartPeriodicSync = false,
  })  : _db = db ?? DatabaseHelper.instance,
        _transport = transport ?? LiveHttpIncidentTransport() {
    if (autoStartPeriodicSync) {
      startPeriodicSync();
    }
  }

  void startPeriodicSync([Duration interval = const Duration(seconds: 10)]) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(interval, (_) {
      syncServerStatusUpdates();
    });
  }

  void setTransport(IncidentTransport transport) {
    _transport = transport;
  }

  void startListening(Connectivity connectivity) {
    _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        triggerSyncCycle();
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicSyncTimer?.cancel();
    _eventController.close();
  }

  /// Calculates bounded exponential backoff with randomized jitter
  DateTime computeNextAttempt({required int attemptCount}) {
    final baseSeconds = 5;
    final maxSeconds = 300;
    final expBackoff = min(maxSeconds, baseSeconds * pow(2, min(attemptCount, 6)).toInt());
    final jitter = (expBackoff * 0.2 * (_random.nextDouble() * 2 - 1)).round();
    final totalSeconds = max(3, expBackoff + jitter);
    return DateTime.now().toUtc().add(Duration(seconds: totalSeconds));
  }

  /// Synchronizes upstream outbox to server
  Future<void> triggerSyncCycle() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final records = await _db.claimPendingOutboxRecords(
        leaseDuration: const Duration(seconds: 60),
        limit: 5,
      );

      for (final record in records) {
        if (record.state == 'cancelled') continue;
        final incident = await _db.getIncidentById(record.incidentId);
        if (incident == null || incident.localState == IncidentDeliveryState.cancelled) continue;

        await _db.updateIncidentState(
          incidentId: incident.incidentId,
          localState: IncidentDeliveryState.sending,
        );
        _eventController.add(record.incidentId);

        final result = await _transport.sendIncident(
          incident: incident,
          idempotencyKey: record.idempotencyKey,
        );

        if (result.isSuccess) {
          await _db.markOutboxSent(
            outboxId: record.outboxId,
            incidentId: record.incidentId,
          );

          await _db.logIncidentEvent(
            IncidentEventRecord(
              eventId: 'EVT-${DateTime.now().millisecondsSinceEpoch}-${record.incidentId.substring(0, min(4, record.incidentId.length))}',
              incidentId: record.incidentId,
              eventType: 'SERVER_ACK_RECEIVED',
              occurredAtUtc: DateTime.now().toUtc(),
              source: 'LANTERN_GATEWAY',
              verified: true,
              safeSummary: 'Distress beacon received and logged by server. Receipt: ${result.receiptId}',
            ),
          );
          _eventController.add(record.incidentId);
        } else {
          final newAttempt = record.attemptCount + 1;
          final nextTime = computeNextAttempt(attemptCount: newAttempt);

          await _db.markOutboxRetry(
            outboxId: record.outboxId,
            nextAttemptCount: newAttempt,
            nextAttemptUtc: nextTime,
            errorCode: result.errorCode ?? 'UNKNOWN_ERROR',
          );

          final newState = newAttempt >= 5
              ? IncidentDeliveryState.deliveryFailed
              : IncidentDeliveryState.queuedLocal;

          await _db.updateIncidentState(
            incidentId: incident.incidentId,
            localState: newState,
          );

          await _db.logIncidentEvent(
            IncidentEventRecord(
              eventId: 'EVT-FAIL-${DateTime.now().millisecondsSinceEpoch}',
              incidentId: record.incidentId,
              eventType: 'TRANSMISSION_FAILED',
              occurredAtUtc: DateTime.now().toUtc(),
              source: 'LOCAL_OUTBOX',
              verified: false,
              safeSummary: 'Attempt $newAttempt failed: ${result.errorMessage}. Retrying at ${nextTime.toLocal().toString().split('.').first}.',
            ),
          );

          if (onFallbackPeerRelay != null) {
            try {
              final relayed = await onFallbackPeerRelay!(
                incident: incident,
                idempotencyKey: record.idempotencyKey,
              );
              if (relayed) {
                debugPrint('[OutboxSync] Transferred offline SOS ${incident.incidentId} to nearby peer radio device.');
              }
            } catch (e) {
              debugPrint('[OutboxSync] Peer relay attempt error: $e');
            }
          }

          _eventController.add(record.incidentId);
        }
      }

      // Also pull down any status updates from server
      await syncServerStatusUpdates();
    } finally {
      _isSyncing = false;
      _eventController.add('SYNC_CYCLE_FINISHED');
    }
  }

  /// Bidirectional sync: pulls down status changes made by rescue dashboard (ACK, ASSIGNED, RESOLVED)
  Future<void> syncServerStatusUpdates() async {
    try {
      final serverIncidents = await _transport.fetchServerIncidents();
      if (serverIncidents.isEmpty) return;

      for (final sInc in serverIncidents) {
        final clientIncId = sInc['client_incident_id']?.toString() ?? sInc['incident_id']?.toString();
        if (clientIncId == null) continue;

        final local = await _db.getIncidentById(clientIncId);
        if (local == null || local.localState == IncidentDeliveryState.cancelled) continue;

        final serverStatus = sInc['status']?.toString();
        IncidentDeliveryState? targetState;

        if (serverStatus == 'SERVER_RECEIVED') {
          targetState = IncidentDeliveryState.serverReceived;
        } else if (serverStatus == 'ACKNOWLEDGED') {
          targetState = IncidentDeliveryState.acknowledged;
        } else if (serverStatus == 'ASSIGNED') {
          targetState = IncidentDeliveryState.responderAssigned;
        } else if (serverStatus == 'RESOLVED') {
          targetState = IncidentDeliveryState.resolved;
        }

        if (targetState != null && local.localState != targetState) {
          await _db.updateIncidentState(
            incidentId: local.incidentId,
            localState: targetState,
          );

          final responderName = sInc['responder_name']?.toString();
          final vehicleId = sInc['vehicle_id']?.toString();
          final detailSummary = responderName != null && responderName.isNotEmpty
              ? 'Rescue Unit Dispatched: $responderName ($vehicleId)'
              : 'Status updated by Command Center to $serverStatus';

          await _db.logIncidentEvent(
            IncidentEventRecord(
              eventId: 'EVT-SERVER-UPDATE-${DateTime.now().millisecondsSinceEpoch}',
              incidentId: local.incidentId,
              eventType: serverStatus ?? 'STATUS_CHANGE',
              occurredAtUtc: DateTime.now().toUtc(),
              source: 'COMMAND_CENTER',
              verified: true,
              safeSummary: detailSummary,
            ),
          );

          _eventController.add(local.incidentId);
        }
      }
    } catch (_) {}
  }
}
