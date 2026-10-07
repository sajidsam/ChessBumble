import 'package:flutter/material.dart';

const Color bgDark = Color(0xFF141414);
const Color cardDark = Color(0xFF1E1E1E);
const Color cardSurface = Color(0xFF282828);
const Color textWhite = Color(0xFFF0F0F0);
const Color textMuted = Color(0xFFA0A0A0);

class ProfilePage extends StatefulWidget {
  final String currentUsername;
  final String currentRating;
  final Function(String newUsername, String newRating)? onProfileUpdated;

  const ProfilePage({
    super.key,
    required this.currentUsername,
    required this.currentRating,
    this.onProfileUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String username;
  late String rating;

  @override
  void initState() {
    super.initState();
    username = widget.currentUsername;
    rating = widget.currentRating;
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: username);
    final ratingController = TextEditingController(text: rating);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
              style: TextStyle(color: textWhite, fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: textWhite, fontFamily: 'Roboto'),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: const TextStyle(color: textMuted),
                filled: true,
                fillColor: cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ratingController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: textWhite, fontFamily: 'Roboto'),
              decoration: InputDecoration(
                labelText: 'Rating (ELO)',
                labelStyle: const TextStyle(color: textMuted),
                filled: true,
                fillColor: cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: textMuted, fontFamily: 'Roboto')),
          ),
          ElevatedButton(
            onPressed: () {
              String newName = nameController.text.trim();
              String newRating = ratingController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  username = newName;
                  if (newRating.isNotEmpty) rating = newRating;
                });
                widget.onProfileUpdated?.call(username, rating);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: cardDark,
                    content: Text('Profile updated successfully', style: TextStyle(color: Colors.white)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // User Header Card (B&W Minimalist)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardSurface,
                          border: Border.all(color: Colors.white30, width: 2),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardDark, width: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Username
                  Text(
                    username,
                    style: const TextStyle(
                      color: textWhite,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Title badge & ELO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cardSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Text(
                          'MEMBER',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$rating ELO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Edit button
                  OutlinedButton.icon(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('Edit Details', style: TextStyle(color: Colors.white, fontFamily: 'Roboto')),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Performance / Stats Grid
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Performance Overview',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(child: _buildStatCard('Rapid', rating, Icons.timer_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard('Blitz', '1580', Icons.bolt_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard('Win Rate', '64%', Icons.pie_chart_outline)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildStatCard('Games', '42', Icons.sports_esports_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard('Won', '27', Icons.emoji_events_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard('Streak', '5 W', Icons.local_fire_department_outlined)),
              ],
            ),

            const SizedBox(height: 20),

            // Recent Matches History (Monochrome B&W list)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Matches',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            _buildMatchHistoryTile('vs Stockfish Bot (Medium)', 'Win (+8)', 'White • 24 moves', true),
            _buildMatchHistoryTile('vs GM_Hikaru_USA', 'Loss (-4)', 'Black • 38 moves', false),
            _buildMatchHistoryTile('vs QueenBumble_BD', 'Win (+10)', 'White • 19 moves', true),
            _buildMatchHistoryTile('vs MagnusFan99', 'Draw (+1)', 'White • 52 moves', null),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: textMuted,
              fontFamily: 'Roboto',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryTile(String opponent, String result, String detail, bool? isWin) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isWin == true
                  ? Colors.white
                  : (isWin == false ? Colors.white30 : Colors.white60),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    color: textMuted,
                    fontFamily: 'Roboto',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cardSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Text(
              result,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
