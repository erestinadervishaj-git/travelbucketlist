import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';
import 'package:ai_mobile_erestinadervishaj1/auth/login_page.dart';
import 'dart:typed_data';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabaseService = SupabaseService();
  final _usernameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _avatarUrl;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      final profile = await _supabaseService.getProfile(userId);
      if (profile != null) {
        setState(() {
          _usernameController.text = profile['username'] ?? '';
          _avatarUrl = profile['avatar_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = Uint8List.fromList(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageToSupabase(XFile imageFile) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return null;

      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Read bytes and convert to Uint8List
      final fileBytes = Uint8List.fromList(await imageFile.readAsBytes());

      // Upload to Supabase Storage
      // Note: For production, you need to create a storage bucket named 'avatars' in Supabase
      // The storage bucket needs to be created in Supabase Dashboard first
      try {
        // Delete old avatar if exists (optional, to save storage)
        // This is skipped for now to avoid errors
        
        // Upload new image
        // Note: Using unique filename with timestamp to avoid conflicts
        await _supabaseService.client.storage
            .from('avatars')
            .uploadBinary(
              fileName, 
              fileBytes,
            );
        
        // Get public URL
        final urlResponse = _supabaseService.client.storage
            .from('avatars')
            .getPublicUrl(fileName);
        
        return urlResponse;
      } catch (e) {
        // Log the error for debugging
        debugPrint('Error uploading image: $e');
        // If storage bucket doesn't exist, return null
        // User can still use local image
        return null;
      }
    } catch (e) {
      debugPrint('Error in _uploadImageToSupabase: $e');
      // If storage bucket doesn't exist, we'll just store the local path for now
      // In production, you'd need to create the storage bucket in Supabase
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      String? avatarUrl = _avatarUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImageToSupabase(_selectedImage!);
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
        } else {
          // If upload failed, show error but still allow saving (will keep old image)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Warning: Image upload failed. Profile will be updated without new image.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Update profile
      await _supabaseService.updateProfile(
        userId,
        username: _usernameController.text.trim(),
        avatarUrl: avatarUrl,
      );

      // Reload profile to get the latest data
      await _loadProfile();

      if (mounted) {
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
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
                          'Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Column(
                            children: [
                              // Avatar
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.orange.withValues(alpha: 0.2),
                                      backgroundImage: _selectedImage != null && _selectedImageBytes != null
                                          ? MemoryImage(_selectedImageBytes!)
                                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                              ? NetworkImage(_avatarUrl!)
                                              : null,
                                      child: (_selectedImage == null &&
                                              (_avatarUrl == null || _avatarUrl!.isEmpty))
                                          ? Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.orange.shade300,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Username field
                              TextFormField(
                                controller: _usernameController,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.1),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Save button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: Colors.orange.withValues(alpha: 0.9),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: Colors.orange.withValues(alpha: 0.4),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Save Changes',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Logout button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _logout,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.red.shade400),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Logout',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade400,
                                    ),
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
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.35, size.height * 0.65);
    path.lineTo(0, size.height);
    path.close();

    path.moveTo(size.width * 0.25, size.height * 0.65);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height);
    path.close();

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

