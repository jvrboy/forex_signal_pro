import 'dart:math';
import 'candle.dart';

class IndicatorCalculator {
  static List<double?> sma(List<Candle> candles, int period) {
    if (candles.length < period) return List.filled(candles.length, null);
    final result = List<double?>.filled(candles.length, null);
    for (var i = period - 1; i < candles.length; i++) {
      double sum = 0;
      for (var j = i - period + 1; j <= i; j++) {
        sum += candles[j].close;
      }
      result[i] = sum / period;
    }
    return result;
  }

  static List<double?> ema(List<Candle> candles, int period) {
    if (candles.length < period) return List.filled(candles.length, null);
    final result = List<double?>.filled(candles.length, null);
    final multiplier = 2.0 / (period + 1);
    final smaValues = sma(candles, period);
    result[period - 1] = smaValues[period - 1];
    for (var i = period; i < candles.length; i++) {
      result[i] = (candles[i].close - result[i - 1]!) * multiplier + result[i - 1]!;
    }
    return result;
  }

  static List<double?> rsi(List<Candle> candles, int period) {
    if (candles.length < period + 1) return List.filled(candles.length, null);
    final result = List<double?>.filled(candles.length, null);
    final gains = <double>[];
    final losses = <double>[];
    for (var i = 1; i < candles.length; i++) {
      final diff = candles[i].close - candles[i - 1].close;
      gains.add(diff > 0 ? diff : 0);
      losses.add(diff < 0 ? -diff : 0);
    }
    for (var i = period; i < candles.length; i++) {
      final avgGain = gains.sublist(i - period, i).reduce((a, b) => a + b) / period;
      final avgLoss = losses.sublist(i - period, i).reduce((a, b) => a + b) / period;
      if (avgLoss == 0) {
        result[i] = 100;
      } else {
        final rs = avgGain / avgLoss;
        result[i] = 100 - (100 / (1 + rs));
      }
    }
    return result;
  }

  static ({List<double?> middle, List<double?> upper, List<double?> lower}) bollinger(
    List<Candle> candles, int period, double stdDev) {
    final middle = sma(candles, period);
    final upper = List<double?>.filled(candles.length, null);
    final lower = List<double?>.filled(candles.length, null);
    for (var i = period - 1; i < candles.length; i++) {
      if (middle[i] == null) continue;
      double sumSqDiff = 0;
      for (var j = i - period + 1; j <= i; j++) {
        sumSqDiff += pow(candles[j].close - middle[i]!, 2);
      }
      final std = sqrt(sumSqDiff / period);
      upper[i] = middle[i]! + stdDev * std;
      lower[i] = middle[i]! - stdDev * std;
    }
    return (middle: middle, upper: upper, lower: lower);
  }

  static ({List<double?> macd, List<double?> signal, List<double?> histogram}) macd(
    List<Candle> candles, int fastPeriod, int slowPeriod, int signalPeriod) {
    final fastEma = ema(candles, fastPeriod);
    final slowEma = ema(candles, slowPeriod);
    final macdLine = List<double?>.filled(candles.length, null);
    for (var i = 0; i < candles.length; i++) {
      if (fastEma[i] != null && slowEma[i] != null) {
        macdLine[i] = fastEma[i]! - slowEma[i]!;
      }
    }
    final signalLine = _emaValues(macdLine, signalPeriod);
    final histogram = List<double?>.filled(candles.length, null);
    for (var i = 0; i < candles.length; i++) {
      if (macdLine[i] != null && signalLine[i] != null) {
        histogram[i] = macdLine[i]! - signalLine[i]!;
      }
    }
    return (macd: macdLine, signal: signalLine, histogram: histogram);
  }

  static List<double?> _emaValues(List<double?> values, int period) {
    if (values.length < period) return List.filled(values.length, null);
    final result = List<double?>.filled(values.length, null);
    final multiplier = 2.0 / (period + 1);
    double? sum;
    int count = 0;
    for (var i = 0; i < values.length; i++) {
      if (values[i] != null) {
        if (sum == null) sum = 0;
        sum = sum! + values[i]!;
        count++;
        if (count == period) {
          result[i] = sum! / period;
        } else if (count > period && result[i - 1] != null) {
          result[i] = (values[i]! - result[i - 1]!) * multiplier + result[i - 1]!;
        }
      }
    }
    return result;
  }

  static List<double?> atr(List<Candle> candles, int period) {
    if (candles.length < 2) return List.filled(candles.length, null);
    final result = List<double?>.filled(candles.length, null);
    final trueRanges = <double>[];
    for (var i = 1; i < candles.length; i++) {
      final hl = candles[i].high - candles[i].low;
      final hpc = (candles[i].high - candles[i - 1].close).abs();
      final lpc = (candles[i].low - candles[i - 1].close).abs();
      trueRanges.add([hl, hpc, lpc].reduce((a, b) => a > b ? a : b));
    }
    for (var i = period - 1; i < trueRanges.length; i++) {
      final sum = trueRanges.sublist(i - period + 1, i + 1).reduce((a, b) => a + b);
      result[i + 1] = sum / period;
    }
    return result;
  }

  static List<double?> stochastic(List<Candle> candles, int period) {
    if (candles.length < period) return List.filled(candles.length, null);
    final result = List<double?>.filled(candles.length, null);
    for (var i = period - 1; i < candles.length; i++) {
      double highest = candles[i].high;
      double lowest = candles[i].low;
      for (var j = i - period + 1; j <= i; j++) {
        if (candles[j].high > highest) highest = candles[j].high;
        if (candles[j].low < lowest) lowest = candles[j].low;
      }
      final range = highest - lowest;
      if (range == 0) {
        result[i] = 50;
      } else {
        result[i] = ((candles[i].close - lowest) / range) * 100;
      }
    }
    return result;
  }
}
