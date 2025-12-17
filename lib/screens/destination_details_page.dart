import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/gallery_page.dart';

class DestinationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailsPage({super.key, required this.destination});

  @override
  State<DestinationDetailsPage> createState() => _DestinationDetailsPageState();
}

class _DestinationDetailsPageState extends State<DestinationDetailsPage> {
  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  
  // Form controllers
  late TextEditingController _userNotesController;
  late TextEditingController _budgetController;
  int _rating = 0;
  DateTime? _dateVisited;
  bool _isEditing = false;

  // Parsed data from note
  String _city = '';
  String _country = '';
  String _description = '';
  String _userNotes = '';
  double _budget = 0.0;

  @override
  void initState() {
    super.initState();
    _parseDestinationData();
    _userNotesController = TextEditingController(text: _userNotes);
    _budgetController = TextEditingController(text: _budget > 0 ? _budget.toStringAsFixed(2) : '');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update budget controller when budget changes
    if (_budgetController.text != (_budget > 0 ? _budget.toStringAsFixed(2) : '')) {
      _budgetController.text = _budget > 0 ? _budget.toStringAsFixed(2) : '';
    }
  }

  @override
  void dispose() {
    _userNotesController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _parseDestinationData() {
    final countryData = widget.destination['countries'] as Map<String, dynamic>?;
    final countryName = countryData?['name'] ?? 'Unknown';
    final note = widget.destination['note'] as String? ?? '';
    final isVisited = widget.destination['is_visited'] as bool? ?? false;
    
    // Parse city and country from first line
    if (note.isNotEmpty) {
      final lines = note.split('\n');
      if (lines.isNotEmpty && lines[0].contains(',')) {
        final parts = lines[0].split(',');
        if (parts.length >= 2) {
          _city = parts[0].trim();
          _country = parts[1].trim();
        } else {
          _city = '';
          _country = countryName;
        }
      } else {
        _city = '';
        _country = countryName;
      }
      
      // Parse description, rating, date visited, and user notes
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.toLowerCase().startsWith('description:')) {
          _description = line.replaceFirst(RegExp(r'description:\s*', caseSensitive: false), '').trim();
          // Collect multi-line description
          for (int j = i + 1; j < lines.length; j++) {
            if (lines[j].trim().isEmpty || 
                lines[j].toLowerCase().startsWith('rating:') ||
                lines[j].toLowerCase().startsWith('date visited:') ||
                lines[j].toLowerCase().startsWith('user notes:')) {
              break;
            }
            _description += '\n${lines[j].trim()}';
          }
        } else if (line.toLowerCase().startsWith('rating:')) {
          final ratingStr = line.replaceFirst(RegExp(r'rating:\s*', caseSensitive: false), '').trim();
          _rating = int.tryParse(ratingStr) ?? 0;
        } else if (line.toLowerCase().startsWith('date visited:')) {
          final dateStr = line.replaceFirst(RegExp(r'date visited:\s*', caseSensitive: false), '').trim();
          if (dateStr.isNotEmpty) {
            try {
              _dateVisited = DateTime.parse(dateStr);
            } catch (e) {
              _dateVisited = null;
            }
          }
        } else if (line.toLowerCase().startsWith('budget:') || line.toLowerCase().startsWith('expense:')) {
          final budgetStr = line.replaceFirst(RegExp(r'(budget|expense):\s*', caseSensitive: false), '').trim();
          _budget = double.tryParse(budgetStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
        } else if (line.toLowerCase().startsWith('budget:') || line.toLowerCase().startsWith('expense:')) {
          final budgetStr = line.replaceFirst(RegExp(r'(budget|expense):\s*', caseSensitive: false), '').trim();
          _budget = double.tryParse(budgetStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
        } else if (line.toLowerCase().startsWith('user notes:')) {
          // Collect all remaining lines as user notes
          final notesLines = <String>[];
          for (int j = i + 1; j < lines.length; j++) {
            notesLines.add(lines[j].trim());
          }
          _userNotes = notesLines.join('\n').trim();
        }
      }
      
      // If description not found, check for "Reason:" (backward compatibility)
      if (_description.isEmpty) {
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].toLowerCase().startsWith('reason:')) {
            _description = lines[i].replaceFirst(RegExp(r'reason:\s*', caseSensitive: false), '').trim();
            break;
          }
        }
      }
    } else {
      _city = '';
      _country = countryName;
    }
    
    // If visited but no date, set to today
    if (isVisited && _dateVisited == null) {
      _dateVisited = DateTime.now();
    }
  }

  String _buildNoteString() {
    final buffer = StringBuffer();
    buffer.write('$_city, $_country');
    
    if (_description.isNotEmpty) {
      buffer.write('\n\nDescription: $_description');
    }
    
    if (_rating > 0) {
      buffer.write('\n\nRating: $_rating');
    }
    
    if (_dateVisited != null) {
      buffer.write('\n\nDate Visited: ${_dateVisited!.toIso8601String().split('T')[0]}');
    }
    
    if (_budget > 0) {
      buffer.write('\n\nBudget: \$${_budget.toStringAsFixed(2)}');
    }
    
    if (_userNotes.isNotEmpty) {
      buffer.write('\n\nUser Notes:\n$_userNotes');
    }
    
    return buffer.toString();
  }

  Future<void> _removeFromVisited() async {
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
      setState(() {
        _isLoading = true;
      });

      try {
        await _supabaseService.toggleVisitedStatus(
          widget.destination['id'].toString(),
          false, // Set to false to move back to wishlist
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Destination moved back to wishlist!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          // Navigate back to previous screen
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
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

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final note = _buildNoteString();
      await _supabaseService.updateBucketListItemNote(
        widget.destination['id'].toString(),
        note,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Changes saved successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the destination data
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DestinationDetailsPage(
              destination: {
                ...widget.destination,
                'note': note,
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDestination() async {
    // Show confirmation dialog
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
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              shadowColor: Colors.red.withValues(alpha: 0.4),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _supabaseService.deleteBucketListItem(
          widget.destination['id'].toString(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Destination deleted successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to previous screen
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting destination: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

  Future<void> _selectDateVisited() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateVisited ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateVisited = picked;
      });
    }
  }

  Widget _buildStarRating() {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: _isEditing
              ? () {
                  setState(() {
                    _rating = index + 1;
                  });
                }
              : null,
          child: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: isSmallScreen ? 28 : 32,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVisited = widget.destination['is_visited'] as bool? ?? false;
    final displayName = _city.isNotEmpty ? '$_city, $_country' : _country;

    return Scaffold(
      backgroundColor: const Color(0xFF2D1B3D), // Dark purple
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Remove from visited button (only if visited)
          if (isVisited && !_isEditing)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              onPressed: _isLoading ? null : _removeFromVisited,
              tooltip: 'Remove from Visited',
            ),
          // Delete button - always visible
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _isLoading ? null : _deleteDestination,
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _userNotesController.text = _userNotes;
                });
              },
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _isLoading ? null : _saveChanges,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _userNotesController.text = _userNotes;
                });
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with icon
                  Container(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.height < 700 ? 20 : 32),
                    child: Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.height < 700 ? 80 : 100,
                          height: MediaQuery.of(context).size.height < 700 ? 80 : 100,
                          decoration: BoxDecoration(
                            color: _getThumbnailColor(displayName),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getThumbnailIcon(displayName),
                            color: Colors.white,
                            size: MediaQuery.of(context).size.height < 700 ? 40 : 50,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height < 700 ? 12 : 20),
                        Text(
                          displayName,
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.height < 700 ? 22 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isVisited ? Colors.green.shade400 : Colors.orange.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isVisited ? 'Visited' : 'Wishlist',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main content card
                  Container(
                    margin: EdgeInsets.all(MediaQuery.of(context).size.height < 700 ? 12 : 16),
                    padding: EdgeInsets.all(MediaQuery.of(context).size.height < 700 ? 16 : 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2D1B3D).withValues(alpha: 0.95),
                          const Color(0xFF3D2B4D).withValues(alpha: 0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country
                        _buildInfoRow('Country', _country, Icons.public),
                        const SizedBox(height: 16),
                        // City
                        if (_city.isNotEmpty) ...[
                          _buildInfoRow('City', _city, Icons.location_city),
                          const SizedBox(height: 16),
                        ],
                        // Description
                        if (_description.isNotEmpty) ...[
                          Text(
                            'Description',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _description,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Rating
                        Text(
                          'Rating',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStarRating(),
                        const SizedBox(height: 16),
                        // Date Visited (only if visited)
                        if (isVisited) ...[
                          Text(
                            'Date Visited',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _isEditing ? _selectDateVisited : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _isEditing ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: _isEditing
                                    ? Border.all(color: Colors.orange.withValues(alpha: 0.3))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: Colors.orange.shade300,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _dateVisited != null
                                        ? _formatDate(_dateVisited!.toIso8601String())
                                        : 'Not set',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Budget Tracker
                        Text(
                          'Travel Budget',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isEditing
                            ? TextField(
                                controller: _budgetController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Enter budget amount (e.g., 1500.00)',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  prefixIcon: Icon(Icons.attach_money, color: Colors.orange.shade300),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.orange.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.orange.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.1),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                onChanged: (value) {
                                  _budget = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
                                },
                              )
                            : Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.attach_money, color: Colors.orange.shade300, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      _budget > 0
                                          ? '\$${_budget.toStringAsFixed(2)}'
                                          : 'No budget set',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _budget > 0
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        const SizedBox(height: 16),
                        // Gallery Link
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const GalleryPage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withValues(alpha: 0.2),
                                  Colors.deepOrange.withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade400,
                                        Colors.deepOrange.shade400,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.photo_library,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'View Travel Gallery',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'See all photos organized by country',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.orange.shade300,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // User Notes
                        Text(
                          'User Notes',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isEditing
                            ? TextField(
                                controller: _userNotesController,
                                maxLines: 5,
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Add your personal notes about this destination...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.orange.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.orange.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.1),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _userNotes = value;
                                  });
                                },
                              )
                            : Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _userNotes.isNotEmpty
                                      ? _userNotes
                                      : 'No notes yet. Tap edit to add notes.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: _userNotes.isNotEmpty
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.white.withValues(alpha: 0.5),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.orange.shade300),
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
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
