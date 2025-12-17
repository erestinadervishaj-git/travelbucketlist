import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Authentication methods
  Future<AuthResponse> signUp(String email, String password, String username) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        // Try to create profile entry (trigger should handle this, but this is a fallback)
        try {
          await client.from('profiles').insert({
            'id': response.user!.id,
            'username': username,
            'email': response.user!.email,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Profile might already exist from trigger, or RLS issue
          // Check if profile exists, if not, rethrow
          final existingProfile = await getProfile(response.user!.id);
          if (existingProfile == null) {
            // Profile doesn't exist and insert failed, rethrow
            rethrow;
          }
          // Profile exists (likely from trigger), update username and email if needed
          if (existingProfile['username'] != username || existingProfile['email'] != response.user!.email) {
            await client
                .from('profiles')
                .update({
                  'username': username,
                  'email': response.user!.email,
                })
                .eq('id', response.user!.id);
          }
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn(String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername;
      
      // Check if input is an email (contains @) or username
      if (!emailOrUsername.contains('@')) {
        // It's a username, find the email from profile
        final profiles = await client
            .from('profiles')
            .select('email')
            .eq('username', emailOrUsername)
            .limit(1);
        
        if (profiles.isEmpty || profiles[0]['email'] == null) {
          throw Exception('Username not found');
        }
        
        email = profiles[0]['email'] as String;
      }
      
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        throw Exception('Please verify your email before logging in.');
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Profile methods
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Country methods
  Future<List<Map<String, dynamic>>> getAllCountries() async {
    try {
      final response = await client.from('countries').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> addCountry(String name) async {
    try {
      final response = await client
          .from('countries')
          .insert({'name': name})
          .select()
          .single();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> findOrCreateCountry(String countryName) async {
    try {
      // First try to find existing country (case-insensitive search)
      final allCountries = await getAllCountries();
      final existing = allCountries.firstWhere(
        (c) => (c['name'] as String).toLowerCase() == countryName.toLowerCase(),
        orElse: () => {},
      );
      
      if (existing.isNotEmpty && existing['id'] != null) {
        return existing['id'].toString();
      }
      
      // If not found, create it
      final newCountry = await addCountry(countryName);
      return newCountry!['id'].toString();
    } catch (e) {
      // If creation fails (e.g., duplicate), try to find again
      try {
        final allCountries = await getAllCountries();
        final existing = allCountries.firstWhere(
          (c) => (c['name'] as String).toLowerCase() == countryName.toLowerCase(),
        );
        return existing['id'].toString();
      } catch (_) {
        rethrow;
      }
    }
  }

  // Bucket list item methods
  Future<List<Map<String, dynamic>>> getBucketListItems(String userId) async {
    try {
      final response = await client
          .from('bucket_list_items')
          .select('''
            *,
            countries (
              id,
              name
            ),
            destination_images (
              id,
              image_url
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWishlistItems(String userId) async {
    try {
      final response = await client
          .from('bucket_list_items')
          .select('''
            *,
            countries (
              id,
              name
            ),
            destination_images (
              id,
              image_url
            )
          ''')
          .eq('user_id', userId)
          .eq('is_visited', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getVisitedItems(String userId) async {
    try {
      final response = await client
          .from('bucket_list_items')
          .select('''
            *,
            countries (
              id,
              name
            ),
            destination_images (
              id,
              image_url
            )
          ''')
          .eq('user_id', userId)
          .eq('is_visited', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Geocoding function to get coordinates from city/country name
  Future<Map<String, double>?> geocodeLocation(String city, String country) async {
    try {
      // Use Nominatim (OpenStreetMap) geocoding API - free and no API key required
      final query = '$city, $country';
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'TravelBucketListApp/1.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final result = results[0];
          return {
            'latitude': double.parse(result['lat']),
            'longitude': double.parse(result['lon']),
          };
        }
      }
      return null;
    } catch (e) {
      // If geocoding fails, return null (coordinates will be null)
      return null;
    }
  }

  Future<Map<String, dynamic>?> addBucketListItem({
    required String userId,
    required String countryId,
    String? note,
  }) async {
    try {
      // Parse city and country from note for geocoding
      String? city;
      String? country;
      Map<String, double>? coordinates;

      if (note != null && note.isNotEmpty) {
        final lines = note.split('\n');
        if (lines.isNotEmpty && lines[0].contains(',')) {
          final parts = lines[0].split(',');
          if (parts.length >= 2) {
            city = parts[0].trim();
            country = parts[1].trim();
            // Geocode the location
            coordinates = await geocodeLocation(city, country);
          }
        }
      }

      // If no city/country parsed, try to get country name from countryId
      if (coordinates == null && countryId.isNotEmpty) {
        try {
          final countryData = await client
              .from('countries')
              .select('name')
              .eq('id', countryId)
              .single();
          if (countryData['name'] != null) {
            coordinates = await geocodeLocation('', countryData['name']);
          }
        } catch (e) {
          // Ignore errors, coordinates will remain null
        }
      }

      final insertData = <String, Object>{
        'user_id': userId,
        'country_id': countryId,
        'note': note ?? '',
        'is_visited': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add coordinates if available
      if (coordinates != null) {
        insertData['latitude'] = coordinates['latitude']!;
        insertData['longitude'] = coordinates['longitude']!;
      }

      final response = await client
          .from('bucket_list_items')
          .insert(insertData)
          .select('''
            *,
            countries (
              id,
              name
            )
          ''')
          .single();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleVisitedStatus(String itemId, bool isVisited) async {
    try {
      await client
          .from('bucket_list_items')
          .update({'is_visited': isVisited})
          .eq('id', itemId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBucketListItemNote(String itemId, String note) async {
    try {
      await client
          .from('bucket_list_items')
          .update({'note': note})
          .eq('id', itemId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBucketListItemCountry(String itemId, String countryId) async {
    try {
      await client
          .from('bucket_list_items')
          .update({'country_id': countryId})
          .eq('id', itemId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBucketListItem(String itemId) async {
    try {
      await client.from('bucket_list_items').delete().eq('id', itemId);
    } catch (e) {
      rethrow;
    }
  }

  // Image methods
  Future<void> uploadDestinationImage(String bucketItemId, String imagePath) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Read the image file
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found');
      }
      
      final fileBytes = await file.readAsBytes();
      
      // Generate unique filename
      final fileName = '${userId}_${bucketItemId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Supabase Storage bucket 'destination-images'
      // Note: You need to create this bucket in Supabase Dashboard first
      await client.storage
          .from('destination-images')
          .uploadBinary(
            fileName,
            fileBytes,
          );
      
      // Get public URL
      final urlResponse = client.storage
          .from('destination-images')
          .getPublicUrl(fileName);
      
      // Save the public URL to database
      await client.from('destination_images').insert({
        'bucket_item_id': bucketItemId,
        'image_url': urlResponse,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDestinationImage(String imageId, String imageUrl) async {
    try {
      // Delete from database first
      await client.from('destination_images').delete().eq('id', imageId);
      
      // Try to delete from storage if it's a Supabase storage URL
      try {
        // Extract filename from URL if it's a Supabase storage URL
        if (imageUrl.contains('destination-images')) {
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            // Find the index of 'destination-images' and get the filename after it
            final bucketIndex = pathSegments.indexOf('destination-images');
            if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
              final fileName = pathSegments.sublist(bucketIndex + 1).join('/');
              await client.storage
                  .from('destination-images')
                  .remove([fileName]);
            }
          }
        }
      } catch (e) {
        // If storage deletion fails, continue (image might be from external source)
        // The database record is already deleted
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDestinationImages(String bucketItemId) async {
    try {
      final response = await client
          .from('destination_images')
          .select()
          .eq('bucket_item_id', bucketItemId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Profile update methods
  Future<void> updateProfile(String userId, {String? username, String? avatarUrl}) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      
      await client
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // Map methods - get destinations with coordinates
  Future<List<Map<String, dynamic>>> getDestinationsWithCoordinates(String userId) async {
    try {
      final response = await client
          .from('bucket_list_items')
          .select('''
            *,
            countries (
              id,
              name
            )
          ''')
          .eq('user_id', userId)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }


  // Statistics methods
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    try {
      final allItems = await getBucketListItems(userId);
      final visitedItems = allItems.where((item) => item['is_visited'] == true).toList();
      final wishlistItems = allItems.where((item) => item['is_visited'] == false).toList();
      
      // Get unique countries
      final visitedCountries = <String>{};
      for (var item in visitedItems) {
        final country = item['countries'] as Map<String, dynamic>?;
        if (country != null && country['name'] != null) {
          visitedCountries.add(country['name'] as String);
        }
      }
      
      final totalCountries = <String>{};
      for (var item in allItems) {
        final country = item['countries'] as Map<String, dynamic>?;
        if (country != null && country['name'] != null) {
          totalCountries.add(country['name'] as String);
        }
      }
      
      final countriesVisitedPercentage = totalCountries.isEmpty 
          ? 0.0 
          : (visitedCountries.length / totalCountries.length * 100);
      
      return {
        'total_destinations': allItems.length,
        'visited_count': visitedItems.length,
        'wishlist_count': wishlistItems.length,
        'unique_countries_visited': visitedCountries.length,
        'unique_countries_total': totalCountries.length,
        'progress_percentage': allItems.isEmpty ? 0.0 : (visitedItems.length / allItems.length * 100),
        'countries_visited_percentage': countriesVisitedPercentage,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Local Recommendations methods
  Future<Map<String, dynamic>?> getLocalRecommendations(String bucketItemId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final response = await client
          .from('local_recommendations')
          .select()
          .eq('bucket_item_id', bucketItemId)
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrUpdateLocalRecommendations({
    required String bucketItemId,
    required String userId,
    List<String>? mustTryFoods,
    String? restaurants,
    String? localTips,
    Map<String, String>? languagePhrases,
  }) async {
    try {
      // Check if exists
      final existing = await getLocalRecommendations(bucketItemId);
      
      final data = {
        'bucket_item_id': bucketItemId,
        'user_id': userId,
        if (mustTryFoods != null) 'must_try_foods': mustTryFoods,
        if (restaurants != null) 'restaurants': restaurants,
        if (localTips != null) 'local_tips': localTips,
        if (languagePhrases != null) 'language_phrases': languagePhrases,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        // Update
        final response = await client
            .from('local_recommendations')
            .update(data)
            .eq('id', existing['id'])
            .select()
            .single();
        return response;
      } else {
        // Create
        data['created_at'] = DateTime.now().toIso8601String();
        final response = await client
            .from('local_recommendations')
            .insert(data)
            .select()
            .single();
        return response;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Enhanced Review methods
  Future<void> updateDestinationReview({
    required String itemId,
    int? rating,
    String? pros,
    String? cons,
    String? bestTimeToVisit,
    bool? wouldVisitAgain,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (rating != null) updateData['rating'] = rating;
      if (pros != null) updateData['pros'] = pros;
      if (cons != null) updateData['cons'] = cons;
      if (bestTimeToVisit != null) updateData['best_time_to_visit'] = bestTimeToVisit;
      if (wouldVisitAgain != null) updateData['would_visit_again'] = wouldVisitAgain;

      if (updateData.isNotEmpty) {
        await client
            .from('bucket_list_items')
            .update(updateData)
            .eq('id', itemId);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Travel Quiz & Recommendations
  Future<List<Map<String, dynamic>>> getRecommendationsBasedOnVisited({
    required String userId,
    Map<String, dynamic>? quizAnswers,
  }) async {
    try {
      final visitedItems = await getVisitedItems(userId);
      final wishlistItems = await getWishlistItems(userId);
      
      // Get visited countries
      final visitedCountries = <String>{};
      for (var item in visitedItems) {
        final country = item['countries'] as Map<String, dynamic>?;
        if (country != null && country['name'] != null) {
          visitedCountries.add(country['name'] as String);
        }
      }

      // Get wishlist countries
      final wishlistCountries = <String>{};
      for (var item in wishlistItems) {
        final country = item['countries'] as Map<String, dynamic>?;
        if (country != null && country['name'] != null) {
          wishlistCountries.add(country['name'] as String);
        }
      }

      // Get all countries
      final allCountries = await getAllCountries();
      
      // Filter out already visited and wishlist items, but include some if list is empty
      List<Map<String, dynamic>> recommendations;
      if (allCountries.isEmpty) {
        // If no countries in database, return empty list
        return [];
      } else if (allCountries.length <= visitedCountries.length + wishlistCountries.length) {
        // If user has added most/all countries, show wishlist items as recommendations
        recommendations = wishlistItems.map((item) {
          final country = item['countries'] as Map<String, dynamic>?;
          return country ?? {};
        }).where((country) => country.isNotEmpty).toList();
        
        // Also include some popular destinations not yet added
        final popularDestinations = [
          'Japan', 'Italy', 'France', 'Spain', 'Thailand', 
          'Greece', 'Iceland', 'New Zealand', 'Morocco', 'Norway'
        ];
        for (var destName in popularDestinations) {
          if (!visitedCountries.contains(destName) && 
              !wishlistCountries.contains(destName)) {
            // Check if country exists in database
            final existing = allCountries.firstWhere(
              (c) => (c['name'] as String).toLowerCase() == destName.toLowerCase(),
              orElse: () => {},
            );
            if (existing.isNotEmpty && !recommendations.any(
              (r) => (r['name'] as String).toLowerCase() == destName.toLowerCase()
            )) {
              recommendations.add(existing);
            }
          }
        }
      } else {
        // Normal case: show countries not in visited or wishlist
        recommendations = allCountries.where((country) {
          final countryName = country['name'] as String;
          return !visitedCountries.contains(countryName) && 
                 !wishlistCountries.contains(countryName);
        }).toList();
      }

      // If quiz answers provided, prioritize/sort based on preferences
      if (quizAnswers != null && quizAnswers.isNotEmpty && recommendations.isNotEmpty) {
        recommendations = _prioritizeByQuizAnswers(recommendations, quizAnswers);
      }

      // Limit to top 20 recommendations
      if (recommendations.length > 20) {
        recommendations = recommendations.take(20).toList();
      }

      return recommendations;
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to prioritize recommendations based on quiz answers
  List<Map<String, dynamic>> _prioritizeByQuizAnswers(
    List<Map<String, dynamic>> countries,
    Map<String, dynamic> quizAnswers,
  ) {
    // Define country characteristics (simplified - in real app, this would be more detailed)
    final countryProfiles = <String, List<String>>{
      'Japan': ['cultural', 'urban', 'food', 'temperate'],
      'Italy': ['cultural', 'food', 'temperate', 'urban'],
      'Thailand': ['tropical', 'food', 'nature', 'budget'],
      'Iceland': ['nature', 'cold', 'adventure', 'backpack'],
      'France': ['cultural', 'food', 'temperate', 'luxury'],
      'Australia': ['nature', 'temperate', 'adventure', 'urban'],
      'Brazil': ['tropical', 'nature', 'adventure', 'budget'],
      'New Zealand': ['nature', 'temperate', 'adventure', 'hiking'],
      'Greece': ['cultural', 'tropical', 'relaxation', 'midrange'],
      'Spain': ['cultural', 'temperate', 'food', 'urban'],
      'Morocco': ['cultural', 'desert', 'budget', 'backpack'],
      'Norway': ['nature', 'cold', 'luxury', 'hiking'],
      'India': ['cultural', 'tropical', 'budget', 'food'],
      'Canada': ['nature', 'cold', 'temperate', 'adventure'],
      'United States': ['urban', 'temperate', 'luxury', 'nature'],
    };

    // Score each country based on quiz answers
    final scoredCountries = countries.map((country) {
      final countryName = country['name'] as String;
      final profile = countryProfiles[countryName] ?? [];
      int score = 0;
      
      quizAnswers.forEach((key, value) {
        if (profile.contains(value.toString())) {
          score += 2; // Strong match
        }
      });
      
      // Base score for diversity
      score += 1;
      
      return {
        'country': country,
        'score': score,
      };
    }).toList();

    // Sort by score (highest first) and return countries
    scoredCountries.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    
    return scoredCountries.map((item) => item['country'] as Map<String, dynamic>).toList();
  }

  // Distance calculation helper (simplified - uses country centers)
  Future<double> calculateDistanceTraveled(String userId) async {
    try {
      final visitedItems = await getVisitedItems(userId);
      // This is a placeholder - would need actual coordinates
      // For now, return count of unique countries * estimated avg distance
      final visitedCountries = <String>{};
      for (var item in visitedItems) {
        final country = item['countries'] as Map<String, dynamic>?;
        if (country != null && country['name'] != null) {
          visitedCountries.add(country['name'] as String);
        }
      }
      // Rough estimate: assume avg 2000km between countries
      return visitedCountries.length > 1 ? (visitedCountries.length - 1) * 2000.0 : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Travel Goals methods
  Future<List<Map<String, dynamic>>> getTravelGoals(String userId) async {
    try {
      final response = await client
          .from('travel_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createTravelGoal({
    required String userId,
    required String goalType,
    required int targetValue,
    DateTime? deadline,
  }) async {
    try {
      final response = await client
          .from('travel_goals')
          .insert({
            'user_id': userId,
            'goal_type': goalType,
            'target_value': targetValue,
            'current_value': 0,
            'deadline': deadline?.toIso8601String(),
            'is_completed': false,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateTravelGoalProgress(String goalId, int currentValue, {bool? isCompleted}) async {
    try {
      final updates = <String, dynamic>{
        'current_value': currentValue,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (isCompleted != null) {
        updates['is_completed'] = isCompleted;
      }
      await client
          .from('travel_goals')
          .update(updates)
          .eq('id', goalId);
    } catch (e) {
      // Silently fail - goals are optional
    }
  }

  Future<void> deleteTravelGoal(String goalId) async {
    try {
      await client
          .from('travel_goals')
          .delete()
          .eq('id', goalId);
    } catch (e) {
      // Silently fail
    }
  }

  // Helper to calculate current goal progress
  Future<Map<String, int>> calculateGoalProgress(String userId) async {
    try {
      final visitedItems = await getVisitedItems(userId);
      final visitedCountries = <String>{};
      final continents = <String>{};
      
      for (var item in visitedItems) {
        final country = item['countries'] as Map<String, dynamic>?;
        if (country != null && country['name'] != null) {
          visitedCountries.add(country['name'] as String);
          // Simple continent mapping (basic - can be enhanced)
          final countryName = country['name'] as String;
          if (countryName.contains('USA') || countryName.contains('Canada') || countryName.contains('Mexico')) {
            continents.add('North America');
          } else if (countryName.contains('Brazil') || countryName.contains('Argentina') || countryName.contains('Chile')) {
            continents.add('South America');
          } else if (countryName.contains('France') || countryName.contains('Germany') || countryName.contains('Italy') || countryName.contains('Spain') || countryName.contains('UK')) {
            continents.add('Europe');
          } else if (countryName.contains('China') || countryName.contains('Japan') || countryName.contains('India') || countryName.contains('Thailand')) {
            continents.add('Asia');
          } else if (countryName.contains('Australia') || countryName.contains('New Zealand')) {
            continents.add('Oceania');
          } else if (countryName.contains('Egypt') || countryName.contains('South Africa') || countryName.contains('Morocco')) {
            continents.add('Africa');
          }
        }
      }
      
      return {
        'visited_countries': visitedCountries.length,
        'visited_continents': continents.length,
        'total_visited': visitedItems.length,
      };
    } catch (e) {
      return {'visited_countries': 0, 'visited_continents': 0, 'total_visited': 0};
    }
  }
}

