import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/location/location_service.dart';
import '../../sos/domain/models.dart';

class MapScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  late AnimationController _pulseController;

  String _selectedFilter = 'All'; // 'All', 'SOS', 'People', 'Shelters'
  LocationData? _userLocation;
  IncidentModel? _activeIncident;

  final LatLng _defaultCenter = const LatLng(17.4389, 78.3912);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final locResult = await _locationService.getCurrentLocation();
    final incidents = await DatabaseHelper.instance.getAllIncidents();

    if (mounted) {
      setState(() {
        if (locResult.status == LocationStatus.success) {
          _userLocation = locResult.data;
        }
        if (incidents.isNotEmpty) {
          _activeIncident = incidents.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final centerLatLng = LatLng(
      widget.initialLat ?? _userLocation?.latitude ?? _defaultCenter.latitude,
      widget.initialLng ?? _userLocation?.longitude ?? _defaultCenter.longitude,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: Stack(
        children: [
          // 1. Interactive Dark Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: 14.2,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lantern.lantern',
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -0.8, 0, 0, 0, 255,
                      0, -0.8, 0, 0, 255,
                      0, 0, -0.8, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: tileWidget,
                  );
                },
              ),

              // Glowing Red Beacon Radius Circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: centerLatLng,
                    radius: 90,
                    useRadiusInMeter: false,
                    color: const Color(0xFFFF2A3C).withValues(alpha: 0.15),
                    borderColor: const Color(0xFFFF2A3C).withValues(alpha: 0.5),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

              // Map Markers
              MarkerLayer(
                markers: [
                  // Center SOS Beacon Pin (Red)
                  Marker(
                    point: centerLatLng,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF2A3C),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2A3C).withValues(alpha: 0.6),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.podcasts_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),

                  // Nearby Orange People Pins
                  Marker(
                    point: LatLng(centerLatLng.latitude + 0.006, centerLatLng.longitude - 0.008),
                    width: 36,
                    height: 36,
                    child: _buildMarkerIcon(Icons.person_rounded, const Color(0xFFF97316)),
                  ),
                  Marker(
                    point: LatLng(centerLatLng.latitude - 0.007, centerLatLng.longitude + 0.009),
                    width: 36,
                    height: 36,
                    child: _buildMarkerIcon(Icons.person_rounded, const Color(0xFFF97316)),
                  ),

                  // Nearby Green Shelters Pins
                  Marker(
                    point: LatLng(centerLatLng.latitude + 0.010, centerLatLng.longitude + 0.007),
                    width: 36,
                    height: 36,
                    child: _buildMarkerIcon(Icons.holiday_village_rounded, const Color(0xFF10B981)),
                  ),
                  Marker(
                    point: LatLng(centerLatLng.latitude - 0.009, centerLatLng.longitude - 0.006),
                    width: 36,
                    height: 36,
                    child: _buildMarkerIcon(Icons.holiday_village_rounded, const Color(0xFF10B981)),
                  ),

                  // Nearby Blue Device Node
                  Marker(
                    point: LatLng(centerLatLng.latitude + 0.003, centerLatLng.longitude + 0.012),
                    width: 32,
                    height: 32,
                    child: _buildMarkerIcon(Icons.bluetooth_rounded, const Color(0xFF38BDF8)),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Header Bar Matching Reference Screen 6
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF141824).withValues(alpha: 0.9),
                        border: Border.all(color: const Color(0xFF2A344A)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Live Map',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Incident Card & Filters at Bottom (Matching Screen 6)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Incident Detail Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141824).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF263045), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Red SOS Badge Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF2A3C),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A3C).withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Incident Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _activeIncident != null
                                      ? (_activeIncident!.incidentId.length > 16
                                          ? 'SOS-${_activeIncident!.incidentId.substring(4, 12)}'
                                          : _activeIncident!.incidentId)
                                      : 'SOS-20241012-001',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF2A3C).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFF2A3C).withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    'High Priority',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFF2A3C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '5 minutes ago',
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${centerLatLng.latitude.toStringAsFixed(4)}° N, ${centerLatLng.longitude.toStringAsFixed(4)}° E',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF38BDF8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Shared via Nearby Device',
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Category Filter Chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141824).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFF263045)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFilterChip('All', null),
                      _buildFilterChip('SOS', const Color(0xFFFF2A3C)),
                      _buildFilterChip('People', const Color(0xFFF97316)),
                      _buildFilterChip('Shelters', const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerIcon(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _buildFilterChip(String label, Color? dotColor) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
