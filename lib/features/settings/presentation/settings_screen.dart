import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/sync/outbox_sync_engine.dart';
import '../../contacts/presentation/emergency_contacts_screen.dart';
import '../../onboarding/presentation/radio_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  final OutboxSyncEngine syncEngine;

  const SettingsScreen({
    super.key,
    required this.syncEngine,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _incidentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final list = await DatabaseHelper.instance.getAllIncidents();
    if (mounted) {
      setState(() => _incidentCount = list.length);
    }
  }

  void _showServerConfigDialog() {
    String currentUrl = 'http://192.168.137.62:3000';
    if (widget.syncEngine.transport is LiveHttpIncidentTransport) {
      currentUrl = (widget.syncEngine.transport as LiveHttpIncidentTransport).baseUrl;
    }

    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141824),
        title: Text('Central Server Gateway', style: GoogleFonts.manrope(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server IP / Base URL:', style: GoogleFonts.manrope(color: const Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0B0E17),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty && widget.syncEngine.transport is LiveHttpIncidentTransport) {
                (widget.syncEngine.transport as LiveHttpIncidentTransport).updateBaseUrl(newUrl);
              }
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141824),
        title: Text('My Statistics', style: GoogleFonts.manrope(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem('Total Incidents Created', '$_incidentCount'),
            _buildStatItem('Mesh Relays Processed', 'Active (Port 8765)'),
            _buildStatItem('Database Sync Mode', 'Local SQLite + Outbox'),
            _buildStatItem('Gateway Uplink', 'HTTP REST / Dio'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(color: const Color(0xFF94A3B8), fontSize: 13)),
          Text(value, style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Profile Avatar Matching Screen 11
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E2536),
                  border: Border.all(color: const Color(0xFF2A344A), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFF94A3B8),
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // User Name
              Text(
                'LANTERN User',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),

              // Phone Number
              Text(
                '+91 98765 43210',
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 32),

              // Settings Options List (Matching Reference Screen 11)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141824),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF21283B), width: 1.2),
                ),
                child: Column(
                  children: [
                    _buildMenuRow(
                      icon: Icons.bar_chart_rounded,
                      title: 'My Statistics',
                      onTap: _showStatsDialog,
                    ),
                    _buildDivider(),
                    _buildMenuRow(
                      icon: Icons.contact_phone_outlined,
                      title: 'Emergency Contacts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuRow(
                      icon: Icons.tune_rounded,
                      title: 'App Settings',
                      onTap: _showServerConfigDialog,
                    ),
                    _buildDivider(),
                    _buildMenuRow(
                      icon: Icons.security_rounded,
                      title: 'Permissions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RadioSetupScreen(
                              isStandalone: true,
                              onSetupComplete: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuRow(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildMenuRow(
                      icon: Icons.info_outline_rounded,
                      title: 'About LANTERN',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFF1E2536), height: 1, indent: 56, endIndent: 16);
  }
}
