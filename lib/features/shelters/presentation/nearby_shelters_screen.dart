import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../map/presentation/map_screen.dart';

class NearbySheltersScreen extends StatefulWidget {
  final Function(double lat, double lng)? onNavigateToMap;

  const NearbySheltersScreen({super.key, this.onNavigateToMap});

  @override
  State<NearbySheltersScreen> createState() => _NearbySheltersScreenState();
}

class _NearbySheltersScreenState extends State<NearbySheltersScreen> {
  String _selectedFilter = 'All'; // 'All', 'Shelters', 'Medical', 'Food'

  final List<Map<String, dynamic>> _mockShelters = [
    {
      'name': 'Community Relief Center',
      'distance': '2.3 km away',
      'status': 'Open • 150 people',
      'amenities': 'Food, Water, Medical Aid',
      'category': 'Shelters',
      'lat': 17.3850,
      'lng': 78.4867,
      'color': Color(0xFF1E3A8A),
      'icon': Icons.apartment_rounded,
    },
    {
      'name': 'Govt. High School Shelter',
      'distance': '4.1 km away',
      'status': 'Open • 300 people',
      'amenities': 'Sleeping Area, Food',
      'category': 'Shelters',
      'lat': 17.4120,
      'lng': 78.4980,
      'color': Color(0xFF065F46),
      'icon': Icons.school_rounded,
    },
    {
      'name': 'City Medical Camp',
      'distance': '5.8 km away',
      'status': 'Open • Medical Support',
      'amenities': 'First Aid, Doctor Available',
      'category': 'Medical',
      'lat': 17.3620,
      'lng': 78.4650,
      'color': Color(0xFF991B1B),
      'icon': Icons.local_hospital_rounded,
    },
    {
      'name': 'Relief Supply Point',
      'distance': '7.2 km away',
      'status': 'Open • Essential Supplies',
      'amenities': 'Food, Water, Blankets',
      'category': 'Food',
      'lat': 17.3990,
      'lng': 78.4420,
      'color': Color(0xFF92400E),
      'icon': Icons.inventory_2_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _mockShelters.where((s) {
      if (_selectedFilter == 'All') return true;
      return s['category'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nearby Shelters',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            children: [
              // Filter Tabs (Matching Reference Screen 9)
              Row(
                children: [
                  _buildTab('All'),
                  const SizedBox(width: 8),
                  _buildTab('Shelters'),
                  const SizedBox(width: 8),
                  _buildTab('Medical'),
                  const SizedBox(width: 8),
                  _buildTab('Food'),
                ],
              ),
              const SizedBox(height: 18),

              // Shelters List
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141824),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF21283B), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail Preview Box
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: s['color'] as Color,
                              ),
                              child: Center(
                                child: Icon(
                                  s['icon'] as IconData,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['name'] as String,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s['distance'] as String,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        'Open',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF10B981), // Green
                                        ),
                                      ),
                                      Text(
                                        ' • ${(s['status'] as String).replaceAll('Open • ', '')}',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s['amenities'] as String,
                                    style: GoogleFonts.manrope(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Navigation Arrow Button
                            GestureDetector(
                              onTap: () {
                                if (widget.onNavigateToMap != null) {
                                  widget.onNavigateToMap!(s['lat'] as double, s['lng'] as double);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MapScreen(
                                        initialLat: s['lat'] as double,
                                        initialLng: s['lng'] as double,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.5)),
                                ),
                                child: const Icon(
                                  Icons.north_east_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF141824),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF21283B),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
