import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _makeCall(BuildContext context, String number, String name) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          _showCallDialog(context, number, name);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showCallDialog(context, number, name);
      }
    }
  }

  void _showCallDialog(BuildContext context, String number, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LanternColors.cardSurface,
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Dial $number for immediate emergency response.\n(Native telephony link invoked)',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DISMISS', style: TextStyle(color: LanternColors.frostLavender)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = [
      _EmergencyContact(
        title: 'National Emergency',
        number: '112',
        subtitle: 'All emergency services',
        icon: Icons.shield_rounded,
        iconColor: LanternColors.primaryBlueHover,
        bgColor: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
      ),
      _EmergencyContact(
        title: 'Ambulance',
        number: '108',
        subtitle: 'Medical emergency',
        icon: Icons.medical_services_rounded,
        iconColor: LanternColors.successGreen,
        bgColor: const Color(0xFF065F46).withValues(alpha: 0.3),
      ),
      _EmergencyContact(
        title: 'Fire Services',
        number: '101',
        subtitle: 'Fire and rescue',
        icon: Icons.local_fire_department_rounded,
        iconColor: LanternColors.warningAmber,
        bgColor: const Color(0xFF92400E).withValues(alpha: 0.3),
      ),
      _EmergencyContact(
        title: 'Police',
        number: '100',
        subtitle: 'Law enforcement',
        icon: Icons.local_police_rounded,
        iconColor: LanternColors.signalCyan,
        bgColor: const Color(0xFF0E7490).withValues(alpha: 0.3),
      ),
      _EmergencyContact(
        title: 'Disaster Helpline',
        number: '1078',
        subtitle: 'Disaster management',
        icon: Icons.hub_rounded,
        iconColor: const Color(0xFFA855F7),
        bgColor: const Color(0xFF6B21A8).withValues(alpha: 0.3),
      ),
    ];

    return Scaffold(
      backgroundColor: LanternColors.cosmic,
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
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
          children: [
            // Top Red Alert Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: LanternColors.emergencyRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LanternColors.emergencyRed.withValues(alpha: 0.35)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: LanternColors.emergencyRed, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'In an emergency, call immediately',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Contact List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = contacts[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LanternColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LanternColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      // Category icon badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),

                      // Name and details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  item.number,
                                  style: const TextStyle(
                                    color: LanternColors.emergencyRed,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    color: LanternColors.textMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Call Action Button
                      GestureDetector(
                        onTap: () => _makeCall(context, item.number, item.title),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: LanternColors.primaryBlue.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            border: Border.all(color: LanternColors.primaryBlue.withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.phone_rounded, color: LanternColors.primaryBlueHover, size: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyContact {
  final String title;
  final String number;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _EmergencyContact({
    required this.title,
    required this.number,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
