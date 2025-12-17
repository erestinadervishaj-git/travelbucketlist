import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _supabaseService = SupabaseService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      final stats = await _supabaseService.getStatistics(userId);

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A0F2E), // Dark purple
                  Color(0xFF2D1B3D), // Medium purple
                  Color(0xFF3D2B4D), // Lighter purple
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Travel Statistics',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats Cards - Compact Grid Layout
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // First row: Total Destinations, Visited
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Total Destinations',
                                value: '${_stats['total_destinations'] ?? 0}',
                                icon: Icons.location_on,
                                color: Colors.blue.shade400,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Visited',
                                value: '${_stats['visited_count'] ?? 0}',
                                icon: Icons.check_circle,
                                color: Colors.green.shade400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Second row: Wishlist, Countries Visited
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Wishlist',
                                value: '${_stats['wishlist_count'] ?? 0}',
                                icon: Icons.favorite,
                                color: Colors.orange.shade400,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Countries Visited',
                                value: '${_stats['unique_countries_visited'] ?? 0}',
                                icon: Icons.flag,
                                color: Colors.orange.shade400,
                                subtitle: '${(_stats['countries_visited_percentage'] ?? 0.0).toStringAsFixed(0)}%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Visited Progress Card (full width)
                        _buildProgressCard(
                          title: 'Visited Progress',
                          visited: _stats['visited_count'] ?? 0,
                          total: _stats['total_destinations'] ?? 0,
                          color: Colors.green,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    String? value,
    IconData? icon,
    Color? color,
    String? subtitle,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D1B3D).withValues(alpha: 0.9),
            const Color(0xFF3D2B4D).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && color != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.orange.shade300, size: 20),
                ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (value != null)
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required int visited,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (visited / total * 100) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D1B3D).withValues(alpha: 0.9),
            const Color(0xFF3D2B4D).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.trending_up, color: Colors.orange.shade300, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$visited / $total',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for mountain silhouette
class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D1B3D)
      ..style = PaintingStyle.fill;

    final path = Path();
    // First mountain (left)
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.35, size.height * 0.65);
    path.lineTo(0, size.height);
    path.close();

    // Second mountain (center)
    path.moveTo(size.width * 0.25, size.height * 0.65);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height);
    path.close();

    // Third mountain (right)
    path.moveTo(size.width * 0.65, size.height * 0.6);
    path.lineTo(size.width * 0.85, size.height * 0.45);
    path.lineTo(size.width, size.height * 0.55);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

