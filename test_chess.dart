import 'package:chess/chess.dart' as ch;

void main() {
  final chess = ch.Chess();
  chess.move({'from': 'h2', 'to': 'h4'});
  var m = chess.history.first.move;
  print('From: ${m.from}, To: ${m.to}'); // from and to are integers
}
