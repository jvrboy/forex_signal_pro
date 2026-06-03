import 'package:equatable/equatable.dart';

class Candle extends Equatable {
  final double open;
  final double high;
  final double low;
  final double close;
  final int epoch;
  final double? volume;

  const Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.epoch,
    this.volume,
  });

  bool get isBullish => close >= open;
  bool get isBearish => close < open;
  double get range => high - low;
  double get body => (close - open).abs();

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(epoch * 1000);

  factory Candle.fromJson(Map<String, dynamic> json) {
    return Candle(
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      epoch: json['epoch'] as int,
      volume: json['volume'] != null ? (json['volume'] as num).toDouble() : null,
    );
  }

  factory Candle.fromTickSeries(List<double> prices, int startEpoch, int intervalSecs) {
    return Candle(
      open: prices.first,
      high: prices.reduce((a, b) => a > b ? a : b),
      low: prices.reduce((a, b) => a < b ? a : b),
      close: prices.last,
      epoch: startEpoch,
    );
  }

  @override
  List<Object?> get props => [open, high, low, close, epoch, volume];
}

enum Timeframe {
  m1, m5, m15, m30, h1, h2, h4, h8, d1, w1, mn1;

  String get label {
    switch (this) {
      case Timeframe.m1: return '1m';
      case Timeframe.m5: return '5m';
      case Timeframe.m15: return '15m';
      case Timeframe.m30: return '30m';
      case Timeframe.h1: return '1H';
      case Timeframe.h2: return '2H';
      case Timeframe.h4: return '4H';
      case Timeframe.h8: return '8H';
      case Timeframe.d1: return '1D';
      case Timeframe.w1: return '1W';
      case Timeframe.mn1: return '1MN';
    }
  }

  int get seconds {
    switch (this) {
      case Timeframe.m1: return 60;
      case Timeframe.m5: return 300;
      case Timeframe.m15: return 900;
      case Timeframe.m30: return 1800;
      case Timeframe.h1: return 3600;
      case Timeframe.h2: return 7200;
      case Timeframe.h4: return 14400;
      case Timeframe.h8: return 28800;
      case Timeframe.d1: return 86400;
      case Timeframe.w1: return 604800;
      case Timeframe.mn1: return 2592000;
    }
  }

  int get ticksPerCandle {
    switch (this) {
      case Timeframe.m1: return 60;
      case Timeframe.m5: return 300;
      case Timeframe.m15: return 900;
      case Timeframe.m30: return 1800;
      case Timeframe.h1: return 3600;
      case Timeframe.h2: return 7200;
      case Timeframe.h4: return 14400;
      case Timeframe.h8: return 28800;
      case Timeframe.d1: return 86400;
      case Timeframe.w1: return 604800;
      case Timeframe.mn1: return 2592000;
    }
  }
}
