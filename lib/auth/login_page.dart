import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/home_page.dart';
import 'package:ai_mobile_erestinadervishaj1/auth/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Purple background
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
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width < 400 ? 16.0 : 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height < 700 ? 20 : 40),
                    // Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.explore,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.height < 700 ? 24 : 28,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Travel Bucket List',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.height < 700 ? 20 : 24,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 700 ? 20 : 40),
                    // Form Card
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                            vertical: MediaQuery.of(context).size.height < 700 ? 20 : 32,
                          ),
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
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.orange.withValues(alpha: 0.3),
                                  Colors.orange.withValues(alpha: 0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              color: Colors.orange.shade300,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title
                          Text(
                            'Welcome Back',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Subtitle
                          Text(
                            'Sign in to continue',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Email/Username field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.orange.shade300,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              isDense: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email or username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.poppins(fontSize: 14),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_isLoading) {
                                _handleLogin();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.orange.shade300,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              isDense: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Login button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 48),
                              minimumSize: const Size(180, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.orange.withValues(alpha: 0.9),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.orange.withValues(alpha: 0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ],
                        ),
                      ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Sign up link
                    Column(
                      children: [
                        Text(
                          "Don't have an account?",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SignupPage()),
                            );
                          },
                          child: Text(
                            'Sign up',
                            style: GoogleFonts.poppins(
                              color: Colors.orange.shade300,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

