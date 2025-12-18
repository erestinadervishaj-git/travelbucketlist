import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/destination_details_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  final _supabaseService = SupabaseService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasSearchText = false;
  final List<Marker> _markers = [];
  List<Map<String, dynamic>> _searchResults = [];
  
  // Default center: London, UK (as shown in the reference image)
  // This ensures the map always has a valid initial position
  static const LatLng _defaultCenter = LatLng(51.5074, -0.1278);
  static const double _defaultZoom = 10.0;

  // Helper method to safely check if search results exist (handles web build edge cases)
  bool get _hasSearchResults {
    try {
      return _searchResults.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Zoom in function
  void _zoomIn() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final currentCenter = _mapController.camera.center;
      if (currentZoom < 18.0) {
        _mapController.move(currentCenter, currentZoom + 1);
      }
    } catch (e) {
      debugPrint('Zoom in error: $e');
    }
  }

  // Zoom out function
  void _zoomOut() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final currentCenter = _mapController.camera.center;
      if (currentZoom > 1.0) {
        _mapController.move(currentCenter, currentZoom - 1);
      }
    } catch (e) {
      debugPrint('Zoom out error: $e');
    }
  }

  // Search for location using Nominatim (OpenStreetMap geocoding)
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Use Nominatim API for geocoding (free, no API key required)
      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ai_mobile_erestinadervishaj1',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Search request timed out');
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
          return;
        }

        final List<dynamic> data = json.decode(responseBody);
        if (mounted) {
          setState(() {
            _searchResults = data.map((item) {
              try {
                final latStr = item['lat']?.toString() ?? '0';
                final lonStr = item['lon']?.toString() ?? '0';
                return {
                  'display_name': item['display_name']?.toString() ?? 'Unknown location',
                  'lat': double.tryParse(latStr) ?? 0.0,
                  'lon': double.tryParse(lonStr) ?? 0.0,
                  'type': item['type']?.toString() ?? '',
                  'address': (item['address'] as Map<String, dynamic>?) ?? <String, dynamic>{},
                };
              } catch (e) {
                debugPrint('Error parsing search result: $e');
                return {
                  'display_name': 'Unknown location',
                  'lat': 0.0,
                  'lon': 0.0,
                  'type': '',
                  'address': <String, dynamic>{},
                };
              }
            }).toList();
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Search failed: ${response.statusCode}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Show dialog to add location to wishlist
  Future<void> _showAddDestinationDialog(double lat, double lon, String displayName, Map<String, dynamic> address) async {
    // Clear search first
    _searchController.clear();
    if (mounted) {
      setState(() {
        _searchResults = [];
        _hasSearchText = false;
        _isSearching = false;
      });
    }

    // Extract city and country from address or display name
    String city = '';
    String country = '';
    
    // Try to get from address first
    if (address.isNotEmpty) {
      city = address['city']?.toString() ?? 
             address['town']?.toString() ?? 
             address['village']?.toString() ?? '';
      country = address['country']?.toString() ?? '';
    }
    
    // If no city/country from address, try parsing display name
    if (city.isEmpty || country.isEmpty) {
      final parts = displayName.split(',');
      if (parts.length >= 2) {
        city = parts[0].trim();
        country = parts[parts.length - 1].trim();
      } else if (parts.length == 1) {
        country = parts[0].trim();
      }
    }

    final cityController = TextEditingController(text: city);
    final countryController = TextEditingController(text: country);
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;
    
    await showDialog<bool>(
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
            child: Form(
              key: formKey,
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
                        child: Icon(Icons.add_location, color: Colors.orange.shade300, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add to Wishlist',
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
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cityController,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'City',
                      labelStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                      hintText: 'e.g., Paris',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a city';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: countryController,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Country',
                      labelStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                      hintText: 'e.g., France',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a country';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Reason to visit (optional)',
                      labelStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                      hintText: 'Why do you want to visit?',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    maxLines: 2,
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
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            if (!mounted) return;
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

                            final userId = _supabaseService.currentUser?.id;
                            if (userId == null) {
                              navigator.pop(false);
                              return;
                            }

                            try {
                              final cityText = cityController.text.trim();
                              final countryText = countryController.text.trim();
                              final reason = reasonController.text.trim();

                              // Find or create country
                              final countryId = await _supabaseService.findOrCreateCountry(countryText);

                              // Create note with city and reason
                              final note = '$cityText, $countryText${reason.isNotEmpty ? '\n\nReason: $reason' : ''}';

                              // Add the destination with coordinates directly
                              // Use Supabase client directly to insert with coordinates
                              try {
                                final insertData = <String, Object>{
                                  'user_id': userId,
                                  'country_id': countryId,
                                  'note': note,
                                  'is_visited': false,
                                  'latitude': lat,
                                  'longitude': lon,
                                  'created_at': DateTime.now().toIso8601String(),
                                };

                                await _supabaseService.client
                                    .from('bucket_list_items')
                                    .insert(insertData);
                              } catch (e) {
                                debugPrint('Error adding destination: $e');
                                // Fallback to addBucketListItem if direct insert fails
                                await _supabaseService.addBucketListItem(
                                  userId: userId,
                                  countryId: countryId,
                                  note: note,
                                );
                                
                                // Try to update coordinates after creation
                                final allItems = await _supabaseService.getBucketListItems(userId);
                                final newItem = allItems.firstWhere(
                                  (item) => item['note']?.toString().contains(cityText) == true &&
                                      item['note']?.toString().contains(countryText) == true,
                                  orElse: () => {},
                                );

                                if (newItem.isNotEmpty && newItem['id'] != null) {
                                  try {
                                    await _supabaseService.client
                                        .from('bucket_list_items')
                                        .update({
                                          'latitude': lat,
                                          'longitude': lon,
                                        })
                                        .eq('id', newItem['id']);
                                  } catch (e) {
                                    debugPrint('Error updating coordinates: $e');
                                  }
                                }
                              }

                              if (!mounted) return;
                              
                              navigator.pop(true);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Added $cityText, $countryText to wishlist!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Reload destinations to refresh markers
                              _loadDestinations();
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error adding destination: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
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
                            'Add',
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
      ),
    );
  }

  Future<void> _loadDestinations() async {
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

      // Load ALL destinations with coordinates (both visited and wishlist)
      // But only show visited ones as pins on the map
      final destinations = await _supabaseService.getDestinationsWithCoordinates(userId);
      
      if (mounted) {
        // Filter to only show visited destinations as pins
        final visitedDestinations = destinations.where((d) => d['is_visited'] == true).toList();
        _createMarkers(visitedDestinations);
        setState(() {
          _isLoading = false;
        });
        
        // Fit map to bounds if we have markers, otherwise keep default view
        if (_markers.isNotEmpty) {
          _fitMapToMarkers();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading destinations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createMarkers(List<Map<String, dynamic>> destinations) {
    _markers.clear();
    
    // Only show visited destinations as pins on the map
    for (var destination in destinations) {
      final latitude = destination['latitude'] as double?;
      final longitude = destination['longitude'] as double?;
      final isVisited = destination['is_visited'] as bool? ?? false;
      
      // Skip if no coordinates or not visited
      if (latitude == null || longitude == null || !isVisited) {
        continue;
      }

      // All markers are green since we only show visited destinations
      final marker = Marker(
        point: LatLng(latitude, longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DestinationDetailsPage(destination: destination),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green, // Green for visited destinations
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );

      _markers.add(marker);
    }
    
    // Don't add default marker if we have visited destinations
    // Only add default marker if there are no visited destinations at all
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty) return;

    // Calculate bounds from all markers
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var marker in _markers) {
      final lat = marker.point.latitude;
      final lng = marker.point.longitude;
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    // Fit camera to bounds after a short delay to ensure map is rendered
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B3D), // Dark purple background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Map View',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : Stack(
              children: [
                // FlutterMap must fill entire available space
                // Using SizedBox.expand ensures it takes all available space
                SizedBox.expand(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      // Always set a valid initial center and zoom
                      // This prevents blank/grey screen on initial load
                      initialCenter: _markers.isNotEmpty 
                          ? _markers.first.point 
                          : _defaultCenter,
                      initialZoom: _defaultZoom,
                      // Set reasonable zoom limits
                      minZoom: 1.0,
                      maxZoom: 18.0,
                      // Enable smooth zoom and pan interactions
                      // Pinch-to-zoom, double-tap zoom, and pan are all enabled
                      // InteractiveFlag.all includes: pinchZoom, drag, scrollWheelZoom, doubleTapZoom
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      // Enable smooth animations
                      cameraConstraint: CameraConstraint.contain(
                        bounds: LatLngBounds(
                          const LatLng(-90, -180),
                          const LatLng(90, 180),
                        ),
                      ),
                    ),
                    children: [
                      // OpenStreetMap tile layer
                      // Using CancellableNetworkTileProvider for better performance
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        // User agent is required by OpenStreetMap tile usage policy
                        userAgentPackageName: 'ai_mobile_erestinadervishaj1',
                        // Cancellable provider prevents memory leaks from cancelled requests
                        tileProvider: CancellableNetworkTileProvider(),
                        // Retry failed tiles
                        maxNativeZoom: 19,
                        maxZoom: 18,
                      ),
                      // Marker layer - always show at least one marker
                      MarkerLayer(markers: _markers),
                    ],
                  ),
                ),
                // Search bar at the top
                // IgnorePointer only for non-interactive areas to allow map gestures to pass through
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Search input field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for a country or city...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            prefixIcon: const Icon(Icons.search, color: Colors.orange),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  )
                                : _hasSearchText
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchResults = [];
                                            _hasSearchText = false;
                                          });
                                        },
                                      )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                          onChanged: (value) {
                            final hasText = value.isNotEmpty;
                            setState(() {
                              _hasSearchText = hasText;
                            });
                            if (hasText) {
                              _searchLocation(value);
                            } else {
                              setState(() {
                                _searchResults = [];
                                _isSearching = false;
                                _hasSearchText = false;
                              });
                            }
                          },
                        ),
                      ),
                      // Search results dropdown
                      if (_hasSearchResults)
                        Material(
                          color: Colors.transparent,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              final displayName = result['display_name']?.toString() ?? 'Unknown location';
                              final address = result['address'] as Map<String, dynamic>? ?? <String, dynamic>{};
                              final countryValue = address['country'];
                              final country = (countryValue != null) ? countryValue.toString() : '';
                              
                              // Safely extract lat/lon with proper type checking
                              double lat = 0.0;
                              double lon = 0.0;
                              
                              try {
                                final latValue = result['lat'];
                                if (latValue != null) {
                                  if (latValue is double) {
                                    lat = latValue;
                                  } else if (latValue is num) {
                                    lat = latValue.toDouble();
                                  } else if (latValue is String) {
                                    lat = double.tryParse(latValue) ?? 0.0;
                                  }
                                }
                                
                                final lonValue = result['lon'];
                                if (lonValue != null) {
                                  if (lonValue is double) {
                                    lon = lonValue;
                                  } else if (lonValue is num) {
                                    lon = lonValue.toDouble();
                                  } else if (lonValue is String) {
                                    lon = double.tryParse(lonValue) ?? 0.0;
                                  }
                                }
                              } catch (e) {
                                debugPrint('Error extracting coordinates: $e');
                              }
                              
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  debugPrint('Tapped on: $displayName, lat: $lat, lon: $lon');
                                  
                                  // Only proceed if we have valid coordinates
                                  if (lat != 0.0 && lon != 0.0) {
                                    // Show dialog to add to wishlist
                                    _showAddDestinationDialog(lat, lon, displayName, address);
                                  } else {
                                    debugPrint('Invalid coordinates: lat=$lat, lon=$lon');
                                    // Clear the menu even if coordinates are invalid
                                    if (mounted) {
                                      setState(() {
                                        _searchResults = [];
                                        _hasSearchText = false;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Invalid location coordinates'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: const Icon(Icons.location_on, color: Colors.orange),
                                    title: Text(
                                      displayName.length > 50 
                                          ? '${displayName.substring(0, 50)}...' 
                                          : displayName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: (country.isNotEmpty)
                                        ? Text(
                                            country,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Zoom controls (plus/minus buttons) on the right side
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zoom in button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _zoomIn,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.add,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Divider
                      Container(
                        width: 48,
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      // Zoom out button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _zoomOut,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.remove,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Legend overlay
                Positioned(
                  top: _hasSearchResults ? 280 : 80,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legend',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem('Visited', Colors.green),
                        const SizedBox(height: 4),
                        _buildLegendItem('Wishlist', Colors.orange),
                        if (_markers.isNotEmpty && _markers.length == 1 && _markers.first.point == _defaultCenter)
                          ...[
                            const SizedBox(height: 4),
                            _buildLegendItem('Default', Colors.blue),
                          ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
