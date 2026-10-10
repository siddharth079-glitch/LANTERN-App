import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../shared/widgets/glossy_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../sos/domain/models.dart';

class IncidentDetailsScreen extends StatefulWidget {
  final IncidentModel incident;
  final VoidCallback? onCancelRequest;

  const IncidentDetailsScreen({
    super.key,
    required this.incident,
    this.onCancelRequest,
  });

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  late IncidentModel _currentIncident;
  List<IncidentEventRecord> _events = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _currentIncident = widget.incident;
    _loadEventsAndIncident();
  }

  Future<void> _loadEventsAndIncident() async {
    final updated = await DatabaseHelper.instance.getIncidentById(widget.incident.incidentId);
    final events = await DatabaseHelper.instance.getEventsForIncident(widget.incident.incidentId);
    if (mounted) {
      setState(() {
        if (updated != null) _currentIncident = updated;
        _events = events;
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _handleCancel() async {
    await DatabaseHelper.instance.cancelIncident(_currentIncident.incidentId);
    await _loadEventsAndIncident();
    if (widget.onCancelRequest != null) {
      widget.onCancelRequest!();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS distress request cancelled.'),
          backgroundColor: LanternColors.cardSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = _currentIncident;
    final formattedId = incident.incidentId.length > 12
        ? 'INC-${incident.incidentId.substring(0, 8).toUpperCase()}'
        : incident.incidentId;

    final canCancel = incident.localState == IncidentDeliveryState.queuedLocal ||
        incident.localState == IncidentDeliveryState.sending ||
        incident.localState == IncidentDeliveryState.awaitingAck ||
        incident.localState == IncidentDeliveryState.deliveryFailed;

    return Scaffold(
      backgroundColor: LanternColors.cosmic,
      appBar: AppBar(
        title: const Text(
          'Incident Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: ID and Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                StatusChip(state: incident.localState),
              ],
            ),
            const SizedBox(height: 16),

            // Incident Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LanternColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LanternColors.glassBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: LanternColors.emergencyRed.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: LanternColors.emergencyRed.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: LanternColors.emergencyRed, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.category.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Hyderabad Disaster Zone',
                          style: TextStyle(color: LanternColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Created: ${DateFormat('MMM d, yyyy • h:mm a').format(incident.createdAtUtc.toLocal())}',
                          style: TextStyle(color: LanternColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mini Map / Location Preview Card
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2230),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LanternColors.glassBorder),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MiniMapGridPainter(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: incident.hasLocation
                                ? LanternColors.emergencyRed
                                : LanternColors.textMuted,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (incident.hasLocation
                                        ? LanternColors.emergencyRed
                                        : LanternColors.textMuted)
                                    .withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            incident.hasLocation
                                ? Icons.location_on_rounded
                                : Icons.location_off_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            incident.hasLocation
                                ? '${incident.latitude!.toStringAsFixed(4)}° N, ${incident.longitude!.toStringAsFixed(4)}° E (±${(incident.locationAccuracyM ?? 10).toStringAsFixed(0)}m)'
                                : 'Coordinates Unavailable (No Satellite Fix)',
                            style: LanternTheme.telemetryMonoStyle.copyWith(
                              color: incident.hasLocation
                                  ? LanternColors.signalCyan
                                  : LanternColors.warningAmber,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Cards Row (People Affected & Priority)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: LanternColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LanternColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: LanternColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.people_rounded, color: LanternColors.primaryBlueHover, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('People Affected', style: TextStyle(color: LanternColors.textMuted, fontSize: 10.5)),
                            const SizedBox(height: 2),
                            Text(
                              '${incident.peopleAffected}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: LanternColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LanternColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: LanternColors.emergencyRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.priority_high_rounded, color: LanternColors.emergencyRed, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Priority', style: TextStyle(color: LanternColors.textMuted, fontSize: 10.5)),
                            SizedBox(height: 2),
                            Text(
                              'High',
                              style: TextStyle(color: LanternColors.emergencyRed, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LanternColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LanternColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distress Notes',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    incident.description != null && incident.description!.isNotEmpty
                        ? incident.description!
                        : 'No additional notes provided. Priority emergency distress beacon broadcasted.',
                    style: TextStyle(color: LanternColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Verified Audit Event Timeline (PRD FR-05 & FR-08)
            const Text(
              'Verified Event Timeline',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LanternColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LanternColors.glassBorder),
              ),
              child: _isLoadingEvents
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: LanternColors.frostLavender),
                    ))
                  : _events.isEmpty
                      ? const Text(
                          'No events recorded yet.',
                          style: TextStyle(color: LanternColors.textMuted, fontSize: 13),
                        )
                      : Column(
                          children: List.generate(_events.length, (i) {
                            final e = _events[i];
                            final isLast = i == _events.length - 1;
                            final timeStr = DateFormat('h:mm:ss a').format(e.occurredAtUtc.toLocal());

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: e.verified
                                              ? LanternColors.successGreen
                                              : LanternColors.warningAmber,
                                        ),
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            color: Colors.white.withValues(alpha: 0.1),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                e.eventType.replaceAll('_', ' '),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                timeStr,
                                                style: LanternTheme.telemetryMonoStyle.copyWith(
                                                  color: LanternColors.textMuted,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            e.safeSummary,
                                            style: TextStyle(
                                              color: LanternColors.textSecondary,
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Source: ${e.source} • ${e.verified ? 'Cryptographically Verified' : 'Local Unverified'}',
                                            style: TextStyle(
                                              color: e.verified
                                                  ? LanternColors.signalCyan
                                                  : LanternColors.textMuted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
            ),
            const SizedBox(height: 24),

            // Cancel Request Action
            if (canCancel) ...[
              GlossyButton(
                label: 'Cancel Request',
                variant: GlossyButtonVariant.emergencyOutline,
                fullWidth: true,
                height: 48,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: LanternColors.cardSurface,
                      title: const Text('Cancel SOS Request?', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'Are you sure you want to cancel this emergency request? Responders and outbox queue will be updated.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('NO, KEEP ACTIVE', style: TextStyle(color: LanternColors.frostLavender)),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _handleCancel();
                          },
                          child: const Text('CANCEL SOS', style: TextStyle(color: LanternColors.emergencyRed)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final roadPaint = Paint()
      ..color = LanternColors.primaryBlue.withValues(alpha: 0.25)
      ..strokeWidth = 3;

    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width * 0.45, size.height * 0.5), roadPaint);
    canvas.drawLine(Offset(size.width * 0.45, size.height * 0.5), Offset(size.width, size.height * 0.2), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
