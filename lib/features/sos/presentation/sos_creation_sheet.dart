import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/location/location_service.dart';
import '../../../core/sync/outbox_sync_engine.dart';
import '../../../shared/widgets/glossy_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../domain/models.dart';
import 'delivery_status_screen.dart';

class SosCreationSheet extends StatefulWidget {
  final OutboxSyncEngine syncEngine;

  const SosCreationSheet({
    super.key,
    required this.syncEngine,
  });

  static Future<void> show(BuildContext context, OutboxSyncEngine syncEngine) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SosCreationSheet(syncEngine: syncEngine),
    );
  }

  @override
  State<SosCreationSheet> createState() => _SosCreationSheetState();
}

class _SosCreationSheetState extends State<SosCreationSheet> {
  IncidentCategory _selectedCategory = IncidentCategory.flood;
  int _peopleAffected = 1;
  final TextEditingController _descController = TextEditingController();
  final LocationService _locationService = LocationService();
  
  LocationData? _locationData;
  bool _fetchingLocation = true;
  String? _locationStatusMsg;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _acquireLocation();
  }

  Future<void> _acquireLocation() async {
    setState(() {
      _fetchingLocation = true;
      _locationStatusMsg = 'Acquiring satellite fix...';
    });

    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (result.status == LocationStatus.success && result.data != null) {
      setState(() {
        _locationData = result.data;
        _fetchingLocation = false;
        _locationStatusMsg = null;
      });
    } else {
      setState(() {
        _locationData = null;
        _fetchingLocation = false;
        _locationStatusMsg = result.message ?? 'GPS fix unavailable.';
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitSOS() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final nowUtc = DateTime.now().toUtc();
    final incidentId = const Uuid().v4();
    final idempotencyKey = incidentId; // PRD: reuse incident UUID as idempotency key

    final incident = IncidentModel(
      incidentId: incidentId,
      category: _selectedCategory,
      createdAtUtc: nowUtc,
      latitude: _locationData?.latitude,
      longitude: _locationData?.longitude,
      locationAccuracyM: _locationData?.accuracy,
      locationCapturedAtUtc: _locationData?.timestamp.toUtc(),
      peopleAffected: _peopleAffected,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      localState: IncidentDeliveryState.queuedLocal,
    );

    final outbox = OutboxRecord(
      outboxId: const Uuid().v4(),
      incidentId: incidentId,
      payloadVersion: 1,
      idempotencyKey: idempotencyKey,
      state: 'queued',
      attemptCount: 0,
      transport: 'HTTPS',
    );

    final initialEvent = IncidentEventRecord(
      eventId: 'EVT-${nowUtc.millisecondsSinceEpoch}',
      incidentId: incidentId,
      eventType: 'SAVED_LOCAL_FIRST',
      occurredAtUtc: nowUtc,
      source: 'LOCAL_DEVICE',
      verified: true,
      safeSummary: 'SOS distress beacon created and safely committed to device storage.',
    );

    // FR-02: Single atomic transaction
    final success = await DatabaseHelper.instance.createIncidentTransactional(
      incident: incident,
      outbox: outbox,
      initialEvent: initialEvent,
    );

    if (!mounted) return;

    if (!success) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save SOS to local database. Storage write error.'),
          backgroundColor: LanternColors.emergencyRed,
        ),
      );
      return;
    }

    // Trigger background sync attempt immediately
    widget.syncEngine.triggerSyncCycle();

    // Close sheet and open Delivery Status Screen
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DeliveryStatusScreen(
          incidentId: incidentId,
          syncEngine: widget.syncEngine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LanternColors.cosmic,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: LanternColors.glassBorder, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LanternColors.emergencyRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: LanternColors.emergencyRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Distress Incident',
                        style: TextStyle(
                          color: LanternColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Will be saved locally first before transmission',
                        style: TextStyle(
                          color: LanternColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category selector
            const Text(
              'EMERGENCY CATEGORY',
              style: TextStyle(
                color: LanternColors.frostLavender,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncidentCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                  selectedColor: LanternColors.emergencyRed.withValues(alpha: 0.25),
                  backgroundColor: LanternColors.glassDefault,
                  side: BorderSide(
                    color: isSelected ? LanternColors.emergencyRed : LanternColors.glassBorder,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : LanternColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // People Affected Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PEOPLE AFFECTED',
                      style: TextStyle(
                        color: LanternColors.frostLavender,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Estimated headcount needing assistance',
                      style: TextStyle(
                        color: LanternColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: LanternColors.glassDefault,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LanternColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _peopleAffected > 1
                            ? () => setState(() => _peopleAffected--)
                            : null,
                      ),
                      Text(
                        '$_peopleAffected',
                        style: const TextStyle(
                          color: LanternColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _peopleAffected++),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Location telemetry banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LanternColors.glassDefault,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LanternColors.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    _locationData != null
                        ? Icons.my_location_rounded
                        : Icons.location_off_rounded,
                    color: _locationData != null
                        ? LanternColors.successGreen
                        : LanternColors.warningAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationData != null
                              ? 'GPS FIX: ${_locationData!.formattedCoordinates}'
                              : (_locationStatusMsg ?? 'Acquiring GPS location...'),
                          style: LanternTheme.telemetryMonoStyle.copyWith(
                            color: _locationData != null
                                ? LanternColors.textPrimary
                                : LanternColors.warningAmber,
                            fontSize: 11,
                          ),
                        ),
                        if (_locationData != null)
                          Text(
                            'Accuracy: ${_locationData!.accuracyLabel} • Captured just now',
                            style: TextStyle(
                              color: LanternColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_fetchingLocation)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: _acquireLocation,
                      tooltip: 'Refresh GPS',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Optional description
            TextField(
              controller: _descController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Urgent notes (e.g. rising water, elderly person, medical need)...',
                hintStyle: TextStyle(color: LanternColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: LanternColors.glassDefault,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: LanternColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: LanternColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: LanternColors.frostLavender),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 22),

            // Submit Button
            GlossyButton(
              label: _isSubmitting ? 'SAVING LOCALLY...' : 'CONFIRM & BROADCAST SOS',
              variant: GlossyButtonVariant.emergency,
              fullWidth: true,
              height: 52,
              isLoading: _isSubmitting,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              onPressed: _isSubmitting ? null : _submitSOS,
            ),
          ],
        ),
      ),
    );
  }
}
