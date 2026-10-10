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

class CreateSosScreen extends StatefulWidget {
  final OutboxSyncEngine syncEngine;

  const CreateSosScreen({super.key, required this.syncEngine});

  @override
  State<CreateSosScreen> createState() => _CreateSosScreenState();
}

class _CreateSosScreenState extends State<CreateSosScreen> {
  String _selectedKey = 'fire';
  int _peopleAffected = 1;
  final TextEditingController _descController = TextEditingController();
  final LocationService _locationService = LocationService();

  LocationData? _locationData;
  bool _fetchingLocation = true;
  String _locationName = 'Hyderabad, Telangana';
  bool _isSubmitting = false;

  final List<_EmergencyType> _emergencyTypes = [
    _EmergencyType(
      key: 'fire',
      category: IncidentCategory.fire,
      label: 'Fire',
      icon: Icons.local_fire_department_rounded,
      color: LanternColors.emergencyRed,
    ),
    _EmergencyType(
      key: 'flood',
      category: IncidentCategory.flood,
      label: 'Flood',
      icon: Icons.water_drop_rounded,
      color: LanternColors.signalCyan,
    ),
    _EmergencyType(
      key: 'earthquake',
      category: IncidentCategory.earthquake,
      label: 'Earthquake',
      icon: Icons.vibration_rounded,
      color: const Color(0xFFA855F7),
    ),
    _EmergencyType(
      key: 'medical',
      category: IncidentCategory.medical,
      label: 'Medical',
      icon: Icons.add_box_rounded,
      color: LanternColors.emergencyRed,
    ),
    _EmergencyType(
      key: 'trapped',
      category: IncidentCategory.trapped,
      label: 'Trapped',
      icon: Icons.person_off_rounded,
      color: LanternColors.warningAmber,
    ),
    _EmergencyType(
      key: 'injury',
      category: IncidentCategory.injury,
      label: 'Trauma / Injury',
      icon: Icons.healing_rounded,
      color: const Color(0xFFE11D48),
    ),
    _EmergencyType(
      key: 'missing_person',
      category: IncidentCategory.missingPerson,
      label: 'Missing Person',
      icon: Icons.person_search_rounded,
      color: const Color(0xFF38BDF8),
    ),
    _EmergencyType(
      key: 'infrastructure_hazard',
      category: IncidentCategory.infrastructureHazard,
      label: 'Grid / Infra Hazard',
      icon: Icons.electrical_services_rounded,
      color: LanternColors.warningAmber,
    ),
    _EmergencyType(
      key: 'other',
      category: IncidentCategory.other,
      label: 'Other',
      icon: Icons.more_horiz_rounded,
      color: LanternColors.signalCyan,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    final res = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        if (res.status == LocationStatus.success && res.data != null) {
          _locationData = res.data;
          _locationName = 'GPS Fix (${res.data!.formattedCoordinates})';
        } else {
          _locationData = null;
          _locationName = 'GPS Fix Unavailable (Explicit Null)';
        }
        _fetchingLocation = false;
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

    final selectedType = _emergencyTypes.firstWhere(
      (t) => t.key == _selectedKey,
      orElse: () => _emergencyTypes.first,
    );

    final nowUtc = DateTime.now().toUtc();
    final incidentId = const Uuid().v4();
    final idempotencyKey = incidentId;

    // FR-01 / FR-06: Explicit null coordinates when GPS fix is missing; never fabricate!
    final incident = IncidentModel(
      incidentId: incidentId,
      category: selectedType.category,
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

    // Trigger sync cycle in background
    widget.syncEngine.triggerSyncCycle();

    // Replace current screen with Delivery Status Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryStatusScreen(
          incidentId: incidentId,
          syncEngine: widget.syncEngine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LanternColors.cosmic,
      appBar: AppBar(
        title: const Text(
          'Create SOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Select Emergency Type
            const Text(
              'Select Emergency Type',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemCount: _emergencyTypes.length,
              itemBuilder: (context, index) {
                final item = _emergencyTypes[index];
                final isSelected = item.key == _selectedKey;

                return GestureDetector(
                  onTap: () => setState(() => _selectedKey = item.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? item.color.withValues(alpha: 0.18)
                          : LanternColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? item.color
                            : LanternColors.glassBorder,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, color: item.color, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : LanternColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),

            // Section 2: People Affected
            const Text(
              'People Affected',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: LanternColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LanternColors.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, color: LanternColors.frostLavender, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Estimated count',
                        style: TextStyle(color: LanternColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _peopleAffected > 1 ? () => setState(() => _peopleAffected--) : null,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: LanternColors.glassDefault,
                            shape: BoxShape.circle,
                            border: Border.all(color: LanternColors.glassBorder),
                          ),
                          child: const Icon(Icons.remove, color: Colors.white, size: 18),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_peopleAffected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _peopleAffected++),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: LanternColors.glassDefault,
                            shape: BoxShape.circle,
                            border: Border.all(color: LanternColors.glassBorder),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Section 3: Additional Information
            const Text(
              'Additional Information (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: LanternColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LanternColors.glassBorder),
              ),
              child: TextField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'E.g. need medical support, elderly, children, etc.',
                  hintStyle: TextStyle(color: LanternColors.textMuted, fontSize: 12.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Section 4: Your Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                TextButton(
                  onPressed: _fetchLocation,
                  child: const Text(
                    'Change Location',
                    style: TextStyle(
                      color: LanternColors.primaryBlueHover,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: LanternColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LanternColors.glassBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LanternColors.emergencyRed.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: LanternColors.emergencyRed, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _locationData != null
                              ? 'Accuracy: ±${_locationData!.accuracy.toStringAsFixed(0)} m • GPS Fix Active'
                              : 'Acquiring GPS fix (approximate: ±12 m)',
                          style: TextStyle(color: LanternColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (_fetchingLocation)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Send SOS Button (Glossy Red)
            GlossyButton(
              label: _isSubmitting ? 'SAVING LOCALLY...' : 'Send SOS',
              variant: GlossyButtonVariant.emergency,
              fullWidth: true,
              height: 52,
              isLoading: _isSubmitting,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              onPressed: _isSubmitting ? null : _submitSOS,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _EmergencyType {
  final String key;
  final IncidentCategory category;
  final String label;
  final IconData icon;
  final Color color;

  _EmergencyType({
    required this.key,
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
  });
}
