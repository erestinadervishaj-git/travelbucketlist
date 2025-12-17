import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/destination_details_page.dart';

class DestinationsListPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> destinations;
  final Color headerColor;
  final String cardType;

  const DestinationsListPage({
    super.key,
    required this.title,
    required this.destinations,
    required this.headerColor,
    required this.cardType,
  });

  @override
  State<DestinationsListPage> createState() => _DestinationsListPageState();
}

class _DestinationsListPageState extends State<DestinationsListPage> {
  final _supabaseService = SupabaseService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshData() async {
    // Trigger refresh in parent
    Navigator.of(context).pop(true);
  }

  Future<void> _toggleVisitedStatus(Map<String, dynamic> item) async {
    try {
      await _supabaseService.toggleVisitedStatus(
        item['id'].toString(),
        true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destination marked as visited!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromVisited(Map<String, dynamic> item) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2D1B3D).withValues(alpha: 0.98),
                const Color(0xFF3D2B4D).withValues(alpha: 0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.orange.withValues(alpha: 0.3),
                            Colors.orange.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.remove_circle_outline, color: Colors.orange.shade300, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Remove from Visited?',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'This will move the destination back to your wishlist.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade600,
                            Colors.deepOrange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Remove',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.toggleVisitedStatus(
          item['id'].toString(),
          false, // Set to false to move back to wishlist
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Destination moved back to wishlist!'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop(true); // Return true to refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating status: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getThumbnailColor(String displayName) {
    final colors = [
      Colors.green.shade300,
      Colors.green.shade400,
      Colors.grey.shade600,
      Colors.grey.shade700,
      Colors.green.shade500,
    ];
    return colors[displayName.hashCode % colors.length];
  }

  IconData _getThumbnailIcon(String displayName) {
    final lower = displayName.toLowerCase();
    if (lower.contains('paris') || lower.contains('france')) {
      return Icons.location_city;
    } else if (lower.contains('everest') || lower.contains('mountain')) {
      return Icons.landscape;
    } else if (lower.contains('reef') || lower.contains('australia')) {
      return Icons.water;
    } else if (lower.contains('japan') || lower.contains('kyoto')) {
      return Icons.temple_buddhist;
    }
    return Icons.public;
  }

  Widget _buildDestinationItem(Map<String, dynamic> item) {
    final country = item['countries'] as Map<String, dynamic>?;
    final countryName = country?['name'] ?? 'Unknown';
    final note = item['note'] as String? ?? '';
    
    // Extract city and country from note (format: "City, Country\n\nReason: ...")
    String displayName = countryName;
    String description = '';
    if (note.isNotEmpty) {
      final lines = note.split('\n');
      if (lines.isNotEmpty && lines[0].contains(',')) {
        displayName = lines[0].trim(); // "City, Country"
      }
      // Extract description/reason
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().startsWith('reason:')) {
          description = lines[i].replaceFirst(RegExp(r'reason:\s*', caseSensitive: false), '').trim();
          if (i + 1 < lines.length) {
            description += '\n' + lines.sublist(i + 1).join('\n').trim();
          }
          break;
        }
      }
      if (description.isEmpty && lines.length > 1) {
        description = lines.sublist(1).where((line) => line.trim().isNotEmpty).join('\n');
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailsPage(destination: item),
          ),
        ).then((value) {
          if (value == true) {
            Navigator.of(context).pop(true); // Refresh parent
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF2D1B3D), // Dark purple
              const Color(0xFF3D2B4D), // Lighter purple
              widget.headerColor.withValues(alpha: 0.2), // Accent color
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with glow
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getThumbnailColor(displayName),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getThumbnailColor(displayName).withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                _getThumbnailIcon(displayName),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Destination info - compact
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Action button - compact
            if (widget.cardType == 'all')
              GestureDetector(
                onTap: () => _toggleVisitedStatus(item),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withValues(alpha: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              )
            else if (widget.cardType == 'visited')
              GestureDetector(
                onTap: () => _removeFromVisited(item),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withValues(alpha: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              )
            else if (widget.cardType == 'wishlist')
              GestureDetector(
                onTap: () => _toggleVisitedStatus(item),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.pink.withValues(alpha: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F2E), // Dark purple background
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2D1B3D), // Dark purple
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: widget.destinations.isEmpty
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A0F2E),
                    Color(0xFF2D1B3D),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No destinations yet',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add destinations to see them here',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A0F2E),
                    Color(0xFF2D1B3D),
                  ],
                ),
              ),
              child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshData,
              color: Colors.orange.shade400,
              backgroundColor: const Color(0xFF2D1B3D),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: widget.destinations.length,
                itemBuilder: (context, index) {
                  return _buildDestinationItem(widget.destinations[index]);
                },
              ),
            ),
            ),
    );
  }
}

