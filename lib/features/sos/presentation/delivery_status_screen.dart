import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/sync/outbox_sync_engine.dart';
import '../../../shared/widgets/glossy_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../domain/models.dart';

class DeliveryStatusScreen extends StatefulWidget {
  final String incidentId;
  final OutboxSyncEngine syncEngine;

  const DeliveryStatusScreen({
    super.key,
    required this.incidentId,
    required this.syncEngine,
  });

  @override
  State<DeliveryStatusScreen> createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends State<DeliveryStatusScreen> with SingleTickerProviderStateMixin {
  IncidentModel? _incident;
  bool _isLoading = true;
  bool _isSyncing = false;
  late AnimationController _pulseController;
  StreamSubscription<String>? _syncSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _loadIncident();
    _syncSub = widget.syncEngine.onSyncEvent.listen((evt) {
      if (evt == widget.incidentId || evt == 'SYNC_CYCLE_FINISHED') {
        _loadIncident(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadIncident({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final inc = await DatabaseHelper.instance.getIncidentById(widget.incidentId);

    if (mounted) {
      setState(() {
        _incident = inc;
        _isLoading = false;
      });
    }
  }

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);
    await widget.syncEngine.triggerSyncCycle();
    await _loadIncident(silent: true);
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: LanternColors.cosmic,
        body: Center(child: CircularProgressIndicator(color: LanternColors.frostLavender)),
      );
    }

    final inc = _incident;

    return Scaffold(
      backgroundColor: LanternColors.cosmic,
      appBar: AppBar(
        title: const Text(
          'SOS Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: LanternColors.cardSurface,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.sync_rounded, color: Colors.white),
                        title: const Text('Force Outbox Sync', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _manualSync();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.white),
                        title: const Text('Incident Audit ID', style: TextStyle(color: Colors.white)),
                        subtitle: Text(widget.incidentId, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Pulsing Red Siren Beacon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: LanternColors.emergencyRed.withValues(alpha: 0.35),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Ring
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: LanternColors.emergencyRed.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        // Middle Ring
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LanternColors.emergencyRed.withValues(alpha: 0.15),
                            border: Border.all(
                              color: LanternColors.emergencyRed.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Core Red Circle
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: LanternColors.emergencyRed,
                            gradient: RadialGradient(
                              colors: [Color(0xFFFF6B6B), LanternColors.emergencyRed, Color(0xFF8B0000)],
                            ),
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Title & Subtitle
            const Text(
              'SOS Saved Locally',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your request has been saved and will be sent automatically when connection is available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LanternColors.textSecondary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),

            // Stepper / Delivery Timeline Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: LanternColors.cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: LanternColors.glassBorder),
              ),
              child: Column(
                children: [
                  _buildTimelineStep(
                    stepNumber: 1,
                    title: 'Pending (Saved on Device)',
                    subtitle: 'Durable local SQLite persistence verified',
                    isCompleted: true,
                    isActive: false,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    stepNumber: 2,
                    title: 'Sending',
                    subtitle: (_isSyncing || inc?.localState == IncidentDeliveryState.sending)
                        ? 'Transmitting distress payload now...'
                        : ((inc?.localState == IncidentDeliveryState.serverReceived ||
                                inc?.localState == IncidentDeliveryState.acknowledged ||
                                inc?.localState == IncidentDeliveryState.responderAssigned ||
                                inc?.localState == IncidentDeliveryState.resolved)
                            ? 'Packet delivered over active transport'
                            : (inc?.localState == IncidentDeliveryState.deliveryFailed
                                ? 'Transport retry scheduled with backoff'
                                : 'Queued in offline outbox')),
                    isCompleted: inc?.localState == IncidentDeliveryState.serverReceived ||
                        inc?.localState == IncidentDeliveryState.acknowledged ||
                        inc?.localState == IncidentDeliveryState.responderAssigned ||
                        inc?.localState == IncidentDeliveryState.resolved,
                    isActive: _isSyncing || inc?.localState == IncidentDeliveryState.sending,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    stepNumber: 3,
                    title: 'Received by Server',
                    subtitle: (inc?.localState == IncidentDeliveryState.serverReceived ||
                            inc?.localState == IncidentDeliveryState.acknowledged ||
                            inc?.localState == IncidentDeliveryState.responderAssigned ||
                            inc?.localState == IncidentDeliveryState.resolved)
                        ? 'Central gateway logged & priority computed'
                        : 'Awaiting server reception',
                    isCompleted: inc?.localState == IncidentDeliveryState.serverReceived ||
                        inc?.localState == IncidentDeliveryState.acknowledged ||
                        inc?.localState == IncidentDeliveryState.responderAssigned ||
                        inc?.localState == IncidentDeliveryState.resolved,
                    isActive: inc?.localState == IncidentDeliveryState.serverReceived,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    stepNumber: 4,
                    title: 'Acknowledged',
                    subtitle: (inc?.localState == IncidentDeliveryState.acknowledged ||
                            inc?.localState == IncidentDeliveryState.responderAssigned ||
                            inc?.localState == IncidentDeliveryState.resolved)
                        ? 'Triaged & confirmed by Command Dispatcher'
                        : 'Pending dispatcher review',
                    isCompleted: inc?.localState == IncidentDeliveryState.acknowledged ||
                        inc?.localState == IncidentDeliveryState.responderAssigned ||
                        inc?.localState == IncidentDeliveryState.resolved,
                    isActive: inc?.localState == IncidentDeliveryState.acknowledged,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    stepNumber: 5,
                    title: 'Resolved',
                    subtitle: inc?.localState == IncidentDeliveryState.resolved
                        ? 'Rescue mission completed. Survivors secured.'
                        : (inc?.localState == IncidentDeliveryState.responderAssigned
                            ? 'Rescue unit dispatched to coordinates'
                            : 'Pending team resolution'),
                    isCompleted: inc?.localState == IncidentDeliveryState.resolved,
                    isActive: inc?.localState == IncidentDeliveryState.responderAssigned,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Transmission Action Button
            GlossyButton(
              label: _isSyncing ? 'TRANSMITTING...' : 'RETRY TRANSMISSION NOW',
              variant: GlossyButtonVariant.emergency,
              fullWidth: true,
              height: 50,
              isLoading: _isSyncing,
              icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
              onPressed: _isSyncing ? null : _manualSync,
            ),
            const SizedBox(height: 12),

            // Return to Home
            GlossyButton(
              label: 'Return to Home',
              variant: GlossyButtonVariant.secondary,
              fullWidth: true,
              height: 48,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    Widget iconWidget;

    if (isCompleted) {
      iconWidget = const Icon(Icons.check_circle_rounded, color: LanternColors.successGreen, size: 22);
    } else if (isActive) {
      iconWidget = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: LanternColors.warningAmber.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: LanternColors.warningAmber, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: LanternColors.warningAmber,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      iconWidget = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and connecting vertical line
          Column(
            children: [
              iconWidget,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted
                        ? LanternColors.successGreen.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isCompleted || isActive ? Colors.white : LanternColors.textMuted,
                      fontWeight: isCompleted || isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isActive ? LanternColors.warningAmber : LanternColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
