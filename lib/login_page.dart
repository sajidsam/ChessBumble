import 'package:flutter/material.dart';
import 'home_page.dart'; // Import to access MyHomePage

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final redColor = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: redColor, // Restored red background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0), // slightly less padding for more keyboard room
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Main Brand Title
                const Center(
                  child: Text(
                    'CHESSBUMBLE',
                    style: TextStyle(
                      color: Colors.white, // Inverted for red background
                      fontSize: 32,
                      fontFamily: 'Doto', // Distinctive dot brand title
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Welcome Subtitle
                const Center(
                  child: Text(
                    'Welcome back! Please login to your account.',
                    style: TextStyle(
                      color: Colors.white70, // Inverted for red background
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Username Field
                _buildProfessionalTextField(
                  hintText: 'type your ChessBumble code',
                  icon: Icons.person_outline,
                  controller: _usernameController,
                  readOnly: true,
                ),
                const SizedBox(height: 32),

                // Custom Doodle Keyboard
                _buildCustomKeyboard(redColor, screenWidth),
                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyHomePage(title: 'ChessBumble'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // White background
                    foregroundColor: Colors.black, // Dark ripple
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Matching the text field
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'LOGIN / REGISTER',
                    style: TextStyle(
                      color: Colors.black87, // Black text
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalTextField({
    required String hintText,
    required IconData icon,
    TextEditingController? controller,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Very light grey fill
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCustomKeyboard(Color redColor, double screenWidth) {
    final keys = [
      ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['z', 'x', 'c', 'v', 'b', 'n', 'm', 'DEL'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA), // Light grey frame matching standard mechanical boards
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2), // White border pops against red bg
      ),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                bool isDel = key == 'DEL';
                
                // "pure red use korba koyekta button e" - use pure red on a few buttons
                bool isRed = isDel || ['1', '2', 'p', 'l', 'm'].contains(key);
                
                // Using flex for mobile responsiveness instead of hardcoded widths
                int flex = 10;
                if (isDel) flex = 18; 
                // Vary sizes to create staggering effect similar to real keyboards
                if (['q', 'a', 'z'].contains(key)) flex = 11; 
                if (['p', 'l', 'm'].contains(key)) flex = 11; 

                return Flexible(
                  flex: flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: InkWell(
                      onTap: () {
                        if (isDel) {
                          if (_usernameController.text.isNotEmpty) {
                            _usernameController.text = _usernameController.text.substring(0, _usernameController.text.length - 1);
                          }
                        } else {
                          _usernameController.text += key;
                        }
                      },
                      child: Container(
                        height: 44, // Taller keys for better touch targets on mobile
                        decoration: BoxDecoration(
                          color: isRed ? redColor : Colors.white, // Same red as login button
                          borderRadius: BorderRadius.circular(6), 
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2), // Shadow pointing down like mechanical keys
                              blurRadius: 1, 
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          key,
                          style: TextStyle(
                            color: isRed ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
