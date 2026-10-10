import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/sync/outbox_sync_engine.dart';
import '../../../shared/widgets/glossy_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../sos/domain/models.dart';
import 'incident_details_screen.dart';

class IncidentsHistoryScreen extends StatefulWidget {
  final OutboxSyncEngine syncEngine;
  final Function(double lat, double lng)? onNavigateToMap;

  const IncidentsHistoryScreen({
    super.key,
    required this.syncEngine,
    this.onNavigateToMap,
  });

  @override
  State<IncidentsHistoryScreen> createState() => _IncidentsHistoryScreenState();
}

class _IncidentsHistoryScreenState extends State<IncidentsHistoryScreen> {
  List<IncidentModel> _incidents = [];
  String _selectedTab = 'Active'; // 'Active', 'Past', 'Cancelled'
  bool _loading = true;
  StreamSubscription<String>? _syncSub;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _syncSub = widget.syncEngine.onSyncEvent.listen((_) {
      _loadIncidents(silent: true);
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _loadIncidents({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final list = await DatabaseHelper.instance.getAllIncidents();
    if (mounted) {
      setState(() {
        _incidents = list;
        _loading = false;
      });
    }
  }

  List<IncidentModel> get _filteredIncidents {
    switch (_selectedTab) {
      case 'Active':
        return _incidents
            .where((i) =>
                i.localState != IncidentDeliveryState.resolved &&
                i.localState != IncidentDeliveryState.cancelled)
            .toList();
      case 'Past':
        return _incidents
            .where((i) => i.localState == IncidentDeliveryState.resolved)
            .toList();
      case 'Cancelled':
        return _incidents
            .where((i) => i.localState == IncidentDeliveryState.cancelled)
            .toList();
      default:
        return _incidents;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIncidents;

    return Scaffold(
      backgroundColor: LanternColors.cosmic,
      appBar: AppBar(
        title: const Text(
          'My Incidents',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            onPressed: () async {
              await widget.syncEngine.triggerSyncCycle();
              _loadIncidents();
            },
            tooltip: 'Sync Outbox Now',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (Active, Past, Cancelled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('Active'),
                const SizedBox(width: 8),
                _buildTab('Past'),
                const SizedBox(width: 8),
                _buildTab('Cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Incidents List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: LanternColors.frostLavender))
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final inc = filtered[index];
                          return _buildIncidentCard(inc);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedTab == label;
    int count = 0;
    if (label == 'Active') {
      count = _incidents
          .where((i) =>
              i.localState != IncidentDeliveryState.resolved &&
              i.localState != IncidentDeliveryState.cancelled)
          .length;
    } else if (label == 'Past') {
      count = _incidents.where((i) => i.localState == IncidentDeliveryState.resolved).length;
    } else if (label == 'Cancelled') {
      count = _incidents.where((i) => i.localState == IncidentDeliveryState.cancelled).length;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? LanternColors.primaryBlue : LanternColors.glassDefault,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LanternColors.primaryBlueHover : LanternColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : LanternColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : LanternColors.glassBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(IncidentModel inc) {
    final formattedId = inc.incidentId.length > 12
        ? 'INC-${inc.incidentId.substring(0, 8).toUpperCase()}'
        : inc.incidentId;
    final createdTime = DateFormat('h:mm a').format(inc.createdAtUtc.toLocal());
    final createdDate = DateFormat('MMM d').format(inc.createdAtUtc.toLocal());

    final isSent = inc.localState == IncidentDeliveryState.serverReceived ||
        inc.localState == IncidentDeliveryState.responderAssigned ||
        inc.localState == IncidentDeliveryState.resolved;
    final isAssigned = inc.localState == IncidentDeliveryState.responderAssigned ||
        inc.localState == IncidentDeliveryState.resolved;
    final isResolved = inc.localState == IncidentDeliveryState.resolved;
    final isCancelled = inc.localState == IncidentDeliveryState.cancelled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LanternColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LanternColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: INC ID & Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedId,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              StatusChip(state: inc.localState, compact: true),
            ],
          ),
          const SizedBox(height: 12),

          // Category Icon & Details
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LanternColors.emergencyRed.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: LanternColors.emergencyRed, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inc.category.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$createdDate at $createdTime • ${inc.peopleAffected} person${inc.peopleAffected > 1 ? 's' : ''}',
                      style: TextStyle(color: LanternColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Embedded Timeline Steps
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isCancelled
                ? Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: LanternColors.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Cancelled by citizen • Not active in dispatch outbox',
                        style: TextStyle(color: LanternColors.textMuted, fontSize: 11.5),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildMiniStep('SOS Stored Locally', createdTime, isDone: true),
                      _buildMiniStep(
                        'Sent to Server',
                        isSent ? 'ACK Receipt Logged' : 'Outbox Queue',
                        isDone: isSent,
                      ),
                      _buildMiniStep('Rescue Team Assigned', '—', isDone: isAssigned),
                      _buildMiniStep('Assistance Resolved', '—', isDone: isResolved, isLast: true),
                    ],
                  ),
          ),
          const SizedBox(height: 14),

          // Bottom Action: View Details / View on Map
          Row(
            children: [
              Expanded(
                child: GlossyButton(
                  label: 'View Details',
                  variant: GlossyButtonVariant.secondary,
                  fullWidth: true,
                  height: 40,
                  icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 15),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncidentDetailsScreen(
                          incident: inc,
                          onCancelRequest: _loadIncidents,
                        ),
                      ),
                    ).then((_) => _loadIncidents());
                  },
                ),
              ),
              if (inc.hasLocation && widget.onNavigateToMap != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.map_rounded, color: LanternColors.signalCyan, size: 20),
                  onPressed: () => widget.onNavigateToMap!(inc.latitude!, inc.longitude!),
                  tooltip: 'View Pin on Map',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStep(String title, String time, {required bool isDone, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isDone ? LanternColors.successGreen : Colors.white24,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDone ? Colors.white : LanternColors.textMuted,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11.5,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: LanternColors.textMuted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LanternColors.glassDefault,
              shape: BoxShape.circle,
              border: Border.all(color: LanternColors.glassBorder),
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: LanternColors.frostLavender,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 'Active'
                ? 'No Active SOS Incidents'
                : (_selectedTab == 'Past'
                    ? 'No Past Resolved Incidents'
                    : 'No Cancelled Incidents'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your emergency requests will appear here with live timeline updates.',
            style: TextStyle(
              color: LanternColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
