import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';
import 'package:ai_mobile_erestinadervishaj1/auth/login_page.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/destination_details_page.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/statistics_page.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/profile_page.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/map_view_page.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/travel_quiz_page.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/discovery_page.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/destinations_list_page.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/gallery_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _wishlistItems = [];
  List<Map<String, dynamic>> _visitedItems = [];
  bool _isLoading = true;
  String _username = 'User';
  String? _avatarUrl;
  
  // Trip Planner Mini
  final Set<String> _tripPlannerSelectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      final profile = await _supabaseService.getProfile(userId);
      if (profile != null && mounted) {
        setState(() {
          _username = profile['username'] as String? ?? 'User';
          _avatarUrl = profile['avatar_url'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
        return;
      }

      // Load profile for username and avatar
      await _loadProfileData();

      final allItems = await _supabaseService.getBucketListItems(userId);
      final wishlistItems = await _supabaseService.getWishlistItems(userId);
      final visitedItems = await _supabaseService.getVisitedItems(userId);

      if (mounted) {
        setState(() {
          _allItems = allItems;
          _wishlistItems = wishlistItems;
          _visitedItems = visitedItems;
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
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddDestinationDialog() async {
    final cityController = TextEditingController();
    final countryController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    if (!mounted) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title bar
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add New Destination',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // City field
                  TextFormField(
                    controller: cityController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'City',
                      labelStyle: GoogleFonts.poppins(fontSize: 14),
                      hintText: 'e.g., Paris',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a city';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Country field
                  TextFormField(
                    controller: countryController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Country',
                      labelStyle: GoogleFonts.poppins(fontSize: 14),
                      hintText: 'e.g., France',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a country';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Reason field
                  TextFormField(
                    controller: reasonController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Reason to visit',
                      labelStyle: GoogleFonts.poppins(fontSize: 14),
                      hintText: 'Why do you want to visit this place?',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a reason';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
                  ),
                ),
                // Actions
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(fontSize: isSmallScreen ? 13 : 14),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final userId = _supabaseService.currentUser?.id;
                        if (userId == null) return;

                        final city = cityController.text.trim();
                        final country = countryController.text.trim();
                        final reason = reasonController.text.trim();

                        // Find or create country
                        final countryId = await _supabaseService.findOrCreateCountry(country);

                        // Create note with city and reason
                        final note = '$city, $country${reason.isNotEmpty ? '\n\nReason: $reason' : ''}';

                        await _supabaseService.addBucketListItem(
                          userId: userId,
                          countryId: countryId,
                          note: note,
                        );

                        if (!mounted) return;
                        navigator.pop();
                        _loadData();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Destination added successfully!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                        });
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: ${e.toString()}',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D5A7F),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                height: isSmallScreen ? 18 : 20,
                                width: isSmallScreen ? 18 : 20,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Add',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _toggleVisitedStatus(Map<String, dynamic> item) async {
    try {
      // Plus button should always mark as visited (true), not toggle
      await _supabaseService.toggleVisitedStatus(
        item['id'].toString(),
        true,
      );
      _loadData();
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

  Future<void> _editDestination(Map<String, dynamic> item) async {
    final countryData = item['countries'] as Map<String, dynamic>?;
    final countryName = countryData?['name'] ?? '';
    final note = item['note'] as String? ?? '';
    
    String city = '';
    String countryText = countryName;
    String reason = '';
    
    if (note.isNotEmpty) {
      final lines = note.split('\n');
      if (lines.isNotEmpty && lines[0].contains(',')) {
        final parts = lines[0].split(',');
        if (parts.length >= 2) {
          city = parts[0].trim();
          countryText = parts[1].trim();
        }
      }
      // Find reason line and capture all subsequent lines
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().startsWith('reason:')) {
          // Get the reason text from this line (after "Reason:")
          final reasonLine = lines[i].replaceFirst(RegExp(r'reason:\s*', caseSensitive: false), '').trim();
          // Collect all remaining lines as part of the reason
          final reasonLines = [reasonLine];
          for (int j = i + 1; j < lines.length; j++) {
            if (lines[j].trim().isNotEmpty) {
              reasonLines.add(lines[j].trim());
            }
          }
          reason = reasonLines.join('\n');
          break;
        }
      }
    }

    final cityController = TextEditingController(text: city);
    final countryController = TextEditingController(text: countryText);
    final reasonController = TextEditingController(text: reason);
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit Destination',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // City field
                  TextFormField(
                    controller: cityController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'City',
                      labelStyle: GoogleFonts.poppins(fontSize: 14),
                      hintText: 'e.g., Paris',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a city';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Country field
                  TextFormField(
                    controller: countryController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Country',
                      labelStyle: GoogleFonts.poppins(fontSize: 14),
                      hintText: 'e.g., France',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a country';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Reason field
                  TextFormField(
                    controller: reasonController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Reason to visit',
                      labelStyle: GoogleFonts.poppins(fontSize: 14),
                      hintText: 'Why do you want to visit this place?',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final city = cityController.text.trim();
                        final countryText = countryController.text.trim();
                        final reason = reasonController.text.trim();

                        // Find or create country
                        final countryId = await _supabaseService.findOrCreateCountry(countryText);

                        // Build note string
                        String note = '$city, $countryText';
                        if (reason.isNotEmpty) {
                          note += '\n\nReason: $reason';
                        }

                        // Update the bucket list item
                        await _supabaseService.updateBucketListItemNote(
                          item['id'].toString(),
                          note,
                        );

                        // Update country if changed
                        if (item['country_id'].toString() != countryId) {
                          await _supabaseService.updateBucketListItemCountry(
                            item['id'].toString(),
                            countryId,
                          );
                        }

                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Destination updated successfully!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadData();
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                        });
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.withValues(alpha: 0.9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDestination(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Destination',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this destination? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteBucketListItem(
          item['id'].toString(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Destination deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
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
  }

  void _toggleTripPlannerSelection(Map<String, dynamic> item) {
    setState(() {
      final itemId = item['id'].toString();
      if (_tripPlannerSelectedIds.contains(itemId)) {
        _tripPlannerSelectedIds.remove(itemId);
      } else {
        _tripPlannerSelectedIds.add(itemId);
      }
    });
  }

  void _suggestRandomDestination() {
    if (_wishlistItems.isEmpty) return;
    
    final random = DateTime.now().millisecondsSinceEpoch % _wishlistItems.length;
    final suggestion = _wishlistItems[random];

    // Show dialog with suggestion
    showDialog(
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
                      child: Icon(Icons.explore, color: Colors.orange.shade300, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your Next Adventure!',
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
                  'We suggest you visit:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSuggestionCard(suggestion),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
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
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DestinationDetailsPage(destination: suggestion),
                            ),
                          ).then((_) => _loadData());
                        },
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
                          'View Details',
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
  }

  Widget _buildSuggestionCard(Map<String, dynamic> item) {
    final country = item['countries'] as Map<String, dynamic>?;
    final countryName = country?['name'] ?? 'Unknown';
    final note = item['note'] as String? ?? '';
    
    String displayName = countryName;
    if (note.isNotEmpty) {
      final lines = note.split('\n');
      if (lines.isNotEmpty && lines[0].contains(',')) {
        displayName = lines[0].trim();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.2),
            Colors.deepOrange.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.deepOrange.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              _getThumbnailIcon(displayName),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTripSection() {
    final tripItems = _allItems.where((item) {
      return _tripPlannerSelectedIds.contains(item['id'].toString());
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flight_takeoff, color: Colors.orange.shade300, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Trip',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tripItems.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade300,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tripPlannerSelectedIds.clear();
                  });
                },
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tripItems.isEmpty)
            Text(
              'No destinations selected',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          else
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tripItems.length,
                itemBuilder: (context, index) {
                  return _buildTripDestinationChip(tripItems[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripDestinationChip(Map<String, dynamic> item) {
    final country = item['countries'] as Map<String, dynamic>?;
    final countryName = country?['name'] ?? 'Unknown';
    final note = item['note'] as String? ?? '';
    
    String displayName = countryName;
    if (note.isNotEmpty) {
      final lines = note.split('\n');
      if (lines.isNotEmpty && lines[0].contains(',')) {
        displayName = lines[0].trim();
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailsPage(destination: item),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getThumbnailColor(displayName),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getThumbnailIcon(displayName),
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayName.length > 15 ? '${displayName.substring(0, 15)}...' : displayName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _toggleTripPlannerSelection(item),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMountainBackground() {
    return CustomPaint(
      painter: MountainPainter(),
      child: Container(),
    );
  }

  Widget _buildFunTravelFacts() {
    if (_visitedItems.isEmpty) return const SizedBox.shrink();
    final visitedCountries = <String>{}; final countries = <String, int>{}; double maxDistance = 0; String? farthestCountry;
    for (var item in _visitedItems) {
      final country = item['countries'] as Map<String, dynamic>?;
      if (country != null && country['name'] != null) {
        final countryName = country['name'] as String;
        visitedCountries.add(countryName);
        countries[countryName] = (countries[countryName] ?? 0) + 1;
      }
      final lat = item['latitude'] as double?; final lon = item['longitude'] as double?;
      if (lat != null && lon != null) {
        final distance = lat.abs() + lon.abs();
        if (distance > maxDistance) { maxDistance = distance; farthestCountry = country?['name'] as String?; }
      }
    }
    String? mostVisitedCountry; int maxVisits = 0;
    countries.forEach((country, count) { if (count > maxVisits) { maxVisits = count; mostVisitedCountry = country; } });
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D1B3D).withValues(alpha: 0.9),
              const Color(0xFF3D2B4D).withValues(alpha: 0.9),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange.shade300, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Fun Travel Facts',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (mostVisitedCountry != null && maxVisits > 1)
              _buildFactItem('Most Visited', 'You\'ve been to $mostVisitedCountry $maxVisits times!', Icons.repeat),
            if (farthestCountry != null)
              _buildFactItem('Farthest Journey', 'Your farthest destination is $farthestCountry', Icons.flight),
            _buildFactItem('Countries Explored', 'You\'ve visited ${visitedCountries.length} unique ${visitedCountries.length == 1 ? 'country' : 'countries'}!', Icons.public),
            _buildFactItem('Total Destinations', 'You\'ve visited ${_visitedItems.length} ${_visitedItems.length == 1 ? 'destination' : 'destinations'} total!', Icons.location_on),
          ],
        ),
      ),
    );
  }

  Widget _buildFactItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.orange.shade300),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteDestinationOfMonth() {
    if (_visitedItems.isEmpty) return const SizedBox.shrink();
    Map<String, dynamic>? favorite; int maxRating = 0; DateTime? mostRecentDate;
    for (var item in _visitedItems) {
      int rating = 0; DateTime? visitDate; final note = item['note'] as String? ?? '';
      for (var line in note.split('\n')) {
        if (line.toLowerCase().startsWith('rating:')) { final ratingStr = line.replaceFirst(RegExp(r'rating:\s*', caseSensitive: false), '').trim(); rating = int.tryParse(ratingStr) ?? 0; }
        else if (line.toLowerCase().startsWith('date visited:')) { final dateStr = line.replaceFirst(RegExp(r'date visited:\s*', caseSensitive: false), '').trim(); if (dateStr.isNotEmpty) { try { visitDate = DateTime.parse(dateStr); } catch (e) { visitDate = null; } } }
      }
      if (rating > maxRating || (rating == maxRating && visitDate != null && (mostRecentDate == null || visitDate.isAfter(mostRecentDate)))) { maxRating = rating; mostRecentDate = visitDate; favorite = item; }
    }
    if (favorite == null && _visitedItems.isNotEmpty) favorite = _visitedItems.first;
    if (favorite == null) return const SizedBox.shrink();
    final country = favorite['countries'] as Map<String, dynamic>?; final countryName = country?['name'] ?? 'Unknown'; final note = favorite['note'] as String? ?? ''; String city = ''; if (note.isNotEmpty && note.contains(',')) city = note.split(',')[0].trim();
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D1B3D).withValues(alpha: 0.9),
              const Color(0xFF3D2B4D).withValues(alpha: 0.9),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.orange.shade300, size: isSmallScreen ? 20 : 24),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Flexible(
                  child: Text(
                    'Favorite Destination',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Row(
              children: [
                Container(
                  width: isSmallScreen ? 50 : 60,
                  height: isSmallScreen ? 50 : 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on, color: Colors.red.shade400, size: isSmallScreen ? 26 : 32),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.isNotEmpty ? '$city, $countryName' : countryName,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (maxRating > 0) ...[
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < maxRating ? Icons.star : Icons.star_border,
                              size: isSmallScreen ? 14 : 16,
                              color: Colors.amber.shade700,
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: Colors.blue.shade700, size: isSmallScreen ? 20 : 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DestinationDetailsPage(destination: favorite!),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDestinationItem(Map<String, dynamic> item, String cardType) {
    final country = item['countries'] as Map<String, dynamic>?;
    final countryName = country?['name'] ?? 'Unknown';
    final note = item['note'] as String? ?? '';
    
    // Extract city and country from note (format: "City, Country\n\nReason: ...")
    String displayName = countryName;
    if (note.isNotEmpty) {
      final lines = note.split('\n');
      if (lines.isNotEmpty && lines[0].contains(',')) {
        displayName = lines[0].trim(); // "City, Country"
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailsPage(destination: item),
          ),
        ).then((_) => _loadData()); // Refresh after returning
      },
      onLongPress: () {
        _showItemActions(item, cardType);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 400 ? 8 : 10,
          vertical: MediaQuery.of(context).size.width < 400 ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: MediaQuery.of(context).size.width < 400 ? 32 : 36,
              height: MediaQuery.of(context).size.width < 400 ? 32 : 36,
              decoration: BoxDecoration(
                color: _getThumbnailColor(displayName),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getThumbnailIcon(displayName),
                color: Colors.white,
                size: MediaQuery.of(context).size.width < 400 ? 16 : 18,
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width < 400 ? 8 : 10),
            // Destination name - must be flexible to prevent overflow
            Expanded(
              child: Text(
                displayName,
                style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width < 400 ? 4 : 6),
            // Status indicator (no action buttons in preview)
            if (cardType == 'all')
              Container(
                width: MediaQuery.of(context).size.width < 400 ? 24 : 26,
                height: MediaQuery.of(context).size.width < 400 ? 24 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8B4B8), // Natural muted pink
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                ),
              )
            else if (cardType == 'visited')
              Container(
                width: MediaQuery.of(context).size.width < 400 ? 24 : 26,
                height: MediaQuery.of(context).size.width < 400 ? 24 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade300, // Light green
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                ),
              )
            else if (cardType == 'wishlist')
              Container(
                width: MediaQuery.of(context).size.width < 400 ? 24 : 26,
                height: MediaQuery.of(context).size.width < 400 ? 24 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade700, // Darker grey
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showItemActions(Map<String, dynamic> item, String cardType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.green),
              title: Text(
                'View Details',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DestinationDetailsPage(destination: item),
                  ),
                ).then((_) => _loadData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: Text(
                'Edit',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _editDestination(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteDestination(item);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal.shade100,
                      backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null || _avatarUrl!.isEmpty
                          ? Icon(Icons.person, color: Colors.green.shade400, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Travel Enthusiast',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white54),
              // Menu Items
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title: Text(
                  'Home',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.white),
                title: Text(
                  'Statistics',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatisticsPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.white),
                title: Text(
                  'Map View',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MapViewPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz, color: Colors.white),
                title: Text(
                  'Travel Quiz',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TravelQuizPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.explore, color: Colors.white),
                title: Text(
                  'Discover',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DiscoveryPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text(
                  'Travel Gallery',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GalleryPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ).then((_) => _loadProfileData()); // Refresh username and avatar if changed
                },
              ),
              const Spacer(),
              const Divider(color: Colors.white54),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _supabaseService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getThumbnailColor(String displayName) {
    final colors = [
      Colors.green.shade300, // Light green
      Colors.green.shade400,
      Colors.grey.shade600, // Darker grey
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

  Widget _buildPanel({
    required String title,
    required List<Map<String, dynamic>> items,
    required Color headerColor,
    required String cardType,
    required String footerText,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    // Get icon based on card type
    IconData cardIcon;
    if (cardType == 'all') {
      cardIcon = Icons.public;
    } else if (cardType == 'wishlist') {
      cardIcon = Icons.favorite;
    } else {
      cardIcon = Icons.check_circle;
    }
    
    Widget panelContent = GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationsListPage(
              title: title,
              destinations: items,
              headerColor: headerColor,
              cardType: cardType,
            ),
          ),
        ).then((value) {
          if (value == true) {
            _loadData();
          }
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 8,
          vertical: 8,
        ),
        height: isSmallScreen ? 140 : 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF2D1B3D), // Dark purple
              const Color(0xFF3D2B4D), // Lighter purple
              headerColor.withValues(alpha: 0.3), // Accent color
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Title and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${items.length} ${items.length == 1 ? 'destination' : 'destinations'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right side - Icon with glow effect
                  Container(
                    width: 80,
                    height: 80,
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
                    child: Icon(
                      cardIcon,
                      size: 50,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Tap indicator
            Positioned(
              top: 20,
              right: 20,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
    
    return panelContent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Background with purple theme
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
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.orange.shade400,
              backgroundColor: const Color(0xFF2D1B3D),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                children: [
                  // Header with logo and welcome
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Menu button and Logo
                        Row(
                          children: [
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.public,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Icon(
                                          Icons.flight,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Travel Bucket List',
                                    style: GoogleFonts.dancingScript(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48), // Balance the menu button
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Welcome message
                        Text(
                          'Welcome Back, $_username',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start your next adventure!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Buttons row - responsive for mobile
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 400;
                            if (isSmallScreen) {
                              // Stack vertically on small screens
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF6366F1), // Indigo
                                            const Color(0xFF8B5CF6), // Purple
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading ? null : _showAddDestinationDialog,
                                        icon: const Icon(Icons.add, color: Colors.white),
                                        label: Text(
                                          'Add New Destination',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF2D1B3D).withValues(alpha: 0.9),
                                            const Color(0xFF3D2B4D).withValues(alpha: 0.9),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange.withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading || _wishlistItems.isEmpty ? null : _suggestRandomDestination,
                                        icon: Icon(Icons.explore, color: Colors.orange.shade300),
                                        label: Text(
                                          'Where should I go next?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Horizontal layout on larger screens
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF6366F1), // Indigo
                                            const Color(0xFF8B5CF6), // Purple
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading ? null : _showAddDestinationDialog,
                                        icon: const Icon(Icons.add, color: Colors.white),
                                        label: Text(
                                          'Add New Destination',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF2D1B3D).withValues(alpha: 0.9),
                                            const Color(0xFF3D2B4D).withValues(alpha: 0.9),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange.withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading || _wishlistItems.isEmpty ? null : _suggestRandomDestination,
                                        icon: Icon(Icons.explore, color: Colors.orange.shade300),
                                        label: Text(
                                          'Where should I go next?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        // Upcoming Trip section
                        if (_tripPlannerSelectedIds.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildUpcomingTripSection(),
                        ],
                      ],
                    ),
                  ),
                  // Three panels - card style layout
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.white))
                  else
                    Column(
                      children: [
                        _buildPanel(
                          title: 'All Destinations',
                          items: _allItems,
                          headerColor: const Color(0xFFC4A882), // Medium brown
                          cardType: 'all',
                          footerText: 'All',
                        ),
                        _buildPanel(
                          title: 'Wishlist',
                          items: _wishlistItems,
                          headerColor: const Color(0xFFD4B89C), // Beige-brown
                          cardType: 'wishlist',
                          footerText: 'Go',
                        ),
                        _buildPanel(
                          title: 'Visited',
                          items: _visitedItems,
                          headerColor: const Color(0xFFB89A7A), // Darker brown
                          cardType: 'visited',
                          footerText: 'Visited',
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                  // New sections: Fun Facts, Favorite Destination
                  if (_allItems.isNotEmpty) ...[
                    _buildFunTravelFacts(),
                    const SizedBox(height: 24),
                    _buildFavoriteDestinationOfMonth(),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 20), // Add some bottom padding for scrolling
                ],
              ),
            ),
            ),
          ),
          // Logout button
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _supabaseService.signOut();
                if (!mounted) return;
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
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
