import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/candle.dart';
import '../../domain/chart_state.dart';
import '../../domain/indicator_calculator.dart';

class CandlestickPainter extends CustomPainter {
  final List<Candle> candles;
  final List<IndicatorConfig> indicators;
  final int visibleCount;
  final int scrollOffset;
  final double? crosshairPrice;
  final int? crosshairIndex;

  CandlestickPainter({
    required this.candles,
    this.indicators = const [],
    this.visibleCount = 50,
    this.scrollOffset = 0,
    this.crosshairPrice,
    this.crosshairIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final paintingWidth = size.width - 60;
    final paintingHeight = size.height - 40;
    final topPadding = 10.0;

    final visible = _visibleCandles;
    if (visible.isEmpty) return;

    final high = visible.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final low = visible.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final range = high - low;
    if (range == 0) return;

    final padding = range * 0.05;
    final adjustedHigh = high + padding;
    final adjustedLow = low - padding;
    final adjustedRange = adjustedHigh - adjustedLow;

    final candleWidth = paintingWidth / visible.length;
    final bodyWidth = (candleWidth * 0.6).clamp(1.0, candleWidth - 2);

    // Background grid
    _drawGrid(canvas, size, paintingWidth, paintingHeight, adjustedLow, adjustedRange);

    // Draw candles
    for (var i = 0; i < visible.length; i++) {
      final candle = visible[i];
      final x = 30.0 + i * candleWidth;
      final centerX = x + candleWidth / 2;

      final openY = _priceToY(candle.open, adjustedHigh, adjustedRange, paintingHeight, topPadding);
      final closeY = _priceToY(candle.close, adjustedHigh, adjustedRange, paintingHeight, topPadding);
      final highY = _priceToY(candle.high, adjustedHigh, adjustedRange, paintingHeight, topPadding);
      final lowY = _priceToY(candle.low, adjustedHigh, adjustedRange, paintingHeight, topPadding);

      final paint = Paint()
        ..color = candle.isBullish ? const Color(0xFF00C853) : const Color(0xFFFF1744)
        ..strokeWidth = 1.0;

      // Wick
      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), paint);

      // Body
      final bodyTop = min(openY, closeY);
      final bodyBottom = max(openY, closeY);
      final bodyHeight = max(bodyBottom - bodyTop, 1.0);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(centerX, bodyTop + bodyHeight / 2), width: bodyWidth, height: bodyHeight),
        Paint()..color = candle.isBullish ? const Color(0xFF00C853) : const Color(0xFFFF1744),
      );
    }

    // Draw indicators
    for (final config in indicators) {
      if (!config.visible) continue;
      _drawIndicator(canvas, size, visible, config, paintingWidth, paintingHeight, adjustedHigh, adjustedRange, topPadding);
    }

    // Draw crosshair
    if (crosshairPrice != null || crosshairIndex != null) {
      _drawCrosshair(canvas, size, paintingWidth, paintingHeight, adjustedHigh, adjustedRange,
          topPadding, candleWidth, visible);
    }

    // Price labels on right axis
    _drawPriceAxis(canvas, size, paintingHeight, adjustedLow, adjustedRange, topPadding);

    // Time labels on bottom
    _drawTimeAxis(canvas, size, paintingWidth, paintingHeight, visible, candleWidth);
  }

  List<Candle> get _visibleCandles {
    final start = candles.length - visibleCount - scrollOffset;
    final end = candles.length - scrollOffset;
    if (start < 0) return candles.sublist(0, end.clamp(0, candles.length));
    if (start >= candles.length) return [];
    return candles.sublist(start, end.clamp(start, candles.length));
  }

  double _priceToY(double price, double high, double range, double height, double topPadding) {
    return topPadding + ((high - price) / range) * height;
  }

  void _drawGrid(Canvas canvas, Size size, double width, double height, double low, double range) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    const gridLines = 8;
    for (var i = 0; i <= gridLines; i++) {
      final y = (height / gridLines) * i + 10;
      canvas.drawLine(Offset(30, y), Offset(30 + width, y), gridPaint);
    }
    for (var i = 0; i <= 6; i++) {
      final x = 30 + (width / 6) * i;
      canvas.drawLine(Offset(x, 10), Offset(x, 10 + height), gridPaint);
    }
  }

  void _drawIndicator(Canvas canvas, Size size, List<Candle> visible, IndicatorConfig config,
      double width, double height, double high, double range, double topPadding) {
    final linePaint = Paint()
      ..color = _indicatorColor(config.type)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final candleWidth = width / visible.length;
    List<double?> values;

    switch (config.type) {
      case IndicatorType.sma:
        values = IndicatorCalculator.sma(visible, config.period);
        break;
      case IndicatorType.ema:
        values = IndicatorCalculator.ema(visible, config.period);
        break;
      case IndicatorType.rsi:
        _drawRsiSubchart(canvas, size, visible, config);
        return;
      case IndicatorType.macd:
        _drawMacdSubchart(canvas, size, visible, config);
        return;
      case IndicatorType.bollinger:
        _drawBollinger(canvas, size, visible, config, width, height, high, range, topPadding);
        return;
      case IndicatorType.atr:
        values = IndicatorCalculator.atr(visible, config.period);
        break;
      default:
        return;
    }

    final path = Path();
    bool started = false;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == null) continue;
      final x = 30.0 + i * candleWidth + candleWidth / 2;
      final y = _priceToY(values[i]!, high, range, height, topPadding);
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    if (started) canvas.drawPath(path, linePaint);
  }

  void _drawBollinger(Canvas canvas, Size size, List<Candle> visible, IndicatorConfig config,
      double width, double height, double high, double range, double topPadding) {
    final result = IndicatorCalculator.bollinger(visible, config.period, config.stdDev ?? 2.0);
    final candleWidth = width / visible.length;

    final upperPath = Path();
    final lowerPath = Path();
    bool upperStarted = false, lowerStarted = false;

    for (var i = 0; i < result.upper.length; i++) {
      if (result.upper[i] == null || result.lower[i] == null) continue;
      final x = 30.0 + i * candleWidth + candleWidth / 2;
      final uy = _priceToY(result.upper[i]!, high, range, height, topPadding);
      final ly = _priceToY(result.lower[i]!, high, range, height, topPadding);

      if (!upperStarted) { upperPath.moveTo(x, uy); upperStarted = true; }
      else { upperPath.lineTo(x, uy); }
      if (!lowerStarted) { lowerPath.moveTo(x, ly); lowerStarted = true; }
      else { lowerPath.lineTo(x, ly); }
    }

    canvas.drawPath(upperPath, Paint()..color = Colors.cyan.withValues(alpha: 0.6)..strokeWidth=1);
    canvas.drawPath(lowerPath, Paint()..color=Colors.cyan.withValues(alpha:0.6)..strokeWidth=1);

    if (result.middle[result.middle.length-1] != null) {
      final midPath = Path();
      bool midStarted = false;
      for (var i = 0; i < result.middle.length; i++) {
        if (result.middle[i] == null) continue;
        final x = 30.0 + i * candleWidth + candleWidth / 2;
        final my = _priceToY(result.middle[i]!, high, range, height, topPadding);
        if (!midStarted) { midPath.moveTo(x, my); midStarted = true; }
        else { midPath.lineTo(x, my); }
      }
      canvas.drawPath(midPath, Paint()..color=Colors.cyan..strokeWidth=1);
    }

    // Fill between bands
    final fillPath = Path();
    bool fillStarted = false;
    for (var i = 0; i < result.upper.length; i++) {
      if (result.upper[i] == null || result.lower[i] == null) continue;
      final x = 30.0 + i * candleWidth + candleWidth / 2;
      if (!fillStarted) {
        fillPath.moveTo(x, _priceToY(result.upper[i]!, high, range, height, topPadding));
        fillStarted = true;
      } else {
        fillPath.lineTo(x, _priceToY(result.upper[i]!, high, range, height, topPadding));
      }
    }
    for (var i = result.lower.length - 1; i >= 0; i--) {
      if (result.lower[i] == null) continue;
      final x = 30.0 + i * candleWidth + candleWidth / 2;
      fillPath.lineTo(x, _priceToY(result.lower[i]!, high, range, height, topPadding));
    }
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color=Colors.cyan.withValues(alpha:0.08));
  }

  void _drawRsiSubchart(Canvas canvas, Size size, List<Candle> visible, IndicatorConfig config) {
    final subHeight = size.height * 0.2;
    final mainHeight = size.height - subHeight - 40;
    final width = size.width - 60;
    final candleWidth = width / visible.length;
    final subTop = mainHeight + 50;

    final values = IndicatorCalculator.rsi(visible, config.period);
    final rsiPaint = Paint()..color = Colors.orange..strokeWidth = 1.5..style = PaintingStyle.stroke;

    // Overbought/oversold lines
    canvas.drawLine(Offset(30, subTop + subHeight * 0.3),
        Offset(30 + width, subTop + subHeight * 0.3),
        Paint()..color = Colors.red.withValues(alpha: 0.3)..strokeWidth = 0.5);
    canvas.drawLine(Offset(30, subTop + subHeight * 0.7),
        Offset(30 + width, subTop + subHeight * 0.7),
        Paint()..color = Colors.green.withValues(alpha: 0.3)..strokeWidth = 0.5);

    final path = Path();
    bool started = false;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == null) continue;
      final x = 30.0 + i * candleWidth + candleWidth / 2;
      final y = subTop + (1 - values[i]! / 100) * subHeight;
      if (!started) { path.moveTo(x, y); started = true; }
      else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, rsiPaint);

    _drawLabel(canvas, 'RSI(${config.period})', Colors.orange, Offset(32, subTop - 2));
    _drawLabel(canvas, '70', Colors.red.withValues(alpha: 0.5), Offset(32, subTop + subHeight * 0.28));
    _drawLabel(canvas, '30', Colors.green.withValues(alpha: 0.5), Offset(32, subTop + subHeight * 0.68));
  }

  void _drawMacdSubchart(Canvas canvas, Size size, List<Candle> visible, IndicatorConfig config) {
    final subHeight = size.height * 0.2;
    final mainHeight = size.height - subHeight - 40;
    final width = size.width - 60;
    final candleWidth = width / visible.length;
    final subTop = mainHeight + 50;

    final result = IndicatorCalculator.macd(visible,
        config.fastPeriod ?? 12, config.slowPeriod ?? 26, config.signalPeriod ?? 9);

    final allValues = <double>[];
    for (var i = 0; i < result.macd.length; i++) {
      if (result.macd[i] != null) allValues.add(result.macd[i]!);
      if (result.signal[i] != null) allValues.add(result.signal[i]!);
      if (result.histogram[i] != null) allValues.add(result.histogram[i]!);
    }
    if (allValues.isEmpty) return;
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    final minVal = allValues.reduce((a, b) => a < b ? a : b);
    final valRange = maxVal - minVal;
    if (valRange == 0) return;

    // Histogram
    for (var i = 0; i < result.histogram.length; i++) {
      if (result.histogram[i] == null) continue;
      final x = 30.0 + i * candleWidth;
      final zeroY = subTop + subHeight * (maxVal / valRange);
      final histY = subTop + subHeight * ((maxVal - result.histogram[i]!) / valRange);
      final isPositive = result.histogram[i]! >= 0;
      canvas.drawRect(
        Rect.fromLTRB(x + 1, isPositive ? histY : zeroY, x + candleWidth - 1, isPositive ? zeroY : histY),
        Paint()..color = isPositive ? const Color(0xFF00C853) : const Color(0xFFFF1744),
      );
    }

    // MACD line
    final macdPath = Path();
    bool macdStarted = false;
    for (var i = 0; i < result.macd.length; i++) {
      if (result.macd[i] == null) continue;
      final x = 30.0 + i * candleWidth + candleWidth / 2;
      final y = subTop + subHeight * ((maxVal - result.macd[i]!) / valRange);
      if (!macdStarted) { macdPath.moveTo(x, y); macdStarted = true; }
      else { macdPath.lineTo(x, y); }
    }
    canvas.drawPath(macdPath, Paint()..color = Colors.blue..strokeWidth = 1.5);

    // Signal line
    final signalPath = Path();
    bool signalStarted = false;
    for (var i = 0; i < result.signal.length; i++) {
      if (result.signal[i] == null) continue;
      final x = 30.0 + i * candleWidth + candleWidth / 2;
      final y = subTop + subHeight * ((maxVal - result.signal[i]!) / valRange);
      if (!signalStarted) { signalPath.moveTo(x, y); signalStarted = true; }
      else { signalPath.lineTo(x, y); }
    }
    canvas.drawPath(signalPath, Paint()..color = Colors.orange..strokeWidth = 1.5);

    _drawLabel(canvas, 'MACD(${config.fastPeriod},${config.slowPeriod},${config.signalPeriod})',
        Colors.blue, Offset(32, subTop - 2));
  }

  void _drawCrosshair(Canvas canvas, Size size, double width, double height,
      double high, double range, double topPadding, double candleWidth, List<Candle> visible) {
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    if (crosshairPrice != null) {
      final y = _priceToY(crosshairPrice!, high, range, height, topPadding);
      canvas.drawLine(Offset(30, y), Offset(30 + width, y), dashPaint);
    }

    if (crosshairIndex != null && crosshairIndex! >= 0 && crosshairIndex! < visible.length) {
      final x = 30.0 + crosshairIndex! * candleWidth + candleWidth / 2;
      canvas.drawLine(Offset(x, topPadding), Offset(x, topPadding + height), dashPaint);
    }
  }

  void _drawPriceAxis(Canvas canvas, Size size, double height, double low, double range, double topPadding) {
    const labelCount = 6;
    for (var i = 0; i <= labelCount; i++) {
      final price = low + (range / labelCount) * (labelCount - i);
      final y = topPadding + (height / labelCount) * i;
      _drawLabel(canvas, price.toStringAsFixed(5), Colors.grey[600]!, Offset(2, y - 6));
    }
  }

  void _drawTimeAxis(Canvas canvas, Size size, double width, double height, List<Candle> visible, double candleWidth) {
    final labelInterval = (visible.length / 6).ceil();
    for (var i = 0; i < visible.length; i += labelInterval) {
      final dt = visible[i].dateTime;
      final label = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      final x = 30.0 + i * candleWidth + candleWidth / 2;
      _drawLabel(canvas, label, Colors.grey[600]!, Offset(x - 12, height + 14));
    }
  }

  void _drawLabel(Canvas canvas, String text, Color color, Offset offset) {
    final textStyle = TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w400);
    final textSpan = TextSpan(text: text, style: textStyle);
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, offset);
  }

  Color _indicatorColor(IndicatorType type) {
    switch (type) {
      case IndicatorType.sma: return Colors.yellow;
      case IndicatorType.ema: return Colors.blue;
      case IndicatorType.bollinger: return Colors.cyan;
      case IndicatorType.atr: return Colors.purple;
      default: return Colors.white;
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) => true;
}
