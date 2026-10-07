import 'dart:math';
import 'package:chess/chess.dart' as ch;

enum BotDifficulty {
  easy,   // Level 1 (~800 ELO)
  medium, // Level 2 (~1400 ELO)
  hard,   // Level 3 (~1850 ELO)
}

class ChessMoveRecommendation {
  final String from;
  final String to;
  final String? promotion;
  final String san;
  final int score;

  ChessMoveRecommendation({
    required this.from,
    required this.to,
    this.promotion,
    required this.san,
    required this.score,
  });
}

class ChessAi {
  static final Random _rng = Random();

  // Piece values in centipawns
  static const Map<String, int> pieceValues = {
    'p': 100,
    'n': 320,
    'b': 330,
    'r': 500,
    'q': 900,
    'k': 20000,
  };

  // Positional tables (from White's perspective; mirrored for Black)
  static const List<int> pawnTable = [
    0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0
  ];

  static const List<int> knightTable = [
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  0,  0,  0,-20,-40,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -30,  5, 15, 20, 20, 15,  5,-30,
    -30,  0, 15, 20, 20, 15,  0,-30,
    -30,  5, 10, 15, 15, 10,  5,-30,
    -40,-20,  0,  5,  5,  0,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50,
  ];

  static const List<int> bishopTable = [
    -20,-10,-10,-10,-10,-10,-10,-20,
    -10,  0,  0,  0,  0,  0,  0,-10,
    -10,  0,  5, 10, 10,  5,  0,-10,
    -10,  5,  5, 10, 10,  5,  5,-10,
    -10,  0, 10, 10, 10, 10,  0,-10,
    -10, 10, 10, 10, 10, 10, 10,-10,
    -10,  5,  0,  0,  0,  0,  5,-10,
    -20,-10,-10,-10,-10,-10,-10,-20,
  ];

  /// Get best move based on difficulty
  static Map<String, dynamic>? getBestMove(ch.Chess game, BotDifficulty difficulty) {
    var moves = game.moves({'verbose': true});
    if (moves.isEmpty) return null;

    if (difficulty == BotDifficulty.easy) {
      // Easy: mostly random, occasional capture
      List<dynamic> captures = moves.where((m) => m['captured'] != null).toList();
      if (captures.isNotEmpty && _rng.nextDouble() < 0.45) {
        return captures[_rng.nextInt(captures.length)] as Map<String, dynamic>;
      }
      return moves[_rng.nextInt(moves.length)] as Map<String, dynamic>;
    }

    int depth = difficulty == BotDifficulty.medium ? 2 : 3;
    bool isWhite = game.turn == ch.Color.WHITE;

    int bestScore = isWhite ? -999999 : 999999;
    Map<String, dynamic>? bestMove = moves.first as Map<String, dynamic>;

    // Shuffle moves slightly for variety among equally good moves
    List<dynamic> shuffledMoves = List.from(moves)..shuffle(_rng);

    for (var m in shuffledMoves) {
      String from = m['from'];
      String to = m['to'];
      String? promotion = m['promotion'];

      game.move({'from': from, 'to': to, ...?promotion != null ? {'promotion': promotion} : null});
      int score = _minimax(game, depth - 1, -999999, 999999, !isWhite);
      game.undo();

      if (isWhite) {
        if (score > bestScore) {
          bestScore = score;
          bestMove = m as Map<String, dynamic>;
        }
      } else {
        if (score < bestScore) {
          bestScore = score;
          bestMove = m as Map<String, dynamic>;
        }
      }
    }

    return bestMove;
  }

  /// Minimax with Alpha-Beta Pruning
  static int _minimax(ch.Chess game, int depth, int alpha, int beta, bool isMaximizing) {
    if (depth == 0 || game.game_over) {
      return _evaluateBoard(game);
    }

    var moves = game.moves({'verbose': true});
    if (moves.isEmpty) {
      return _evaluateBoard(game);
    }

    if (isMaximizing) {
      int maxEval = -999999;
      for (var m in moves) {
        game.move({'from': m['from'], 'to': m['to'], ...?m['promotion'] != null ? {'promotion': m['promotion']} : null});
        int evaluation = _minimax(game, depth - 1, alpha, beta, false);
        game.undo();
        maxEval = max(maxEval, evaluation);
        alpha = max(alpha, evaluation);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (var m in moves) {
        game.move({'from': m['from'], 'to': m['to'], ...?m['promotion'] != null ? {'promotion': m['promotion']} : null});
        int evaluation = _minimax(game, depth - 1, alpha, beta, true);
        game.undo();
        minEval = min(minEval, evaluation);
        beta = min(beta, evaluation);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  /// Board static evaluation: Positive favors White, Negative favors Black
  static int _evaluateBoard(ch.Chess game) {
    if (game.in_checkmate) {
      return game.turn == ch.Color.WHITE ? -99999 : 99999;
    }
    if (game.in_draw) {
      return 0;
    }

    int score = 0;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String sq = '${String.fromCharCode('a'.codeUnitAt(0) + c)}${r + 1}';
        var piece = game.get(sq);
        if (piece == null) continue;

        String type = piece.type.name.toLowerCase();
        int baseVal = pieceValues[type] ?? 0;

        int posVal = 0;
        int sqIdx = (7 - r) * 8 + c; // standard index from top to bottom
        if (type == 'p') {
          posVal = piece.color == ch.Color.WHITE ? pawnTable[sqIdx] : pawnTable[63 - sqIdx];
        } else if (type == 'n') {
          posVal = piece.color == ch.Color.WHITE ? knightTable[sqIdx] : knightTable[63 - sqIdx];
        } else if (type == 'b') {
          posVal = piece.color == ch.Color.WHITE ? bishopTable[sqIdx] : bishopTable[63 - sqIdx];
        }

        if (piece.color == ch.Color.WHITE) {
          score += baseVal + posVal;
        } else {
          score -= (baseVal + posVal);
        }
      }
    }

    return score;
  }

  /// Generate a smart hint for the player whose turn it is
  static Map<String, dynamic>? getHint(ch.Chess game) {
    return getBestMove(game, BotDifficulty.hard);
  }
}
