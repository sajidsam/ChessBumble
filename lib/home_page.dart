import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;
import 'info_feed_page.dart';
import 'services/chess_ai.dart';
import 'services/api_service.dart';
import 'profile_page.dart';

// Brand & Dark Theme Colors
const Color brandRed = Color(0xFFDD0004);
const Color bgDark = Color(0xFF161512); // Lichess / Chess.com rich dark
const Color cardDark = Color(0xFF21201D);
const Color cardSurface = Color(0xFF2B2925);
const Color textWhite = Color(0xFFECECEC);
const Color textMuted = Color(0xFF8B8987);

enum BoardTheme {
  wood,
  liquidRed,
  tournamentGreen,
  slate,
}

class BoardColors {
  final Color lightSquare;
  final Color darkSquare;
  final Color darkCoordOnLight;
  final Color lightCoordOnDark;
  final Color borderColor;
  final String displayName;

  const BoardColors({
    required this.lightSquare,
    required this.darkSquare,
    required this.darkCoordOnLight,
    required this.lightCoordOnDark,
    required this.borderColor,
    required this.displayName,
  });
}

const Map<BoardTheme, BoardColors> boardColorThemes = {
  BoardTheme.wood: BoardColors(
    lightSquare: Color(0xFFF0D9B5),
    darkSquare: Color(0xFFB58863),
    darkCoordOnLight: Color(0xFFB58863),
    lightCoordOnDark: Color(0xFFF0D9B5),
    borderColor: Color(0xFF5C3A21),
    displayName: 'Classic Wood',
  ),
  BoardTheme.liquidRed: BoardColors(
    lightSquare: Color(0xFFFFFFFF),
    darkSquare: Color(0xFFCC0004),
    darkCoordOnLight: Color(0xFFCC0004),
    lightCoordOnDark: Color(0xFFFFFFFF),
    borderColor: Color(0xFF880002),
    displayName: 'Glossy Liquid Red',
  ),
  BoardTheme.tournamentGreen: BoardColors(
    lightSquare: Color(0xFFEEEED2),
    darkSquare: Color(0xFF769656),
    darkCoordOnLight: Color(0xFF769656),
    lightCoordOnDark: Color(0xFFEEEED2),
    borderColor: Color(0xFF3B4D2B),
    displayName: 'Tournament Green',
  ),
  BoardTheme.slate: BoardColors(
    lightSquare: Color(0xFFDCE2E6),
    darkSquare: Color(0xFF7D949E),
    darkCoordOnLight: Color(0xFF7D949E),
    lightCoordOnDark: Color(0xFFDCE2E6),
    borderColor: Color(0xFF384347),
    displayName: 'Midnight Slate',
  ),
};

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ch.Chess chess;
  String? selectedSquare;
  List<String> validMoves = [];
  List<String> moveHistory = []; // Tracks 'e2-e4' format for easter egg
  List<String> sanHistory = [];  // Tracks PGN/SAN moves (e.g. 'e4', 'Nf3')

  // Move highlights
  String? lastMoveFrom;
  String? lastMoveTo;

  // Hint highlights
  String? hintFrom;
  String? hintTo;

  // Board display settings
  bool isFlipped = false;
  BoardTheme currentTheme = BoardTheme.wood; // Defaults to previous wood as requested!

  // Game Mode & AI Settings
  bool isVsComputer = true;
  BotDifficulty botDifficulty = BotDifficulty.medium;
  bool isComputerThinking = false;
  bool userPlaysWhite = true;

  // Registered Player Info
  String currentUserName = 'bumble@sajid';
  String currentUserRating = '1650';

  // Opponent Info
  String opponentName = 'Stockfish Bot';
  String opponentRating = '1400';

  // Timer controls (in seconds)
  int initialTimeSeconds = 600; // 10 minutes default
  int whiteTime = 600;
  int blackTime = 600;
  Timer? _timer;
  bool isTimerRunning = false;

  final ScrollController _movesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    chess = ch.Chess();
    _updateOpponentProfile();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _movesScrollController.dispose();
    super.dispose();
  }

  void _updateOpponentProfile() {
    if (isVsComputer) {
      switch (botDifficulty) {
        case BotDifficulty.easy:
          opponentName = 'ChessBot (Easy)';
          opponentRating = '800';
          break;
        case BotDifficulty.medium:
          opponentName = 'ChessBot (Medium)';
          opponentRating = '1400';
          break;
        case BotDifficulty.hard:
          opponentName = 'ChessBot (Master)';
          opponentRating = '1850';
          break;
      }
    }
  }

  void _startTimerIfNeeded() {
    if (initialTimeSeconds == 0) return; // Unlimited
    if (isTimerRunning) return;

    isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (chess.game_over) {
        timer.cancel();
        isTimerRunning = false;
        return;
      }

      setState(() {
        if (chess.turn == ch.Color.WHITE) {
          if (whiteTime > 0) {
            whiteTime--;
          } else {
            timer.cancel();
            isTimerRunning = false;
            _showGameOverDialog('Time out! Black wins on time.');
          }
        } else {
          if (blackTime > 0) {
            blackTime--;
          } else {
            timer.cancel();
            isTimerRunning = false;
            _showGameOverDialog('Time out! White wins on time.');
          }
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    isTimerRunning = false;
  }

  void _resetGame() {
    _stopTimer();
    setState(() {
      chess = ch.Chess();
      selectedSquare = null;
      validMoves = [];
      moveHistory.clear();
      sanHistory.clear();
      lastMoveFrom = null;
      lastMoveTo = null;
      hintFrom = null;
      hintTo = null;
      whiteTime = initialTimeSeconds;
      blackTime = initialTimeSeconds;
      isComputerThinking = false;
    });

    // If user plays black vs computer, computer plays first
    if (isVsComputer && !userPlaysWhite) {
      _triggerComputerMove();
    }
  }

  String _formatTime(int totalSeconds) {
    if (initialTimeSeconds == 0) return '∞';
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void onSquareTapped(String square) {
    if (chess.game_over || isComputerThinking) return;

    // Check if it's user's turn when playing vs computer
    if (isVsComputer) {
      bool isUserTurn = (userPlaysWhite && chess.turn == ch.Color.WHITE) ||
                        (!userPlaysWhite && chess.turn == ch.Color.BLACK);
      if (!isUserTurn) return;
    }

    setState(() {
      // Clear hint on tap
      hintFrom = null;
      hintTo = null;

      if (selectedSquare == null) {
        // Select piece if it belongs to current player's turn
        var piece = chess.get(square);
        if (piece != null && piece.color == chess.turn) {
          selectedSquare = square;
          validMoves = chess
              .moves({'square': square, 'verbose': true})
              .map((m) => m['to'] as String)
              .toList();
        }
      } else {
        // Tapping the same square -> deselect
        if (selectedSquare == square) {
          selectedSquare = null;
          validMoves = [];
          return;
        }

        // Tapping another piece of current player -> change selection
        var piece = chess.get(square);
        if (piece != null && piece.color == chess.turn) {
          selectedSquare = square;
          validMoves = chess
              .moves({'square': square, 'verbose': true})
              .map((m) => m['to'] as String)
              .toList();
          return;
        }

        // Destination tapped
        if (validMoves.contains(square)) {
          var movingPiece = chess.get(selectedSquare!);
          bool isPawn = movingPiece?.type.name == 'p';
          bool isPromotionRank = (movingPiece?.color == ch.Color.WHITE && square[1] == '8') ||
                                 (movingPiece?.color == ch.Color.BLACK && square[1] == '1');

          if (isPawn && isPromotionRank) {
            _showPromotionPicker(selectedSquare!, square);
          } else {
            _executeMove(selectedSquare!, square, null);
          }
        }

        selectedSquare = null;
        validMoves = [];
      }
    });
  }

  void _showPromotionPicker(String from, String to) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String colorPrefix = chess.turn == ch.Color.WHITE ? 'w' : 'b';
        final pieces = [
          {'type': 'q', 'label': 'Queen', 'asset': 'assets/images/chess/${colorPrefix}q.png'},
          {'type': 'r', 'label': 'Rook', 'asset': 'assets/images/chess/${colorPrefix}r.png'},
          {'type': 'b', 'label': 'Bishop', 'asset': 'assets/images/chess/${colorPrefix}b.png'},
          {'type': 'n', 'label': 'Knight', 'asset': 'assets/images/chess/${colorPrefix}n.png'},
        ];

        return AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Promote Pawn',
            textAlign: TextAlign.center,
            style: TextStyle(color: textWhite, fontFamily: 'Roboto', fontWeight: FontWeight.bold),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: pieces.map((p) {
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _executeMove(from, to, p['type']);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Image.asset(p['asset']!, width: 44, height: 44),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _executeMove(String from, String to, String? promotion) {
    // Determine SAN notation before making move
    var verboseMoves = chess.moves({'verbose': true});
    String moveSan = '$from-$to';
    for (var m in verboseMoves) {
      if (m['from'] == from && m['to'] == to) {
        moveSan = m['san'] ?? moveSan;
        break;
      }
    }

    bool moveSuccess = chess.move({
      'from': from,
      'to': to,
      ...?promotion != null ? {'promotion': promotion} : null,
    });

    if (moveSuccess) {
      _startTimerIfNeeded();
      setState(() {
        lastMoveFrom = from;
        lastMoveTo = to;
        hintFrom = null;
        hintTo = null;
        moveHistory.add('$from-$to');
        sanHistory.add(moveSan);

        // Auto-scroll moves tape to right
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_movesScrollController.hasClients) {
            _movesScrollController.animateTo(
              _movesScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });

        _checkEasterEgg();

        // Game over checks
        if (chess.game_over) {
          _stopTimer();
          if (chess.in_checkmate) {
            String winner = chess.turn == ch.Color.WHITE ? 'Black' : 'White';
            _showGameOverDialog('Checkmate! $winner won the match!');
          } else if (chess.in_draw) {
            _showGameOverDialog('Draw! Game ended peacefully.');
          }
        } else {
          // If playing vs computer and it is now computer's turn
          if (isVsComputer) {
            bool isComputerTurn = (userPlaysWhite && chess.turn == ch.Color.BLACK) ||
                                  (!userPlaysWhite && chess.turn == ch.Color.WHITE);
            if (isComputerTurn) {
              _triggerComputerMove();
            }
          }
        }
      });
    }
  }

  void _triggerComputerMove() {
    setState(() {
      isComputerThinking = true;
    });

    int thinkDelay = botDifficulty == BotDifficulty.easy
        ? 450
        : (botDifficulty == BotDifficulty.medium ? 700 : 950);

    Future.delayed(Duration(milliseconds: thinkDelay), () {
      if (!mounted || !isVsComputer || chess.game_over) {
        if (mounted) setState(() => isComputerThinking = false);
        return;
      }

      var bestMove = ChessAi.getBestMove(chess, botDifficulty);
      if (bestMove != null) {
        _executeMove(bestMove['from'], bestMove['to'], bestMove['promotion'] ?? 'q');
      }

      if (mounted) {
        setState(() {
          isComputerThinking = false;
        });
      }
    });
  }

  void _showHint() {
    if (chess.game_over || isComputerThinking) return;

    var bestMove = ChessAi.getHint(chess);
    if (bestMove != null) {
      setState(() {
        hintFrom = bestMove['from'];
        hintTo = bestMove['to'];
      });

      String movingPiece = chess.get(hintFrom!)?.type.name.toUpperCase() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cardDark,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amberAccent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hint: Move $movingPiece from ${hintFrom!.toUpperCase()} to ${hintTo!.toUpperCase()} (${bestMove['san']})',
                  style: const TextStyle(color: textWhite, fontFamily: 'Roboto', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _undoMove() {
    if (moveHistory.isEmpty || isComputerThinking) return;
    setState(() {
      chess.undo();
      moveHistory.removeLast();
      if (sanHistory.isNotEmpty) sanHistory.removeLast();

      // If playing vs computer, undo computer's move too so it's user's turn
      if (isVsComputer && moveHistory.isNotEmpty) {
        chess.undo();
        moveHistory.removeLast();
        if (sanHistory.isNotEmpty) sanHistory.removeLast();
      }

      selectedSquare = null;
      validMoves = [];
      hintFrom = null;
      hintTo = null;
      if (moveHistory.isNotEmpty) {
        var parts = moveHistory.last.split('-');
        lastMoveFrom = parts[0];
        lastMoveTo = parts[1];
      } else {
        lastMoveFrom = null;
        lastMoveTo = null;
      }
    });
  }

  void _checkEasterEgg() {
    final List<String> easterEggPattern = ['h2-h4', 'd7-d6', 'g1-f3'];
    if (moveHistory.length == 3) {
      bool isMatch = true;
      for (int i = 0; i < 3; i++) {
        if (moveHistory[i] != easterEggPattern[i]) {
          isMatch = false;
          break;
        }
      }
      if (isMatch) {
        moveHistory.clear();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InfoFeedPage()),
            );
          }
        });
      }
    }
  }

  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Game Over',
          style: TextStyle(color: textWhite, fontFamily: 'Roboto', fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: textWhite, fontFamily: 'Roboto', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review Board', style: TextStyle(color: textMuted, fontFamily: 'Roboto')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('New Game', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String getPieceAsset(ch.Piece? piece) {
    if (piece == null) return '';
    String color = piece.color == ch.Color.WHITE ? 'w' : 'b';
    String type = piece.type.name.toLowerCase();
    return 'assets/images/chess/$color$type.png';
  }

  // Calculate captured pieces and material advantage
  Map<String, dynamic> _calculateMaterialAndCaptured() {
    final initialCounts = {'p': 8, 'n': 2, 'b': 2, 'r': 2, 'q': 1};
    final pieceValues = {'p': 1, 'n': 3, 'b': 3, 'r': 5, 'q': 9};

    Map<String, int> whiteOnBoard = {'p': 0, 'n': 0, 'b': 0, 'r': 0, 'q': 0};
    Map<String, int> blackOnBoard = {'p': 0, 'n': 0, 'b': 0, 'r': 0, 'q': 0};

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String sq = '${String.fromCharCode('a'.codeUnitAt(0) + c)}${r + 1}';
        var p = chess.get(sq);
        if (p != null) {
          String type = p.type.name.toLowerCase();
          if (p.color == ch.Color.WHITE && whiteOnBoard.containsKey(type)) {
            whiteOnBoard[type] = whiteOnBoard[type]! + 1;
          } else if (p.color == ch.Color.BLACK && blackOnBoard.containsKey(type)) {
            blackOnBoard[type] = blackOnBoard[type]! + 1;
          }
        }
      }
    }

    List<String> capturedByWhite = []; // Black pieces taken
    List<String> capturedByBlack = []; // White pieces taken

    int whiteMaterial = 0;
    int blackMaterial = 0;

    for (var key in initialCounts.keys) {
      int blackDiff = initialCounts[key]! - (blackOnBoard[key] ?? 0);
      for (int i = 0; i < blackDiff; i++) {
        capturedByWhite.add('assets/images/chess/b$key.png');
      }

      int whiteDiff = initialCounts[key]! - (whiteOnBoard[key] ?? 0);
      for (int i = 0; i < whiteDiff; i++) {
        capturedByBlack.add('assets/images/chess/w$key.png');
      }

      whiteMaterial += (whiteOnBoard[key] ?? 0) * pieceValues[key]!;
      blackMaterial += (blackOnBoard[key] ?? 0) * pieceValues[key]!;
    }

    int whiteAdvantage = whiteMaterial - blackMaterial;
    int blackAdvantage = blackMaterial - whiteMaterial;

    return {
      'capturedByWhite': capturedByWhite,
      'capturedByBlack': capturedByBlack,
      'whiteAdvantage': whiteAdvantage > 0 ? whiteAdvantage : 0,
      'blackAdvantage': blackAdvantage > 0 ? blackAdvantage : 0,
    };
  }

  // Find the king's square if in check
  String? _findKingInCheck() {
    if (!chess.in_check) return null;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String sq = '${String.fromCharCode('a'.codeUnitAt(0) + c)}${r + 1}';
        var p = chess.get(sq);
        if (p != null && p.type == ch.PieceType.KING && p.color == chess.turn) {
          return sq;
        }
      }
    }
    return null;
  }

  // --- Registration Dialog ---
  void _showRegistrationDialog() {
    final nameController = TextEditingController(text: currentUserName == 'You' ? '' : currentUserName);
    final ratingController = TextEditingController(text: currentUserRating);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.person_add_alt_1, color: brandRed),
            SizedBox(width: 8),
            Text(
              'Register Player Profile',
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
                labelText: 'Player Username / MSI Code',
                labelStyle: const TextStyle(color: textMuted),
                hintText: 'e.g. GrandmasterSam',
                hintStyle: TextStyle(color: Colors.white24),
                filled: true,
                fillColor: cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ratingController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: textWhite, fontFamily: 'Roboto'),
              decoration: InputDecoration(
                labelText: 'Player Rating (ELO)',
                labelStyle: const TextStyle(color: textMuted),
                hintText: 'e.g. 1650',
                filled: true,
                fillColor: cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
            onPressed: () async {
              String name = nameController.text.trim();
              String rating = ratingController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  currentUserName = name;
                  if (rating.isNotEmpty) currentUserRating = rating;
                });
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);

                // Optional background sync with backend
                try {
                  await ApiService.login(name);
                } catch (_) {}

                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green.shade800,
                    content: Text('Profile registered: $name ($currentUserRating ELO)'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Register', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Find Players Dialog ---
  void _showFindPlayersDialog() {
    final searchController = TextEditingController();
    List<Map<String, String>> allPlayers = [
      {'name': 'GM_Hikaru_USA', 'rating': '2550', 'flag': '🇺🇸', 'status': 'Online'},
      {'name': 'QueenBumble_BD', 'rating': '1780', 'flag': '🇧🇩', 'status': 'Online'},
      {'name': 'MagnusFan99', 'rating': '1920', 'flag': '🇳🇴', 'status': 'In Game'},
      {'name': 'KnightRider_SAM', 'rating': '1640', 'flag': '🇧🇩', 'status': 'Online'},
      {'name': 'ChessTitan_UK', 'rating': '1450', 'flag': '🇬🇧', 'status': 'Online'},
      {'name': 'PawnStorm_DE', 'rating': '1380', 'flag': '🇩🇪', 'status': 'Online'},
    ];

    List<Map<String, String>> filteredPlayers = List.from(allPlayers);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Icon(Icons.travel_explore, color: brandRed, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Find Players (Matchmaking)',
                        style: TextStyle(color: textWhite, fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: textWhite, fontFamily: 'Roboto'),
                    onChanged: (val) {
                      setModalState(() {
                        filteredPlayers = allPlayers
                            .where((p) => p['name']!.toLowerCase().contains(val.toLowerCase()) ||
                                          p['rating']!.contains(val))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search player username or rating...',
                      hintStyle: const TextStyle(color: textMuted),
                      prefixIcon: const Icon(Icons.search, color: textMuted),
                      filled: true,
                      fillColor: cardSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Active Online Players', style: TextStyle(color: textMuted, fontSize: 13, fontFamily: 'Roboto')),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      itemCount: filteredPlayers.length,
                      itemBuilder: (context, idx) {
                        final p = filteredPlayers[idx];
                        bool isAvailable = p['status'] == 'Online';
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: cardSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(p['flag']!, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['name']!,
                                      style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                                    ),
                                    Text(
                                      '${p['rating']} ELO • ${p['status']}',
                                      style: TextStyle(
                                        color: isAvailable ? Colors.greenAccent : textMuted,
                                        fontSize: 12,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    isVsComputer = false; // Playing vs chosen player
                                    opponentName = p['name']!;
                                    opponentRating = p['rating']!;
                                    _resetGame();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: brandRed,
                                      content: Text('Match started against ${p['name']}!'),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Challenge', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Computer Level Selector Dialog ---
  void _showGameModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.smart_toy_outlined, color: brandRed),
            SizedBox(width: 8),
            Text(
              'Game Mode & Level',
              style: TextStyle(color: textWhite, fontFamily: 'Roboto', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Play vs Computer', style: TextStyle(color: textWhite, fontFamily: 'Roboto')),
              subtitle: Text(
                isVsComputer ? 'AI opponent enabled' : 'Pass & Play (2 Players)',
                style: const TextStyle(color: textMuted, fontSize: 12, fontFamily: 'Roboto'),
              ),
              value: isVsComputer,
              activeThumbColor: brandRed,
              onChanged: (val) {
                setState(() {
                  isVsComputer = val;
                  if (!isVsComputer) {
                    opponentName = 'Player 2 (Black)';
                    opponentRating = '1600';
                  } else {
                    _updateOpponentProfile();
                  }
                });
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Computer Difficulty:', style: TextStyle(color: textMuted, fontFamily: 'Roboto', fontSize: 13)),
            ),
            const SizedBox(height: 8),
            _buildDifficultyOption(
              BotDifficulty.easy,
              'Easy (Level 1 • 800 ELO)',
              'Casual play, beginner moves',
              Colors.greenAccent,
            ),
            _buildDifficultyOption(
              BotDifficulty.medium,
              'Medium (Level 2 • 1400 ELO)',
              'Club strength, tactical moves',
              Colors.amberAccent,
            ),
            _buildDifficultyOption(
              BotDifficulty.hard,
              'Hard (Level 3 • 1850 ELO)',
              'Minimax master, deep evaluation',
              Colors.redAccent,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
            child: const Text('Done', style: TextStyle(fontFamily: 'Roboto')),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(BotDifficulty level, String title, String subtitle, Color badgeColor) {
    bool isSelected = isVsComputer && botDifficulty == level;
    return InkWell(
      onTap: () {
        setState(() {
          isVsComputer = true;
          botDifficulty = level;
          _updateOpponentProfile();
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cardSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? badgeColor : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontFamily: 'Roboto', fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 11, fontFamily: 'Roboto')),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check, color: Colors.greenAccent, size: 18),
          ],
        ),
      ),
    );
  }

  void _cycleBoardTheme() {
    setState(() {
      if (currentTheme == BoardTheme.wood) {
        currentTheme = BoardTheme.liquidRed;
      } else if (currentTheme == BoardTheme.liquidRed) {
        currentTheme = BoardTheme.tournamentGreen;
      } else if (currentTheme == BoardTheme.tournamentGreen) {
        currentTheme = BoardTheme.slate;
      } else {
        currentTheme = BoardTheme.wood;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: cardDark,
        duration: const Duration(seconds: 1),
        content: Text('Board: ${boardColorThemes[currentTheme]!.displayName}'),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          currentUsername: currentUserName,
          currentRating: currentUserRating,
          onProfileUpdated: (newName, newRating) {
            setState(() {
              currentUserName = newName;
              currentUserRating = newRating;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = boardColorThemes[currentTheme]!;
    final materialData = _calculateMaterialAndCaptured();
    final kingInCheckSquare = _findKingInCheck();

    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive board sizing: fits mobile screens perfectly with clean margin
    double boardSize = screenWidth > 500 ? 440 : (screenWidth - 20);
    double squareSize = boardSize / 8;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgDark,
        primaryColor: brandRed,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
      ),
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          backgroundColor: bgDark,
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 170,
          leading: Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: _navigateToProfile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.white, // Pure B&W
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 115),
                        child: Text(
                          currentUserName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white, // Pure B&W
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            // Board Theme quick switcher (B&W white icon)
            IconButton(
              iconSize: 22,
              tooltip: 'Board Theme',
              icon: const Icon(Icons.palette_outlined, color: Colors.white),
              onPressed: _cycleBoardTheme,
            ),
            // Popup menu for Profile, Mode, Players, Theme, New Game (Strictly B&W)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
              color: cardDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white24, width: 1),
              ),
              onSelected: (val) {
                if (val == 'profile') _navigateToProfile();
                if (val == 'mode') _showGameModeDialog();
                if (val == 'players') _showFindPlayersDialog();
                if (val == 'theme') _cycleBoardTheme();
                if (val == 'new_game') _showNewGameConfirmDialog();
              },
              itemBuilder: (context) => [
                // Profile Item (B&W)
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Profile',
                        style: TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Game Mode & Level (B&W)
                PopupMenuItem(
                  value: 'mode',
                  child: Row(
                    children: [
                      Icon(
                        isVsComputer ? Icons.smart_toy_outlined : Icons.people_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isVsComputer ? 'Mode: Bot (${botDifficulty.name.toUpperCase()})' : 'Mode: Pass & Play',
                        style: const TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Find Players (B&W)
                const PopupMenuItem(
                  value: 'players',
                  child: Row(
                    children: [
                      Icon(Icons.travel_explore, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Find Players',
                        style: TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Board Theme (B&W)
                const PopupMenuItem(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Board Theme',
                        style: TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(color: Colors.white24),
                // New Game (B&W)
                const PopupMenuItem(
                  value: 'new_game',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'New Game',
                        style: TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),

                // Top Section: Opponent Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: _buildPlayerCard(
                    isWhitePlayer: isFlipped ? true : false,
                    playerName: isFlipped ? currentUserName : opponentName,
                    rating: isFlipped ? currentUserRating : opponentRating,
                    timeString: _formatTime(isFlipped ? whiteTime : blackTime),
                    isActive: isFlipped
                        ? chess.turn == ch.Color.WHITE && !chess.game_over
                        : chess.turn == ch.Color.BLACK && !chess.game_over,
                    capturedAssets: isFlipped
                        ? (materialData['capturedByWhite'] as List<String>)
                        : (materialData['capturedByBlack'] as List<String>),
                    advantage: isFlipped
                        ? (materialData['whiteAdvantage'] as int)
                        : (materialData['blackAdvantage'] as int),
                    isThinking: !isFlipped && isComputerThinking,
                  ),
                ),

                const SizedBox(height: 8),

                // Center Section: Chess Board with embedded coordinates
                Center(
                  child: Container(
                    width: boardSize,
                    height: boardSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.borderColor, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: currentTheme == BoardTheme.liquidRed
                              ? const Color(0x66DD0004)
                              : Colors.black54,
                          blurRadius: currentTheme == BoardTheme.liquidRed ? 20 : 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                        itemCount: 64,
                        itemBuilder: (context, index) {
                          int row = index ~/ 8;
                          int col = index % 8;

                          // Flip board calculation
                          int actualRow = isFlipped ? 7 - row : row;
                          int actualCol = isFlipped ? 7 - col : col;

                          bool isLightSquare = (actualRow + actualCol) % 2 == 0;
                          String file = String.fromCharCode('a'.codeUnitAt(0) + actualCol);
                          String rank = '${8 - actualRow}';
                          String square = '$file$rank';

                          ch.Piece? piece = chess.get(square);
                          bool isSelected = selectedSquare == square;
                          bool isValidDest = validMoves.contains(square);
                          bool isLastMove = square == lastMoveFrom || square == lastMoveTo;
                          bool isHint = square == hintFrom || square == hintTo;
                          bool isKingCheck = square == kingInCheckSquare;

                          // Embedded coordinates: Rank on first col, File on last row
                          bool showRankCoord = col == 0;
                          bool showFileCoord = row == 7;

                          Color sqColor = isLightSquare ? colors.lightSquare : colors.darkSquare;
                          Color coordColor = isLightSquare ? colors.darkCoordOnLight : colors.lightCoordOnDark;

                          // Special glossy styling for Liquid Red theme
                          Widget squareBg;
                          if (currentTheme == BoardTheme.liquidRed) {
                            if (!isLightSquare) {
                              squareBg = Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF2E32), // Liquid gloss specular reflection
                                      Color(0xFFDD0004), // Vibrant rich liquid red
                                      Color(0xFF880002), // Deep ruby shadow
                                    ],
                                    stops: [0.0, 0.45, 1.0],
                                  ),
                                ),
                              );
                            } else {
                              squareBg = Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFF1F1F5),
                                    ],
                                  ),
                                ),
                              );
                            }
                          } else {
                            squareBg = Container(color: sqColor);
                          }

                          return GestureDetector(
                            onTap: () => onSquareTapped(square),
                            child: Stack(
                              children: [
                                squareBg,

                                // Last move soft highlight
                                if (isLastMove)
                                  Container(
                                    color: const Color(0x66F7F769), // Translucent yellow
                                  ),

                                // Selected square highlight
                                if (isSelected)
                                  Container(
                                    color: const Color(0x88F5D77F), // Warm gold highlight
                                  ),

                                // Hint move highlight (Electric Cyan)
                                if (isHint)
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFF00E5FF), width: 3),
                                      color: const Color(0x5500E5FF),
                                    ),
                                  ),

                                // King in check warning highlight
                                if (isKingCheck)
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.redAccent.withValues(alpha: 0.85),
                                          Colors.red.withValues(alpha: 0.3),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Rank coordinate (top-left)
                                if (showRankCoord)
                                  Positioned(
                                    top: 2,
                                    left: 3,
                                    child: Text(
                                      rank,
                                      style: TextStyle(
                                        color: coordColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ),

                                // File coordinate (bottom-right)
                                if (showFileCoord)
                                  Positioned(
                                    bottom: 1,
                                    right: 3,
                                    child: Text(
                                      file,
                                      style: TextStyle(
                                        color: coordColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ),

                                // Piece Image
                                if (piece != null)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Image.asset(
                                        getPieceAsset(piece),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),

                                // Valid move hint: Dot for empty, Ring for capture
                                if (isValidDest)
                                  Center(
                                    child: piece != null
                                        ? Container(
                                            width: squareSize * 0.88,
                                            height: squareSize * 0.88,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.black.withValues(alpha: 0.35),
                                                width: 3.5,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: squareSize * 0.28,
                                            height: squareSize * 0.28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black.withValues(alpha: 0.24),
                                            ),
                                          ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Player Card (Bottom - User)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: _buildPlayerCard(
                    isWhitePlayer: isFlipped ? false : true,
                    playerName: isFlipped ? opponentName : '$currentUserName (You)',
                    rating: isFlipped ? opponentRating : currentUserRating,
                    timeString: _formatTime(isFlipped ? blackTime : whiteTime),
                    isActive: isFlipped
                        ? chess.turn == ch.Color.BLACK && !chess.game_over
                        : chess.turn == ch.Color.WHITE && !chess.game_over,
                    capturedAssets: isFlipped
                        ? (materialData['capturedByBlack'] as List<String>)
                        : (materialData['capturedByWhite'] as List<String>),
                    advantage: isFlipped
                        ? (materialData['blackAdvantage'] as int)
                        : (materialData['whiteAdvantage'] as int),
                    isThinking: isFlipped && isComputerThinking,
                  ),
                ),

                const SizedBox(height: 8),

                // Live Move Notation Bar (PGN Ticker)
                Container(
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 14.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: sanHistory.isEmpty
                      ? const Center(
                          child: Text(
                            'Game started. Make your move.',
                            style: TextStyle(color: textMuted, fontSize: 13, fontFamily: 'Roboto'),
                          ),
                        )
                      : ListView.builder(
                          controller: _movesScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: (sanHistory.length + 1) ~/ 2,
                          itemBuilder: (context, pairIndex) {
                            int whiteIdx = pairIndex * 2;
                            int blackIdx = whiteIdx + 1;
                            int moveNumber = pairIndex + 1;

                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$moveNumber. ',
                                    style: const TextStyle(
                                      color: textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: whiteIdx == sanHistory.length - 1
                                          ? brandRed.withValues(alpha: 0.3)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sanHistory[whiteIdx],
                                      style: const TextStyle(
                                        color: textWhite,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ),
                                  if (blackIdx < sanHistory.length) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: blackIdx == sanHistory.length - 1
                                            ? brandRed.withValues(alpha: 0.3)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        sanHistory[blackIdx],
                                        style: const TextStyle(
                                          color: textWhite,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 8),

                // Bottom Action Toolbar (Professional Controls + Hint button)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14.0),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Hint Button!
                      _buildToolbarButton(
                        icon: Icons.lightbulb_outline,
                        tooltip: 'Show Best Move Hint',
                        label: 'Hint',
                        color: Colors.amberAccent,
                        onTap: _showHint,
                      ),
                      _buildToolbarButton(
                        icon: Icons.flip_camera_android_outlined,
                        tooltip: 'Flip Board',
                        label: 'Flip',
                        onTap: () {
                          setState(() {
                            isFlipped = !isFlipped;
                          });
                        },
                      ),
                      _buildToolbarButton(
                        icon: Icons.undo,
                        tooltip: 'Undo Move',
                        label: 'Undo',
                        onTap: _undoMove,
                      ),
                      _buildToolbarButton(
                        icon: Icons.timer_outlined,
                        tooltip: 'Time Control',
                        label: initialTimeSeconds == 0 ? '∞' : '${initialTimeSeconds ~/ 60}m',
                        onTap: _cycleTimeControl,
                      ),
                      _buildToolbarButton(
                        icon: Icons.flag_outlined,
                        tooltip: 'Resign',
                        label: 'Resign',
                        color: Colors.redAccent.shade100,
                        onTap: _showResignConfirmDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required bool isWhitePlayer,
    required String playerName,
    required String rating,
    required String timeString,
    required bool isActive,
    required List<String> capturedAssets,
    required int advantage,
    bool isThinking = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Player Avatar Circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isWhitePlayer ? Colors.white : const Color(0xFF2E2C29),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Center(
              child: isThinking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                    )
                  : Image.asset(
                      isWhitePlayer ? 'assets/images/chess/wp.png' : 'assets/images/chess/bp.png',
                      width: 22,
                      height: 22,
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Player Name & Captured Pieces Tray
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isThinking ? '$playerName (Thinking...)' : playerName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isThinking ? Colors.amberAccent : textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($rating)',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Captured pieces list & Advantage pill
                Row(
                  children: [
                    if (capturedAssets.isNotEmpty)
                      Expanded(
                        child: SizedBox(
                          height: 16,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: capturedAssets.length,
                            itemBuilder: (context, idx) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 2.0),
                                child: Image.asset(
                                  capturedAssets[idx],
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    if (advantage > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+$advantage',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Digital Clock Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2A3D2A) : cardSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? Colors.greenAccent : Colors.white12,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                Text(
                  timeString,
                  style: TextStyle(
                    color: isActive ? Colors.greenAccent : textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color ?? Colors.white70, size: 21),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color ?? Colors.white70,
                  fontSize: 11,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleTimeControl() {
    final times = [600, 300, 180, 0]; // 10m, 5m, 3m, unlimited
    int nextIdx = (times.indexOf(initialTimeSeconds) + 1) % times.length;
    setState(() {
      initialTimeSeconds = times[nextIdx];
      whiteTime = initialTimeSeconds;
      blackTime = initialTimeSeconds;
    });
  }

  void _showNewGameConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('New Game?', style: TextStyle(color: textWhite, fontFamily: 'Roboto')),
        content: const Text(
          'Are you sure you want to restart this game?',
          style: TextStyle(color: textMuted, fontFamily: 'Roboto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: textMuted, fontFamily: 'Roboto')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart', style: TextStyle(fontFamily: 'Roboto')),
          ),
        ],
      ),
    );
  }

  void _showResignConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Resign Game?', style: TextStyle(color: textWhite, fontFamily: 'Roboto')),
        content: const Text(
          'Do you want to forfeit this game?',
          style: TextStyle(color: textMuted, fontFamily: 'Roboto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: textMuted, fontFamily: 'Roboto')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopTimer();
              String winner = chess.turn == ch.Color.WHITE ? 'Black' : 'White';
              _showGameOverDialog('$winner won by resignation.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resign', style: TextStyle(fontFamily: 'Roboto')),
          ),
        ],
      ),
    );
  }
}
