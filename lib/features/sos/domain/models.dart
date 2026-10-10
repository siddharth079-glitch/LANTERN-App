import '../../../shared/widgets/status_chip.dart';

enum IncidentCategory {
  flood('Flood / Rising Water', 'flood'),
  trapped('Trapped / Structural Collapse', 'trapped'),
  medical('Medical Emergency', 'medical'),
  fire('Fire / Hazmat', 'fire'),
  earthquake('Earthquake Damage', 'earthquake'),
  injury('Critical Injury / Trauma', 'injury'),
  missingPerson('Missing Person', 'missing_person'),
  infrastructureHazard('Power / Infrastructure Failure', 'infrastructure_hazard'),
  other('Other Emergency', 'other');

  final String displayName;
  final String key;
  const IncidentCategory(this.displayName, this.key);

  static IncidentCategory fromKey(String key) {
    return IncidentCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => IncidentCategory.other,
    );
  }
}

class IncidentModel {
  final String incidentId;
  final IncidentCategory category;
  final DateTime createdAtUtc;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracyM;
  final DateTime? locationCapturedAtUtc;
  final int peopleAffected;
  final String? description;
  final IncidentDeliveryState localState;
  final String? serverState;
  final DateTime? lastServerUpdateUtc;

  IncidentModel({
    required this.incidentId,
    required this.category,
    required this.createdAtUtc,
    this.latitude,
    this.longitude,
    this.locationAccuracyM,
    this.locationCapturedAtUtc,
    this.peopleAffected = 1,
    this.description,
    this.localState = IncidentDeliveryState.queuedLocal,
    this.serverState,
    this.lastServerUpdateUtc,
  });

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toMap() {
    return {
      'incident_id': incidentId,
      'incident_type': category.key,
      'created_at_utc': createdAtUtc.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy_m': locationAccuracyM,
      'location_captured_at_utc': locationCapturedAtUtc?.toIso8601String(),
      'people_affected': peopleAffected,
      'description_encrypted_or_minimized': description,
      'local_state': localState.name,
      'server_state': serverState,
      'last_server_update_utc': lastServerUpdateUtc?.toIso8601String(),
    };
  }

  factory IncidentModel.fromMap(Map<String, dynamic> map) {
    return IncidentModel(
      incidentId: map['incident_id'] as String,
      category: IncidentCategory.fromKey(map['incident_type'] as String? ?? 'other'),
      createdAtUtc: DateTime.parse(map['created_at_utc'] as String),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationAccuracyM: (map['location_accuracy_m'] as num?)?.toDouble(),
      locationCapturedAtUtc: map['location_captured_at_utc'] != null
          ? DateTime.tryParse(map['location_captured_at_utc'] as String)
          : null,
      peopleAffected: (map['people_affected'] as int?) ?? 1,
      description: map['description_encrypted_or_minimized'] as String?,
      localState: IncidentDeliveryState.values.firstWhere(
        (s) => s.name == map['local_state'],
        orElse: () => IncidentDeliveryState.queuedLocal,
      ),
      serverState: map['server_state'] as String?,
      lastServerUpdateUtc: map['last_server_update_utc'] != null
          ? DateTime.tryParse(map['last_server_update_utc'] as String)
          : null,
    );
  }

  IncidentModel copyWith({
    IncidentDeliveryState? localState,
    String? serverState,
    DateTime? lastServerUpdateUtc,
  }) {
    return IncidentModel(
      incidentId: incidentId,
      category: category,
      createdAtUtc: createdAtUtc,
      latitude: latitude,
      longitude: longitude,
      locationAccuracyM: locationAccuracyM,
      locationCapturedAtUtc: locationCapturedAtUtc,
      peopleAffected: peopleAffected,
      description: description,
      localState: localState ?? this.localState,
      serverState: serverState ?? this.serverState,
      lastServerUpdateUtc: lastServerUpdateUtc ?? this.lastServerUpdateUtc,
    );
  }
}

class OutboxRecord {
  final String outboxId;
  final String incidentId;
  final int payloadVersion;
  final String idempotencyKey;
  final String state; // 'queued', 'leased', 'sent', 'failed'
  final int attemptCount;
  final DateTime? nextAttemptAtUtc;
  final DateTime? lastAttemptAtUtc;
  final String? lastErrorCode;
  final DateTime? leaseUntilUtc;
  final String? transport;

  OutboxRecord({
    required this.outboxId,
    required this.incidentId,
    this.payloadVersion = 1,
    required this.idempotencyKey,
    this.state = 'queued',
    this.attemptCount = 0,
    this.nextAttemptAtUtc,
    this.lastAttemptAtUtc,
    this.lastErrorCode,
    this.leaseUntilUtc,
    this.transport = 'HTTPS',
  });

  Map<String, dynamic> toMap() {
    return {
      'outbox_id': outboxId,
      'incident_id': incidentId,
      'payload_version': payloadVersion,
      'idempotency_key': idempotencyKey,
      'state': state,
      'attempt_count': attemptCount,
      'next_attempt_at_utc': nextAttemptAtUtc?.toIso8601String(),
      'last_attempt_at_utc': lastAttemptAtUtc?.toIso8601String(),
      'last_error_code': lastErrorCode,
      'lease_until_utc': leaseUntilUtc?.toIso8601String(),
      'transport': transport,
    };
  }

  factory OutboxRecord.fromMap(Map<String, dynamic> map) {
    return OutboxRecord(
      outboxId: map['outbox_id'] as String,
      incidentId: map['incident_id'] as String,
      payloadVersion: (map['payload_version'] as int?) ?? 1,
      idempotencyKey: map['idempotency_key'] as String,
      state: map['state'] as String? ?? 'queued',
      attemptCount: (map['attempt_count'] as int?) ?? 0,
      nextAttemptAtUtc: map['next_attempt_at_utc'] != null
          ? DateTime.tryParse(map['next_attempt_at_utc'] as String)
          : null,
      lastAttemptAtUtc: map['last_attempt_at_utc'] != null
          ? DateTime.tryParse(map['last_attempt_at_utc'] as String)
          : null,
      lastErrorCode: map['last_error_code'] as String?,
      leaseUntilUtc: map['lease_until_utc'] != null
          ? DateTime.tryParse(map['lease_until_utc'] as String)
          : null,
      transport: map['transport'] as String?,
    );
  }
}

class IncidentEventRecord {
  final String eventId;
  final String incidentId;
  final String eventType;
  final DateTime occurredAtUtc;
  final String source;
  final bool verified;
  final String safeSummary;
  final int? serverSequence;

  IncidentEventRecord({
    required this.eventId,
    required this.incidentId,
    required this.eventType,
    required this.occurredAtUtc,
    required this.source,
    required this.verified,
    required this.safeSummary,
    this.serverSequence,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'incident_id': incidentId,
      'event_type': eventType,
      'occurred_at_utc': occurredAtUtc.toIso8601String(),
      'source': source,
      'verified': verified ? 1 : 0,
      'safe_summary': safeSummary,
      'server_sequence': serverSequence,
    };
  }

  factory IncidentEventRecord.fromMap(Map<String, dynamic> map) {
    return IncidentEventRecord(
      eventId: map['event_id'] as String,
      incidentId: map['incident_id'] as String,
      eventType: map['event_type'] as String,
      occurredAtUtc: DateTime.parse(map['occurred_at_utc'] as String),
      source: map['source'] as String,
      verified: (map['verified'] as int? ?? 0) == 1,
      safeSummary: map['safe_summary'] as String,
      serverSequence: map['server_sequence'] as int?,
    );
  }
}

class CachedPlaceRecord {
  final String placeId;
  final String category; // 'shelter', 'hospital', 'fire_station', 'evacuation_point', 'hazard'
  final String name;
  final double latitude;
  final double longitude;
  final String source;
  final DateTime updatedAtUtc;
  final String? availabilityStatus; // 'Open - 42 spots available', 'Operational', etc.
  final String? metadataJson;

  CachedPlaceRecord({
    required this.placeId,
    required this.category,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.source,
    required this.updatedAtUtc,
    this.availabilityStatus,
    this.metadataJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'place_id': placeId,
      'category': category,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'source': source,
      'updated_at_utc': updatedAtUtc.toIso8601String(),
      'availability_status': availabilityStatus,
      'metadata_json': metadataJson,
    };
  }

  factory CachedPlaceRecord.fromMap(Map<String, dynamic> map) {
    return CachedPlaceRecord(
      placeId: map['place_id'] as String,
      category: map['category'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      source: map['source'] as String,
      updatedAtUtc: DateTime.parse(map['updated_at_utc'] as String),
      availabilityStatus: map['availability_status'] as String?,
      metadataJson: map['metadata_json'] as String?,
    );
  }
}
