import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/sos/domain/models.dart';
import '../../shared/widgets/status_chip.dart';
import '../database/database_helper.dart';
import '../sync/outbox_sync_engine.dart';

class PeerNode {
  final String nodeId;
  final String ipAddress;
  final int port;
  final DateTime lastSeen;

  PeerNode({
    required this.nodeId,
    required this.ipAddress,
    required this.port,
    required this.lastSeen,
  });
}

class RelayPacket {
  final String incidentId;
  final String idempotencyKey;
  final String categoryKey;
  final String createdAtIso;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracyM;
  final int peopleAffected;
  final String? description;
  final String originNodeId;
  final int hopCount;
  final int maxHops;
  final List<String> relayPath;

  RelayPacket({
    required this.incidentId,
    required this.idempotencyKey,
    required this.categoryKey,
    required this.createdAtIso,
    this.latitude,
    this.longitude,
    this.locationAccuracyM,
    this.peopleAffected = 1,
    this.description,
    required this.originNodeId,
    this.hopCount = 0,
    this.maxHops = 3,
    required this.relayPath,
  });

  Map<String, dynamic> toJson() => {
        'incidentId': incidentId,
        'idempotencyKey': idempotencyKey,
        'categoryKey': categoryKey,
        'createdAtIso': createdAtIso,
        'latitude': latitude,
        'longitude': longitude,
        'locationAccuracyM': locationAccuracyM,
        'peopleAffected': peopleAffected,
        'description': description,
        'originNodeId': originNodeId,
        'hopCount': hopCount,
        'maxHops': maxHops,
        'relayPath': relayPath,
      };

  factory RelayPacket.fromJson(Map<String, dynamic> json) => RelayPacket(
        incidentId: json['incidentId'] as String,
        idempotencyKey: json['idempotencyKey'] as String,
        categoryKey: json['categoryKey'] as String? ?? 'other',
        createdAtIso: json['createdAtIso'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locationAccuracyM: (json['locationAccuracyM'] as num?)?.toDouble(),
        peopleAffected: (json['peopleAffected'] as int?) ?? 1,
        description: json['description'] as String?,
        originNodeId: json['originNodeId'] as String? ?? 'UNKNOWN',
        hopCount: (json['hopCount'] as int?) ?? 0,
        maxHops: (json['maxHops'] as int?) ?? 3,
        relayPath: (json['relayPath'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class PeerRelayService {
  static const int tcpPort = 8765;
  static const int udpDiscoveryPort = 8766;

  final DatabaseHelper _db;
  final OutboxSyncEngine syncEngine;

  String _myNodeId = 'NODE-UNKNOWN';
  ServerSocket? _tcpServer;
  RawDatagramSocket? _udpSocket;
  Timer? _beaconTimer;
  Timer? _cleanupTimer;

  final Map<String, PeerNode> _discoveredPeers = {};
  final StreamController<List<PeerNode>> _peersController = StreamController<List<PeerNode>>.broadcast();

  Stream<List<PeerNode>> get peersStream => _peersController.stream;
  List<PeerNode> get activePeers => _discoveredPeers.values.toList();
  String get myNodeId => _myNodeId;

  PeerRelayService({
    DatabaseHelper? db,
    required this.syncEngine,
  }) : _db = db ?? DatabaseHelper.instance;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    var savedId = prefs.getString('lantern_peer_node_id');
    if (savedId == null) {
      savedId = 'NODE-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase().substring(4)}';
      await prefs.setString('lantern_peer_node_id', savedId);
    }
    _myNodeId = savedId;

    if (!kIsWeb) {
      await _startTcpServer();
      await _startUdpDiscovery();
    }
  }

  Future<void> _startTcpServer() async {
    try {
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
      _tcpServer?.listen(_handleIncomingClient, onError: (e) {
        debugPrint('[Relay TCP] Server error: $e');
      });
      debugPrint('[Relay TCP] Listening on 0.0.0.0:$tcpPort (Node: $_myNodeId)');
    } catch (e) {
      debugPrint('[Relay TCP] Failed to bind ServerSocket: $e');
    }
  }

  void _handleIncomingClient(Socket client) {
    StringBuffer buffer = StringBuffer();
    client.listen(
      (data) {
        buffer.write(utf8.decode(data));
      },
      onDone: () async {
        try {
          final payload = jsonDecode(buffer.toString());
          if (payload['type'] == 'OFFLINE_SOS_TRANSFER') {
            final packet = RelayPacket.fromJson(payload['packet']);
            final response = await _processInboundRelay(packet);
            client.write(jsonEncode(response));
            await client.flush();
          }
        } catch (e) {
          debugPrint('[Relay TCP] Error parsing payload: $e');
        } finally {
          client.close();
        }
      },
      onError: (_) => client.close(),
    );
  }

  Future<Map<String, dynamic>> _processInboundRelay(RelayPacket packet) async {
    // 1. Loop Prevention
    if (packet.relayPath.contains(_myNodeId)) {
      return {'status': 'REJECTED_LOOP', 'nodeId': _myNodeId};
    }

    // 2. Hop Limit Enforcement
    if (packet.hopCount >= packet.maxHops) {
      return {'status': 'REJECTED_MAX_HOPS', 'nodeId': _myNodeId};
    }

    // 3. Deduplication Check
    final existing = await _db.getIncidentById(packet.incidentId);
    if (existing != null) {
      return {'status': 'ALREADY_SAVED', 'incidentId': packet.incidentId, 'nodeId': _myNodeId};
    }

    // 4. Save Inbound Relayed SOS into local SQLite
    final incident = IncidentModel(
      incidentId: packet.incidentId,
      category: IncidentCategory.fromKey(packet.categoryKey),
      createdAtUtc: DateTime.tryParse(packet.createdAtIso) ?? DateTime.now().toUtc(),
      latitude: packet.latitude,
      longitude: packet.longitude,
      locationAccuracyM: packet.locationAccuracyM,
      locationCapturedAtUtc: DateTime.now().toUtc(),
      peopleAffected: packet.peopleAffected,
      description: packet.description,
      localState: IncidentDeliveryState.queuedLocal,
    );

    final updatedRelayPath = List<String>.from(packet.relayPath)..add(_myNodeId);
    final hops = packet.hopCount + 1;

    final outboxRecord = OutboxRecord(
      outboxId: 'OBX-RELAY-${DateTime.now().millisecondsSinceEpoch}-${packet.incidentId.substring(0, min(6, packet.incidentId.length))}',
      incidentId: packet.incidentId,
      payloadVersion: 1,
      idempotencyKey: packet.idempotencyKey,
      state: 'queued',
      attemptCount: 0,
    );

    final initialEvent = IncidentEventRecord(
      eventId: 'EVT-RELAY-${DateTime.now().millisecondsSinceEpoch}',
      incidentId: packet.incidentId,
      eventType: 'PEER_RELAY_RECEIVED',
      occurredAtUtc: DateTime.now().toUtc(),
      source: 'PEER_${packet.originNodeId}',
      verified: true,
      safeSummary: 'Received offline SOS beacon via relay hop $hops from ${packet.relayPath.isEmpty ? packet.originNodeId : packet.relayPath.last}. Route: ${updatedRelayPath.join(" -> ")}',
    );

    await _db.createIncidentTransactional(
      incident: incident,
      outbox: outboxRecord,
      initialEvent: initialEvent,
    );

    // 5. Trigger outbox sync if this device has internet access!
    final connectivity = await Connectivity().checkConnectivity();
    final hasNet = connectivity.any((c) => c != ConnectivityResult.none);
    if (hasNet) {
      syncEngine.triggerSyncCycle();
    }

    return {
      'status': 'ACCEPTED',
      'incidentId': packet.incidentId,
      'nodeId': _myNodeId,
      'hopCount': hops,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> _startUdpDiscovery() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpDiscoveryPort, reuseAddress: true);
      _udpSocket?.broadcastEnabled = true;
      _udpSocket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket?.receive();
          if (datagram != null) {
            _handleDiscoveryBeacon(datagram);
          }
        }
      });

      // Broadcast beacon every 4 seconds
      _beaconTimer = Timer.periodic(const Duration(seconds: 4), (_) => _broadcastDiscoveryBeacon());

      // Purge peers not seen for 15 seconds
      _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) => _cleanupStalePeers());
    } catch (e) {
      debugPrint('[Relay UDP] Discovery bind failed: $e');
    }
  }

  void _broadcastDiscoveryBeacon() {
    if (_udpSocket == null) return;
    try {
      final msg = utf8.encode('LANTERN_BEACON:v1:$_myNodeId:$tcpPort:${DateTime.now().millisecondsSinceEpoch}');
      _udpSocket?.send(msg, InternetAddress('255.255.255.255'), udpDiscoveryPort);
    } catch (_) {}
  }

  void _handleDiscoveryBeacon(Datagram datagram) {
    try {
      final text = utf8.decode(datagram.data);
      if (text.startsWith('LANTERN_BEACON:v1:')) {
        final parts = text.split(':');
        final peerId = parts[2];
        final port = int.tryParse(parts[3]) ?? tcpPort;

        if (peerId != _myNodeId) {
          _discoveredPeers[peerId] = PeerNode(
            nodeId: peerId,
            ipAddress: datagram.address.address,
            port: port,
            lastSeen: DateTime.now(),
          );
          _peersController.add(_discoveredPeers.values.toList());
        }
      }
    } catch (_) {}
  }

  void _cleanupStalePeers() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 15));
    _discoveredPeers.removeWhere((id, peer) => peer.lastSeen.isBefore(cutoff));
    _peersController.add(_discoveredPeers.values.toList());
  }

  /// Attempts to relay an incident to nearby discovered peers over direct TCP
  Future<bool> relayIncidentToNearbyPeers({
    required IncidentModel incident,
    required String idempotencyKey,
  }) async {
    if (kIsWeb) return false;

    final peers = activePeers;
    if (peers.isEmpty) {
      debugPrint('[Relay] No nearby peer devices currently discovered in radio range.');
      return false;
    }

    final packet = RelayPacket(
      incidentId: incident.incidentId,
      idempotencyKey: idempotencyKey,
      categoryKey: incident.category.key,
      createdAtIso: incident.createdAtUtc.toIso8601String(),
      latitude: incident.latitude,
      longitude: incident.longitude,
      locationAccuracyM: incident.locationAccuracyM,
      peopleAffected: incident.peopleAffected,
      description: incident.description,
      originNodeId: _myNodeId,
      hopCount: 0,
      maxHops: 3,
      relayPath: [_myNodeId],
    );

    for (final peer in peers) {
      try {
        final socket = await Socket.connect(peer.ipAddress, peer.port, timeout: const Duration(seconds: 3));
        final payload = jsonEncode({
          'type': 'OFFLINE_SOS_TRANSFER',
          'packet': packet.toJson(),
        });

        socket.write(payload);
        await socket.flush();

        final completer = Completer<String>();
        final buffer = StringBuffer();
        socket.listen(
          (data) => buffer.write(utf8.decode(data)),
          onDone: () => completer.complete(buffer.toString()),
          onError: (e) => completer.completeError(e),
        );

        final responseStr = await completer.future.timeout(const Duration(seconds: 3));
        await socket.close();

        final response = jsonDecode(responseStr);
        if (response['status'] == 'ACCEPTED' || response['status'] == 'ALREADY_SAVED') {
          await _db.updateIncidentState(
            incidentId: incident.incidentId,
            localState: IncidentDeliveryState.relaying,
          );

          await _db.logIncidentEvent(
            IncidentEventRecord(
              eventId: 'EVT-RELAY-SENT-${DateTime.now().millisecondsSinceEpoch}',
              incidentId: incident.incidentId,
              eventType: 'RELAYED_TO_PEER',
              occurredAtUtc: DateTime.now().toUtc(),
              source: 'LOCAL_PEER_RADIO',
              verified: true,
              safeSummary: 'Transferred offline SOS distress beacon to nearby peer ${peer.nodeId} (${peer.ipAddress}). Waiting for peer gateway forwarding.',
            ),
          );

          return true;
        }
      } catch (e) {
        debugPrint('[Relay] Failed to transfer to peer ${peer.nodeId} (${peer.ipAddress}): $e');
      }
    }

    return false;
  }

  void dispose() {
    _beaconTimer?.cancel();
    _cleanupTimer?.cancel();
    _udpSocket?.close();
    _tcpServer?.close();
    _peersController.close();
  }
}
