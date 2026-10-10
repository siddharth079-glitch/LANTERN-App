import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class SafetyGuideScreen extends StatefulWidget {
  const SafetyGuideScreen({super.key});

  @override
  State<SafetyGuideScreen> createState() => _SafetyGuideScreenState();
}

class _SafetyGuideScreenState extends State<SafetyGuideScreen> {
  String _selectedPhase = 'During'; // 'Before', 'During', 'After'

  final List<_GuideItem> _guides = [
    _GuideItem(
      title: 'Earthquake',
      subtitle: 'Stay calm, Drop, Cover, Hold On.',
      icon: Icons.vibration_rounded,
      color: LanternColors.warningAmber,
      bgColor: const Color(0xFF92400E).withValues(alpha: 0.25),
      stepsBefore: [
        'Secure heavy furniture and water heaters to wall studs.',
        'Create a family disaster supply kit with 3 days of water & food.',
        'Identify safe interior spots: under sturdy desks away from glass.',
      ],
      stepsDuring: [
        'DROP down onto your hands and knees.',
        'COVER your head and neck under a sturdy table or desk.',
        'HOLD ON to your shelter until shaking stops.',
        'Stay away from windows, outer doors, and unanchored structures.',
      ],
      stepsAfter: [
        'Check yourself and family for injuries before moving.',
        'Expect aftershocks: be prepared to drop and cover again.',
        'Inspect gas, water, and electrical lines for leaks and damage.',
      ],
    ),
    _GuideItem(
      title: 'Flood',
      subtitle: 'Move to higher ground immediately.',
      icon: Icons.water_drop_rounded,
      color: LanternColors.primaryBlueHover,
      bgColor: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
      stepsBefore: [
        'Know evacuation routes and high ground locations in your area.',
        'Elevate electrical appliances and critical documents.',
        'Charge satellite or mobile beacons and emergency battery packs.',
      ],
      stepsDuring: [
        'Move to higher ground immediately. Do NOT enter basements.',
        'Never walk, swim, or drive through flowing water.',
        'Turn off primary gas and electricity mains if safe to do so.',
        'Signal rescuers with flashlights or bright fabric from upper floors.',
      ],
      stepsAfter: [
        'Return only when authorities declare the zone safe.',
        'Avoid contact with floodwater—it may be electrically charged.',
        'Disinfect all items and discard contaminated food.',
      ],
    ),
    _GuideItem(
      title: 'Fire',
      subtitle: 'Use stairs, avoid elevators.',
      icon: Icons.local_fire_department_rounded,
      color: LanternColors.emergencyRed,
      bgColor: const Color(0xFF7F1D1D).withValues(alpha: 0.25),
      stepsBefore: [
        'Test smoke detectors monthly and replace batteries.',
        'Plan two escape routes from each room.',
        'Keep fire extinguishers accessible and inspected.',
      ],
      stepsDuring: [
        'Crawl low under smoke where air is cleaner and cooler.',
        'Feel doors before opening; if hot, use secondary escape route.',
        'Never use elevators during a structural fire.',
        'STOP, DROP, and ROLL if clothes catch fire.',
      ],
      stepsAfter: [
        'Never re-enter a burning building for any belongings.',
        'Seek immediate medical care for burns and smoke inhalation.',
        'Notify emergency dispatch of anyone remaining trapped.',
      ],
    ),
    _GuideItem(
      title: 'Cyclone',
      subtitle: 'Stay indoors, away from windows.',
      icon: Icons.cyclone_rounded,
      color: LanternColors.signalCyan,
      bgColor: const Color(0xFF0E7490).withValues(alpha: 0.25),
      stepsBefore: [
        'Board up windows or close storm shutters securely.',
        'Store drinking water and non-perishable rations for 5 days.',
        'Trim dead tree branches near your house.',
      ],
      stepsDuring: [
        'Stay indoors in the strongest part of the house away from windows.',
        'Beware of the "eye" of the cyclone: severe winds resume suddenly.',
        'Keep battery radio tuned to civil defense emergency frequencies.',
      ],
      stepsAfter: [
        'Watch for loose power cables and fallen electrical poles.',
        'Do not drink tap water until verified uncontaminated.',
      ],
    ),
    _GuideItem(
      title: 'Medical Emergency',
      subtitle: 'Provide first aid and call for help.',
      icon: Icons.medical_services_rounded,
      color: LanternColors.successGreen,
      bgColor: const Color(0xFF065F46).withValues(alpha: 0.25),
      stepsBefore: [
        'Maintain a stocked first aid kit with tourniquets and sterile gauze.',
        'Learn Hands-Only CPR techniques.',
      ],
      stepsDuring: [
        'Check scene safety before approaching casualty.',
        'Severe bleeding: Apply direct continuous pressure with sterile pad.',
        'Unresponsive non-breathing: Begin chest compressions at 100-120 bpm.',
        'Shock: Lay victim flat, elevate feet 30cm, keep warm.',
      ],
      stepsAfter: [
        'Monitor vital signs until medical responders arrive.',
        'Provide responders with accurate timeline of symptoms and triage.',
      ],
    ),
  ];

  void _showProtocolSheet(BuildContext context, _GuideItem guide) {
    List<String> currentSteps;
    if (_selectedPhase == 'Before') {
      currentSteps = guide.stepsBefore;
    } else if (_selectedPhase == 'After') {
      currentSteps = guide.stepsAfter;
    } else {
      currentSteps = guide.stepsDuring;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: LanternColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: guide.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(guide.icon, color: guide.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      Text(
                        'Phase: $_selectedPhase Disaster Protocols',
                        style: TextStyle(color: guide.color, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...currentSteps.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: guide.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(color: guide.color, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
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
          'Safety Guide',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Phase Tabs (Before, During, After)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildPhaseTab('Before'),
                const SizedBox(width: 8),
                _buildPhaseTab('During'),
                const SizedBox(width: 8),
                _buildPhaseTab('After'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Guides List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _guides.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final guide = _guides[index];
                return GestureDetector(
                  onTap: () => _showProtocolSheet(context, guide),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LanternColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LanternColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        // Icon Box
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: guide.bgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(guide.icon, color: guide.color, size: 24),
                        ),
                        const SizedBox(width: 14),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guide.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                guide.subtitle,
                                style: TextStyle(
                                  color: LanternColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Chevron
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTab(String phase) {
    final isSelected = _selectedPhase == phase;
    return GestureDetector(
      onTap: () => setState(() => _selectedPhase = phase),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? LanternColors.primaryBlue : LanternColors.glassDefault,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LanternColors.primaryBlueHover : LanternColors.glassBorder,
          ),
        ),
        child: Text(
          phase,
          style: TextStyle(
            color: isSelected ? Colors.white : LanternColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _GuideItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<String> stepsBefore;
  final List<String> stepsDuring;
  final List<String> stepsAfter;

  _GuideItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.stepsBefore,
    required this.stepsDuring,
    required this.stepsAfter,
  });
}
