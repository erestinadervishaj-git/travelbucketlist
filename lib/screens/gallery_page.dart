import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _photosByCountry = {};
  List<String> _countries = [];

  @override
  void initState() {
    super.initState();
    _initializeGallery();
  }

  Future<void> _initializeGallery() async {
    // Clean up invalid blob URLs first
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId != null) {
        await _supabaseService.cleanupInvalidImageUrls(userId);
      }
    } catch (e) {
      debugPrint('Error cleaning up invalid URLs: $e');
    }
    // Then load photos
    await _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Get all visited destinations with their images
      final visitedItems = await _supabaseService.getVisitedItems(userId);
      
      debugPrint('Gallery: Loaded $visitedItems.length visited items');
      
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      final Set<String> countriesWithVisited = {};
      
      // Process each visited destination
      for (var item in visitedItems) {
        final country = item['countries'] as Map<String, dynamic>?;
        final countryName = country?['name'] ?? 'Unknown';
        countriesWithVisited.add(countryName);
        
        // Initialize the list for this country if not exists
        if (!grouped.containsKey(countryName)) {
          grouped[countryName] = [];
        }
        
        // Get images from nested destination_images or fetch separately
        List<Map<String, dynamic>> images = [];
        
        // First, try to get images from nested structure (if available)
        final nestedImages = item['destination_images'] as List<dynamic>?;
        if (nestedImages != null && nestedImages.isNotEmpty) {
          images = nestedImages.cast<Map<String, dynamic>>();
            debugPrint('Gallery: Found $images.length nested images for $countryName');
        } else {
          // Fallback: fetch images separately
          try {
            images = await _supabaseService.getDestinationImages(
              item['id'].toString(),
            );
            debugPrint('Gallery: Fetched $images.length images separately for $countryName');
          } catch (e) {
            debugPrint('Gallery: Error fetching images for item ${item['id']}: $e');
          }
        }
        
        // Add destination info to each image
        for (var image in images) {
          var imageUrl = image['image_url'] as String?;
          
          // Skip blob URLs - they're temporary and won't work
          if (imageUrl != null && imageUrl.startsWith('blob:')) {
            debugPrint('Gallery: Skipping image with invalid blob URL: ${image['id']}');
            debugPrint('Gallery: This image needs to be re-uploaded to fix the URL');
            // Auto-delete blob URLs
            try {
              await _supabaseService.client.from('destination_images').delete().eq('id', image['id']);
              debugPrint('Gallery: Auto-deleted blob URL image: ${image['id']}');
            } catch (e) {
              debugPrint('Gallery: Error deleting blob URL image: $e');
            }
            continue;
          }
          
          // Validate and clean URL
          if (imageUrl != null && imageUrl.isNotEmpty) {
            imageUrl = imageUrl.trim();
            
            // Ensure it's a valid HTTP/HTTPS URL
            if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
              debugPrint('Gallery: Adding image with URL: $imageUrl');
              grouped[countryName]!.add({
                ...image,
                'image_url': imageUrl, // Use cleaned URL
                'destination': item,
                'destination_name': _getDestinationName(item),
              });
            } else {
              debugPrint('Gallery: Invalid URL format (not http/https): $imageUrl');
            }
          } else {
            debugPrint('Gallery: Skipping image with empty URL: ${image['id']}');
          }
        }
      }
      
      debugPrint('Gallery: Grouped photos by ${grouped.length} countries');
      for (var entry in grouped.entries) {
        debugPrint('Gallery: ${entry.key}: ${entry.value.length} photos');
      }
      
      if (mounted) {
        setState(() {
          _photosByCountry = grouped;
          _countries = countriesWithVisited.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Gallery: Error loading photos: $e');
      debugPrint('Gallery: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading photos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildImageWidget(String imageUrl) {
    // Use a more robust image loading approach
    // Try loading with error handling and retry logic
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      // Don't use headers that might cause CORS issues
      // Let the browser handle CORS naturally
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[800],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.orange,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Gallery: Error loading image: $imageUrl');
        debugPrint('Gallery: Error type: ${error.runtimeType}');
        debugPrint('Gallery: Error: $error');
        
        // Show the URL in the error for debugging
        return Container(
          color: Colors.grey[800],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(
                'Failed to load',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  imageUrl.length > 40 ? '${imageUrl.substring(0, 40)}...' : imageUrl,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      // Add frameBuilder to handle loading states better
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }

  void _showDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln('Gallery Debug Info:\n');
    buffer.writeln('Countries: ${_countries.length}');
    buffer.writeln('Photos by country:');
    
    for (var entry in _photosByCountry.entries) {
      buffer.writeln('\n${entry.key}: ${entry.value.length} photos');
      for (var photo in entry.value) {
        final url = photo['image_url'] as String?;
        buffer.writeln('  - URL: ${url ?? "null"}');
        buffer.writeln('    ID: ${photo['id']}');
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Text(
            buffer.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getDestinationName(Map<String, dynamic> item) {
    final country = item['countries'] as Map<String, dynamic>?;
    final countryName = country?['name'] ?? 'Unknown';
    final note = item['note'] as String? ?? '';
    
    if (note.isNotEmpty) {
      final lines = note.split('\n');
      if (lines.isNotEmpty && lines[0].contains(',')) {
        return lines[0].trim();
      }
    }
    return countryName;
  }

  Future<void> _loadCountriesWithVisited() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      final visitedItems = await _supabaseService.getVisitedItems(userId);
      final Set<String> countries = {};
      
      for (var item in visitedItems) {
        final country = item['countries'] as Map<String, dynamic>?;
        final countryName = country?['name'] ?? 'Unknown';
        countries.add(countryName);
      }
      
      if (mounted) {
        setState(() {
          _countries = countries.toList()..sort();
        });
      }
    } catch (e) {
      // Silently fail - countries list will be empty
    }
  }

  void _showAddPhotoDialog() async {
    // Reload countries list to ensure we have all visited countries
    await _loadCountriesWithVisited();
    
    if (!mounted) return;
    
    if (_countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark at least one destination as visited first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
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
                      child: Icon(Icons.add_photo_alternate, color: Colors.orange.shade300, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select Country',
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
                  'Choose a country to add photos to:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _countries.length,
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.deepOrange.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.public, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          country,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange.shade300, size: 16),
                        onTap: () {
                          Navigator.of(context).pop();
                          _addPhotoForCountry(country);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addPhotoForCountry(String countryName) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('Image picked: ${image.path}, name: ${image.name}');
        
        // Find a destination for this country
        final userId = _supabaseService.currentUser?.id;
        if (userId == null) {
          debugPrint('User not authenticated');
          return;
        }

        final visitedItems = await _supabaseService.getVisitedItems(userId);
        Map<String, dynamic>? destinationForCountry;
        
        for (var item in visitedItems) {
          final country = item['countries'] as Map<String, dynamic>?;
          final itemCountryName = country?['name'] ?? 'Unknown';
          if (itemCountryName == countryName) {
            destinationForCountry = item;
            break;
          }
        }

        if (destinationForCountry != null) {
          setState(() {
            _isLoading = true;
          });

          try {
            debugPrint('Starting upload for destination: ${destinationForCountry['id']}');
            
            // Read bytes from XFile (works on both web and mobile)
            final fileBytes = await image.readAsBytes();
            debugPrint('Read ${fileBytes.length} bytes from image');
            
            await _supabaseService.uploadDestinationImage(
              destinationForCountry['id'].toString(),
              fileBytes,
            );
            debugPrint('Upload completed, reloading photos...');

            await _loadPhotos();

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e, stackTrace) {
            debugPrint('Error uploading image: $e');
            debugPrint('Stack trace: $stackTrace');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error uploading photo: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No destination found for this country. Please mark a destination as visited first.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _addPhotoForCountry: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding photo: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showImageGallery(String countryName, int initialIndex) {
    final photos = _photosByCountry[countryName] ?? [];
    final PageController pageController = PageController(initialPage: initialIndex);
    int currentIndex = initialIndex;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: photos.length,
                controller: pageController,
                onPageChanged: (index) {
                  setDialogState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  final imageUrl = photo['image_url'] as String?;
                  
                  if (imageUrl == null || imageUrl.isEmpty) {
                    return const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                    );
                  }
                  
                  return Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Gallery: Error loading full-screen image: $imageUrl');
                        debugPrint('Gallery: Error: $error');
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.white, size: 64),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deletePhoto(photos[currentIndex], countryName, context),
                        tooltip: 'Delete photo',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Close button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      '${currentIndex + 1} / ${photos.length}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    if (photos[currentIndex]['destination_name'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          photos[currentIndex]['destination_name'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
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
    );
  }

  Future<void> _deletePhoto(Map<String, dynamic> photo, String countryName, BuildContext dialogContext) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: dialogContext,
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
                            Colors.red.withValues(alpha: 0.3),
                            Colors.red.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Delete Photo?',
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
                  'This action cannot be undone.',
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
                            Colors.red.shade600,
                            Colors.red.shade800,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
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
                          'Delete',
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
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      
      try {
        setState(() {
          _isLoading = true;
        });

        final imageId = photo['id'].toString();
        final imageUrl = photo['image_url'] as String;

        // Delete the photo
        await _supabaseService.deleteDestinationImage(imageId, imageUrl);

        // Reload photos
        await _loadPhotos();

        if (!mounted) return;
        
        // Close the gallery dialog if it's open (for full-screen view)
        if (navigator.canPop()) {
          navigator.pop();
        }
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Photo deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error deleting photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B3D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Travel Gallery',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
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
            child: IconButton(
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
              onPressed: () => _showAddPhotoDialog(),
              tooltip: 'Add Photo',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _initializeGallery(); // This will cleanup and reload
            },
            tooltip: 'Refresh',
          ),
          // Debug button to show URLs
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: _showDebugInfo,
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _photosByCountry.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
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
                            Icons.photo_library_outlined,
                            size: 80,
                            color: Colors.orange.shade300,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Photos Yet',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Visit destinations and add photos to see them organized by country here',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPhotos,
                  color: Colors.orange.shade400,
                  backgroundColor: const Color(0xFF2D1B3D),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _countries.length,
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      final photos = _photosByCountry[country] ?? [];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2D1B3D).withValues(alpha: 0.95),
                              const Color(0xFF3D2B4D).withValues(alpha: 0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
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
                            // Country header
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
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
                                    child: const Icon(
                                      Icons.public,
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
                                          country,
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${photos.length} ${photos.length == 1 ? 'photo' : 'photos'}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                    child: IconButton(
                                      icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                                      onPressed: () => _addPhotoForCountry(country),
                                      tooltip: 'Add Photo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Photo grid
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                                itemCount: photos.length,
                                itemBuilder: (context, photoIndex) {
                                  final photo = photos[photoIndex];
                                  final imageUrl = photo['image_url'] as String?;
                                  
                                  if (imageUrl == null || imageUrl.isEmpty) {
                                    debugPrint('Gallery: Photo at index $photoIndex has no image_url');
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.withValues(alpha: 0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.error_outline, color: Colors.red),
                                      ),
                                    );
                                  }
                                  
                                  return GestureDetector(
                                    onTap: () => _showImageGallery(country, photoIndex),
                                    onLongPress: () => _deletePhoto(photo, country, context),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange.withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: _buildImageWidget(imageUrl),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

