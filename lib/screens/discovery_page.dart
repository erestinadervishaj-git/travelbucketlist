import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/travel_quiz_page.dart';

class DiscoveryPage extends StatefulWidget {
  final Map<String, dynamic>? quizAnswers;

  const DiscoveryPage({super.key, this.quizAnswers});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      final recommendations = await _supabaseService.getRecommendationsBasedOnVisited(
        userId: userId,
        quizAnswers: widget.quizAnswers,
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
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
            content: Text('Error loading recommendations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getThumbnailColor(String name) {
    final colors = [
      Colors.green.shade300, // Light green
      Colors.green.shade400,
      Colors.grey.shade600, // Darker grey
      Colors.grey.shade700,
      Colors.green.shade500,
      Colors.grey.shade500,
    ];
    return colors[name.hashCode % colors.length];
  }

  IconData _getThumbnailIcon(String name) {
    return Icons.location_on;
  }

  Future<void> _addToWishlist(Map<String, dynamic> country) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      final countryId = country['id'].toString();
      await _supabaseService.addBucketListItem(
        userId: userId,
        countryId: countryId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${country['name']} added to wishlist!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRecommendations(); // Reload to update list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B3D), // Dark purple
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Discover Destinations',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiscoveryPage()),
              );
            },
            tooltip: 'Take Travel Quiz',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _recommendations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.explore_off,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No new recommendations available',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ve already added all available destinations!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TravelQuizPage()),
                            );
                            if (mounted) {
                              _loadRecommendations();
                            }
                          },
                          icon: const Icon(Icons.quiz, color: Colors.white),
                          label: Text(
                            'Take Travel Quiz Again',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(alpha: 0.9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: Colors.orange.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.quizAnswers != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
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
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Personalized recommendations based on your quiz',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        'Recommended Destinations',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recommendations.length,
                        itemBuilder: (context, index) {
                          final country = _recommendations[index];
                          final countryName = country['name'] as String;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getThumbnailColor(countryName),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getThumbnailIcon(countryName),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                countryName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.add_circle, color: Colors.orange.shade300),
                                      onPressed: () => _addToWishlist(country),
                                      tooltip: 'Add to Wishlist',
                                    ),
                                  ),
                                ],
                              ),
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

