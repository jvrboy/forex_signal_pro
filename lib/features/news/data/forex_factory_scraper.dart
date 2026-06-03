import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:forex_signal_pro/core/constants/app_constants.dart';
import '../domain/news_event.dart';

class ForexFactoryScraper {
  final http.Client _client;

  ForexFactoryScraper({http.Client? client}) : _client = client ?? http.Client();

  Future<List<NewsEvent>> fetchXmlFeed() async {
    try {
      final response = await _client.get(
        Uri.parse(AppConstants.forexFactoryXmlUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/xml, text/xml, */*',
        },
      );

      if (response.statusCode != 200) return [];

      final document = XmlDocument.parse(response.body);
      final events = <NewsEvent>[];

      for (final event in document.findAllElements('event')) {
        try {
          events.add(NewsEvent.fromXml({
            'date': event.getElement('date')?.innerText ?? '',
            'time': event.getElement('time')?.innerText ?? '',
            'currency': event.getElement('currency')?.innerText ?? '',
            'impact': event.getElement('impact')?.innerText ?? 'low',
            'event': event.getElement('title')?.innerText ?? 'Unknown',
            'previous': event.getElement('previous')?.innerText,
            'forecast': event.getElement('forecast')?.innerText,
            'actual': event.getElement('actual')?.innerText,
          }));
        } catch (e) {
          print('ForexFactory: skipped invalid event: $e');
        }
      }

      return events;
    } catch (e) {
      print('ForexFactory: XML feed fetch/parse failed: $e');
      return [];
    }
  }

  Future<List<NewsEvent>> fetchHtmlCalendar() async {
    try {
      final response = await _client.get(
        Uri.parse(AppConstants.forexFactoryCalendarUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml',
        },
      );

      if (response.statusCode != 200) return [];
      return [];
    } catch (e) {
      print('ForexFactory: HTML calendar fetch failed: $e');
      return [];
    }
  }

  List<NewsEvent> convertToSast(List<NewsEvent> events) {
    return events.map((event) {
      final sastTime = _estToSast(event.timeSast);
      return NewsEvent.create(
        date: event.date,
        timeSast: sastTime,
        currency: event.currency,
        impact: event.impact,
        event: event.event,
        previous: event.previous,
        forecast: event.forecast,
        actual: event.actual,
      );
    }).toList();
  }

  String _estToSast(String estTime) {
    final parts = estTime.split(':');
    if (parts.length != 2) return estTime;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final sastHour = (hour + 7) % 24;
    return '${sastHour.toString().padLeft(2, '0')}:$minute';
  }

  void dispose() {
    _client.close();
  }
}
