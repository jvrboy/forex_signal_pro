import 'package:equatable/equatable.dart';

class Tick extends Equatable {
  final String symbol;
  final double quote;
  final int epoch;
  final double? bid;
  final double? ask;

  const Tick({
    required this.symbol,
    required this.quote,
    required this.epoch,
    this.bid,
    this.ask,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(epoch * 1000);

  factory Tick.fromJson(Map<String, dynamic> json) {
    final tick = json['tick'] as Map<String, dynamic>?;
    if (tick == null) throw const FormatException('Invalid tick data');
    return Tick(
      symbol: tick['symbol'] as String,
      quote: (tick['quote'] as num).toDouble(),
      epoch: tick['epoch'] as int,
      bid: tick['bid'] != null ? (tick['bid'] as num).toDouble() : null,
      ask: tick['ask'] != null ? (tick['ask'] as num).toDouble() : null,
    );
  }

  @override
  List<Object?> get props => [symbol, quote, epoch, bid, ask];
}
