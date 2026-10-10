import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/sync/outbox_sync_engine.dart';

class MessagesScreen extends StatefulWidget {
  final OutboxSyncEngine syncEngine;

  const MessagesScreen({super.key, required this.syncEngine});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _selectedFilter = 'All'; // 'All', 'SOS', 'System', 'Community'

  @override
  Widget build(BuildContext context) {
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
          'Messages',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            children: [
              // Filter Tabs (Matching Reference Screen 8)
              Row(
                children: [
                  _buildTab('All'),
                  const SizedBox(width: 8),
                  _buildTab('SOS'),
                  const SizedBox(width: 8),
                  _buildTab('System'),
                  const SizedBox(width: 8),
                  _buildTab('Community'),
                ],
              ),
              const SizedBox(height: 18),

              // Message List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildMessageCard(
                      iconWidget: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF2A3C),
                        ),
                        child: const Center(
                          child: Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      title: 'Emergency SOS',
                      time: '2 min ago',
                      subtitle: 'Someone nearby needs help!',
                      unreadBadge: '1',
                      category: 'SOS',
                    ),
                    const SizedBox(height: 12),

                    _buildMessageCard(
                      iconWidget: _buildRoundIcon(Icons.shield_rounded, const Color(0xFF10B981)),
                      title: 'Rescue Team',
                      time: '5 min ago',
                      subtitle: 'Help is on the way. Stay safe!',
                      category: 'System',
                    ),
                    const SizedBox(height: 12),

                    _buildMessageCard(
                      iconWidget: _buildRoundIcon(Icons.campaign_rounded, const Color(0xFF059669)),
                      title: 'Community Alert',
                      time: '12 min ago',
                      subtitle: 'Need medical supplies at Riverside Camp.',
                      category: 'Community',
                    ),
                    const SizedBox(height: 12),

                    _buildMessageCard(
                      iconWidget: _buildRoundIcon(Icons.info_outline_rounded, const Color(0xFF2563EB)),
                      title: 'System',
                      time: '15 min ago',
                      subtitle: 'Your SOS has been received by the server.',
                      category: 'System',
                    ),
                    const SizedBox(height: 12),

                    _buildMessageCard(
                      iconWidget: _buildRoundIcon(Icons.bluetooth_rounded, const Color(0xFF38BDF8)),
                      title: 'Nearby Device',
                      time: '20 min ago',
                      subtitle: 'New device connected.',
                      category: 'System',
                    ),
                  ],
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

  Widget _buildRoundIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildMessageCard({
    required Widget iconWidget,
    required String title,
    required String time,
    required String subtitle,
    String? unreadBadge,
    required String category,
  }) {
    if (_selectedFilter != 'All' && _selectedFilter != category) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF21283B), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    if (unreadBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF2A3C),
                        ),
                        child: Text(
                          unreadBadge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
