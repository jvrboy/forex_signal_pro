import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum NewsImpact { low, medium, high }

class NewsEvent extends Equatable {
  final String id;
  final DateTime date;
  final String timeSast;
  final String currency;
  final NewsImpact impact;
  final String event;
  final String? previous;
  final String? forecast;
  final String? actual;
  final DateTime createdAt;

  const NewsEvent({
    required this.id,
    required this.date,
    required this.timeSast,
    required this.currency,
    required this.impact,
    required this.event,
    this.previous,
    this.forecast,
    this.actual,
    required this.createdAt,
  });

  factory NewsEvent.create({
    required DateTime date,
    required String timeSast,
    required String currency,
    required NewsImpact impact,
    required String event,
    String? previous,
    String? forecast,
    String? actual,
  }) {
    return NewsEvent(
      id: const Uuid().v4(),
      date: date,
      timeSast: timeSast,
      currency: currency,
      impact: impact,
      event: event,
      previous: previous,
      forecast: forecast,
      actual: actual,
      createdAt: DateTime.now(),
    );
  }

  factory NewsEvent.fromXml(Map<String, dynamic> xml) {
    final impactRaw = (xml['impact'] as String?)?.toLowerCase() ?? 'low';
    return NewsEvent.create(
      date: DateTime.parse(xml['date'] as String),
      timeSast: xml['time'] as String? ?? '00:00',
      currency: xml['currency'] as String? ?? 'USD',
      impact: impactRaw == 'high'
          ? NewsImpact.high
          : impactRaw == 'medium'
              ? NewsImpact.medium
              : NewsImpact.low,
      event: xml['event'] as String? ?? 'Unknown',
      previous: xml['previous'] as String?,
      forecast: xml['forecast'] as String?,
      actual: xml['actual'] as String?,
    );
  }

  bool get isPast => DateTime.now().isAfter(date);
  bool get isUpcoming => !isPast;
  bool get isReleased => actual != null;

  bool get isHighImpactNearby {
    if (!isUpcoming) return false;
    final hoursUntil = date.difference(DateTime.now()).inHours.abs();
    return impact == NewsImpact.high && hoursUntil <= 2;
  }

  @override
  List<Object?> get props => [
    id, date, timeSast, currency, impact, event,
    previous, forecast, actual, createdAt,
  ];
}
