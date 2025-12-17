import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_mobile_erestinadervishaj1/screens/discovery_page.dart';

class TravelQuizPage extends StatefulWidget {
  const TravelQuizPage({super.key});

  @override
  State<TravelQuizPage> createState() => _TravelQuizPageState();
}

class _TravelQuizPageState extends State<TravelQuizPage> {
  int _currentQuestion = 0;
  Map<String, dynamic> _answers = {};
  bool _showResults = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What type of travel experience do you prefer?',
      'options': [
        {'text': 'Adventure & Outdoor Activities', 'value': 'adventure'},
        {'text': 'Relaxation & Beaches', 'value': 'relaxation'},
        {'text': 'Cultural & Historical Sites', 'value': 'cultural'},
        {'text': 'City Exploration & Nightlife', 'value': 'urban'},
        {'text': 'Nature & Wildlife', 'value': 'nature'},
      ],
    },
    {
      'question': 'What\'s your ideal climate?',
      'options': [
        {'text': 'Tropical & Warm', 'value': 'tropical'},
        {'text': 'Temperate & Mild', 'value': 'temperate'},
        {'text': 'Cold & Snowy', 'value': 'cold'},
        {'text': 'Desert & Dry', 'value': 'desert'},
        {'text': 'I love all climates!', 'value': 'any'},
      ],
    },
    {
      'question': 'How do you prefer to travel?',
      'options': [
        {'text': 'Luxury & Comfort', 'value': 'luxury'},
        {'text': 'Budget-Friendly', 'value': 'budget'},
        {'text': 'Backpacking & Hostels', 'value': 'backpack'},
        {'text': 'Mid-Range Hotels', 'value': 'midrange'},
      ],
    },
    {
      'question': 'What\'s your travel group size preference?',
      'options': [
        {'text': 'Solo Travel', 'value': 'solo'},
        {'text': 'Couple/Romantic', 'value': 'couple'},
        {'text': 'Family with Kids', 'value': 'family'},
        {'text': 'Friends Group', 'value': 'friends'},
      ],
    },
    {
      'question': 'What activities interest you most?',
      'options': [
        {'text': 'Food & Culinary Tours', 'value': 'food'},
        {'text': 'Museums & Art Galleries', 'value': 'museums'},
        {'text': 'Hiking & Trekking', 'value': 'hiking'},
        {'text': 'Water Sports & Diving', 'value': 'watersports'},
        {'text': 'Shopping & Markets', 'value': 'shopping'},
      ],
    },
  ];

  void _answerQuestion(String value) {
    setState(() {
      _answers[_questions[_currentQuestion]['question']] = value;
      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      } else {
        _showResults = true;
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestion = 0;
      _answers = {};
      _showResults = false;
    });
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
          'Travel Quiz',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _showResults
          ? _buildResults()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Container(
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
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: (_currentQuestion + 1) / _questions.length,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Question ${_currentQuestion + 1} of ${_questions.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Question card
                  Container(
                    padding: const EdgeInsets.all(24),
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
                        Text(
                          _questions[_currentQuestion]['question'],
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...(_questions[_currentQuestion]['options'] as List<dynamic>).map((option) {
                          final index = (_questions[_currentQuestion]['options'] as List<dynamic>).indexOf(option);
                          // Vary button colors slightly for visual interest
                          final buttonColors = [
                            [Colors.orange.shade600, Colors.orange.shade400],
                            [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
                            [Colors.orange.shade700, Colors.orange.shade500],
                            [Colors.deepOrange.shade700, Colors.deepOrange.shade500],
                            [Colors.orange.shade500, Colors.orange.shade300],
                          ];
                          final colors = buttonColors[index % buttonColors.length];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors[0].withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _answerQuestion(option['value']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    option['text'],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
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
                    Icons.celebration,
                    size: 80,
                    color: Colors.orange.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quiz Complete!',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Based on your preferences, we\'ve prepared some destination recommendations for you!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => DiscoveryPage(quizAnswers: _answers),
                ),
              );
            },
            icon: const Icon(Icons.explore, color: Colors.white),
            label: Text(
              'View Recommendations',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.withValues(alpha: 0.9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.orange.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resetQuiz,
            child: Text(
              'Retake Quiz',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.orange.shade300,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

