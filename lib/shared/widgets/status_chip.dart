import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum IncidentDeliveryState {
  draft,
  queuedLocal,
  sending,
  awaitingAck,
  relaying,
  serverReceived,
  acknowledged,
  responderAssigned,
  resolved,
  deliveryFailed,
  cancelled;

  String get label {
    switch (this) {
      case IncidentDeliveryState.draft:
        return 'Draft';
      case IncidentDeliveryState.queuedLocal:
        return 'Saved on this device';
      case IncidentDeliveryState.sending:
        return 'Sending...';
      case IncidentDeliveryState.awaitingAck:
        return 'Waiting for Connection';
      case IncidentDeliveryState.relaying:
        return 'Relaying';
      case IncidentDeliveryState.serverReceived:
        return 'Server Received';
      case IncidentDeliveryState.acknowledged:
        return 'Acknowledged';
      case IncidentDeliveryState.responderAssigned:
        return 'Responder Assigned';
      case IncidentDeliveryState.resolved:
        return 'Resolved';
      case IncidentDeliveryState.deliveryFailed:
        return 'Delivery Failed';
      case IncidentDeliveryState.cancelled:
        return 'Cancelled';
    }
  }

  String get descriptiveStatus {
    switch (this) {
      case IncidentDeliveryState.draft:
        return 'Draft request not yet finalized.';
      case IncidentDeliveryState.queuedLocal:
        return 'Saved locally in device storage. Not yet delivered to rescuers.';
      case IncidentDeliveryState.sending:
        return 'Dispatching distress packet over active transport...';
      case IncidentDeliveryState.awaitingAck:
        return 'Waiting for connection or nearby peer relay.';
      case IncidentDeliveryState.relaying:
        return 'Offline emergency relay in progress with nearby peer device.';
      case IncidentDeliveryState.serverReceived:
        return 'Acknowledged and logged by LANTERN disaster response server.';
      case IncidentDeliveryState.acknowledged:
        return 'Confirmed and triaged by rescue command dispatcher.';
      case IncidentDeliveryState.responderAssigned:
        return 'Emergency rescue team has acknowledged and been deployed.';
      case IncidentDeliveryState.resolved:
        return 'Incident extraction or assistance confirmed resolved.';
      case IncidentDeliveryState.deliveryFailed:
        return 'Transport transmission failed. Stored safely in local outbox for retry.';
      case IncidentDeliveryState.cancelled:
        return 'Distress request cancelled by citizen.';
    }
  }

  Color get color {
    switch (this) {
      case IncidentDeliveryState.draft:
        return LanternColors.textMuted;
      case IncidentDeliveryState.queuedLocal:
        return LanternColors.warningAmber;
      case IncidentDeliveryState.sending:
        return LanternColors.signalCyan;
      case IncidentDeliveryState.awaitingAck:
        return LanternColors.frostLavender;
      case IncidentDeliveryState.relaying:
        return LanternColors.signalCyan;
      case IncidentDeliveryState.serverReceived:
        return LanternColors.successGreen;
      case IncidentDeliveryState.acknowledged:
        return LanternColors.signalCyan;
      case IncidentDeliveryState.responderAssigned:
        return LanternColors.frostLavender;
      case IncidentDeliveryState.resolved:
        return LanternColors.successGreen;
      case IncidentDeliveryState.deliveryFailed:
        return LanternColors.emergencyRed;
      case IncidentDeliveryState.cancelled:
        return LanternColors.textMuted;
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentDeliveryState.draft:
        return Icons.edit_note_rounded;
      case IncidentDeliveryState.queuedLocal:
        return Icons.save_alt_rounded;
      case IncidentDeliveryState.sending:
        return Icons.podcasts_rounded;
      case IncidentDeliveryState.awaitingAck:
        return Icons.hourglass_top_rounded;
      case IncidentDeliveryState.relaying:
        return Icons.cell_tower_rounded;
      case IncidentDeliveryState.serverReceived:
        return Icons.check_circle_outline_rounded;
      case IncidentDeliveryState.acknowledged:
        return Icons.verified_outlined;
      case IncidentDeliveryState.responderAssigned:
        return Icons.shield_rounded;
      case IncidentDeliveryState.resolved:
        return Icons.task_alt_rounded;
      case IncidentDeliveryState.deliveryFailed:
        return Icons.error_outline_rounded;
      case IncidentDeliveryState.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

class StatusChip extends StatelessWidget {
  final IncidentDeliveryState state;
  final bool compact;

  const StatusChip({
    super.key,
    required this.state,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = state.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(state.icon, size: compact ? 13 : 15, color: c),
          const SizedBox(width: 6),
          Text(
            state.label,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
