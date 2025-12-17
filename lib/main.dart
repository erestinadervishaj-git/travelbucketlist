import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/services/supabase_service.dart';
import 'package:ai_mobile_erestinadervishaj1/auth/login_page.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // TODO: Replace with your Supabase URL and anon key
  await Supabase.initialize(
    url: 'https://ryaadrxlioljtfvvjpis.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5YWFkcnhsaW9sanRmdnZqcGlzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3MzA2MzMsImV4cCI6MjA4MTMwNjYzM30.--0BQRm4BOYIb_0iNbsXJPY9c-1_aF3FAYrns9964rw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Bucket List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenToAuthChanges();
  }

  void _checkAuthState() {
    final user = _supabaseService.currentUser;
    setState(() {
      _isAuthenticated = user != null;
      _isLoading = false;
    });
  }

  void _listenToAuthChanges() {
    _supabaseService.authStateChanges.listen((AuthState state) {
      if (mounted) {
        setState(() {
          _isAuthenticated = state.session != null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isAuthenticated ? const HomePage() : const LoginPage();
  }
}
