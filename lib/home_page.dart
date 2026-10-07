import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;
import 'info_feed_page.dart';

// Brand & Dark Theme Colors
const Color brandRed = Color(0xFFDD0004);
const Color bgDark = Color(0xFF161512); // Lichess / Chess.com rich dark
const Color cardDark = Color(0xFF21201D);
const Color cardSurface = Color(0xFF2B2925);
const Color textWhite = Color(0xFFECECEC);
const Color textMuted = Color(0xFF8B8987);

enum BoardTheme {
  wood,
  tournamentGreen,
  slate,
}

class BoardColors {
  final Color lightSquare;
  final Color darkSquare;
  final Color darkCoordOnLight;
  final Color lightCoordOnDark;
  final Color borderColor;

  const BoardColors({
    required this.lightSquare,
    required this.darkSquare,
    required this.darkCoordOnLight,
    required this.lightCoordOnDark,
    required this.borderColor,
  });
}

const Map<BoardTheme, BoardColors> boardColorThemes = {
  BoardTheme.wood: BoardColors(
    lightSquare: Color(0xFFF0D9B5),
    darkSquare: Color(0xFFB58863),
    darkCoordOnLight: Color(0xFFB58863),
    lightCoordOnDark: Color(0xFFF0D9B5),
    borderColor: Color(0xFF5C3A21),
  ),
  BoardTheme.tournamentGreen: BoardColors(
    lightSquare: Color(0xFFEEEED2),
    darkSquare: Color(0xFF769656),
    darkCoordOnLight: Color(0xFF769656),
    lightCoordOnDark: Color(0xFFEEEED2),
    borderColor: Color(0xFF3B4D2B),
  ),
  BoardTheme.slate: BoardColors(
    lightSquare: Color(0xFFDCE2E6),
    darkSquare: Color(0xFF7D949E),
    darkCoordOnLight: Color(0xFF7D949E),
    lightCoordOnDark: Color(0xFFDCE2E6),
    borderColor: Color(0xFF384347),
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

  // Board display settings
  bool isFlipped = false;
  BoardTheme currentTheme = BoardTheme.wood;

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _movesScrollController.dispose();
    super.dispose();
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
      whiteTime = initialTimeSeconds;
      blackTime = initialTimeSeconds;
    });
  }

  String _formatTime(int totalSeconds) {
    if (initialTimeSeconds == 0) return '∞';
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void onSquareTapped(String square) {
    if (chess.game_over) return;

    setState(() {
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
        }
      });
    }
  }

  void _undoMove() {
    if (moveHistory.isEmpty) return;
    setState(() {
      chess.undo();
      moveHistory.removeLast();
      if (sanHistory.isNotEmpty) sanHistory.removeLast();
      selectedSquare = null;
      validMoves = [];
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 26,
              height: 26,
            ),
            const SizedBox(width: 8),
            const Text(
              'ChessBumble',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Board Theme',
            icon: const Icon(Icons.palette_outlined, color: Colors.white70),
            onPressed: () {
              setState(() {
                if (currentTheme == BoardTheme.wood) {
                  currentTheme = BoardTheme.tournamentGreen;
                } else if (currentTheme == BoardTheme.tournamentGreen) {
                  currentTheme = BoardTheme.slate;
                } else {
                  currentTheme = BoardTheme.wood;
                }
              });
            },
          ),
          IconButton(
            tooltip: 'New Game',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _showNewGameConfirmDialog,
          ),
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
                  playerName: isFlipped ? 'White' : 'Black (Opponent)',
                  rating: '1600',
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
                    border: Border.all(color: colors.borderColor, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 16,
                        offset: Offset(0, 6),
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
                        bool isKingCheck = square == kingInCheckSquare;

                        // Embedded coordinates: Rank on first col, File on last row
                        bool showRankCoord = col == 0;
                        bool showFileCoord = row == 7;

                        Color sqColor = isLightSquare ? colors.lightSquare : colors.darkSquare;
                        Color coordColor = isLightSquare ? colors.darkCoordOnLight : colors.lightCoordOnDark;

                        return GestureDetector(
                          onTap: () => onSquareTapped(square),
                          child: Container(
                            color: sqColor,
                            child: Stack(
                              children: [
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
                  playerName: isFlipped ? 'Black (You)' : 'White (You)',
                  rating: '1650',
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

              // Bottom Action Toolbar (Professional Controls)
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
    ),);
  }

  Widget _buildPlayerCard({
    required bool isWhitePlayer,
    required String playerName,
    required String rating,
    required String timeString,
    required bool isActive,
    required List<String> capturedAssets,
    required int advantage,
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
              child: Image.asset(
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
                    Text(
                      playerName,
                      style: const TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($rating)',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 12,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color ?? Colors.white70, size: 22),
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
