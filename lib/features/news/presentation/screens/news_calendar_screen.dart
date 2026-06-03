import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/forex_factory_scraper.dart';
import '../../domain/news_event.dart';

final newsProvider = FutureProvider<List<NewsEvent>>((ref) async {
  final scraper = ForexFactoryScraper();
  ref.onDispose(() => scraper.dispose());
  return scraper.fetchXmlFeed();
});

final _currencyFilterProvider = StateProvider<List<String>>((ref) => []);
final _impactFilterProvider = StateProvider<Set<NewsImpact>>((ref) => {NewsImpact.low, NewsImpact.medium, NewsImpact.high});

class NewsCalendarScreen extends ConsumerStatefulWidget {
  const NewsCalendarScreen({super.key});

  @override
  ConsumerState<NewsCalendarScreen> createState() => _NewsCalendarScreenState();
}

class _NewsCalendarScreenState extends ConsumerState<NewsCalendarScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final newsAsync = ref.watch(newsProvider);
    final currencyFilter = ref.watch(_currencyFilterProvider);
    final impactFilter = ref.watch(_impactFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forex News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(newsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(currencies: _extractCurrencies(newsAsync)),
          Expanded(
            child: newsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Could not load news', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(err.toString(), style: theme.textTheme.bodySmall),
                    TextButton(
                      onPressed: () => ref.invalidate(newsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (events) {
                var filtered = events.where((e) => impactFilter.contains(e.impact)).toList();
                if (currencyFilter.isNotEmpty) {
                  filtered = filtered.where((e) => currencyFilter.contains(e.currency)).toList();
                }
                filtered.sort((a, b) => a.date.compareTo(b.date));

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text('No matching events', style: theme.textTheme.bodyLarge),
                        TextButton(
                          onPressed: () {
                            ref.read(_currencyFilterProvider.notifier).state = [];
                            ref.read(_impactFilterProvider.notifier).state = {NewsImpact.low, NewsImpact.medium, NewsImpact.high};
                          },
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final event = filtered[index];
                    return _NewsEventCard(
                      event: event,
                      countdown: _countdownText(event),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractCurrencies(AsyncValue<List<NewsEvent>> newsAsync) {
    return newsAsync.maybeWhen(
      data: (events) => events.map((e) => e.currency).toSet().toList()..sort(),
      orElse: () => ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'NZD'],
    );
  }

  String? _countdownText(NewsEvent event) {
    if (event.isPast || event.isReleased) return null;
    final diff = event.date.difference(DateTime.now());
    if (diff.isNegative) return null;
    if (diff.inDays > 1) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
    return '${diff.inSeconds}s';
  }
}

class _FilterBar extends ConsumerWidget {
  final List<String> currencies;
  const _FilterBar({required this.currencies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFilter = ref.watch(_currencyFilterProvider);
    final impactFilter = ref.watch(_impactFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(bottom: BorderSide(color: theme.dividerTheme.color ?? Colors.grey[800]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Impact: ', style: TextStyle(fontSize: 12)),
              _FilterChip(label: 'High', selected: impactFilter.contains(NewsImpact.high),
                color: Colors.red, onTap: () => _toggleImpact(ref, NewsImpact.high)),
              const SizedBox(width: 4),
              _FilterChip(label: 'Med', selected: impactFilter.contains(NewsImpact.medium),
                color: Colors.orange, onTap: () => _toggleImpact(ref, NewsImpact.medium)),
              const SizedBox(width: 4),
              _FilterChip(label: 'Low', selected: impactFilter.contains(NewsImpact.low),
                color: Colors.grey, onTap: () => _toggleImpact(ref, NewsImpact.low)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(label: 'All', selected: currencyFilter.isEmpty,
                  onTap: () => ref.read(_currencyFilterProvider.notifier).state = []),
                ...currencies.map((c) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _FilterChip(label: c, selected: currencyFilter.contains(c),
                    onTap: () => _toggleCurrency(ref, c)),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleImpact(WidgetRef ref, NewsImpact impact) {
    final current = Set<NewsImpact>.from(ref.read(_impactFilterProvider));
    if (current.contains(impact)) {
      current.remove(impact);
    } else {
      current.add(impact);
    }
    ref.read(_impactFilterProvider.notifier).state = current;
  }

  void _toggleCurrency(WidgetRef ref, String currency) {
    final current = List<String>.from(ref.read(_currencyFilterProvider));
    if (current.contains(currency)) {
      current.remove(currency);
    } else {
      current.add(currency);
    }
    ref.read(_currencyFilterProvider.notifier).state = current;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? (color ?? Theme.of(context).colorScheme.primary) : Colors.grey.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? color ?? Theme.of(context).colorScheme.primary : null,
        )),
      ),
    );
  }
}

class _NewsEventCard extends StatelessWidget {
  final NewsEvent event;
  final String? countdown;
  const _NewsEventCard({required this.event, this.countdown});

  Color _impactColor(NewsImpact impact) {
    switch (impact) {
      case NewsImpact.high: return Colors.red;
      case NewsImpact.medium: return Colors.orange;
      case NewsImpact.low: return Colors.grey;
    }
  }

  String _impactLabel(NewsImpact impact) {
    switch (impact) {
      case NewsImpact.high: return 'HIGH';
      case NewsImpact.medium: return 'MED';
      case NewsImpact.low: return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final impactColor = _impactColor(event.impact);
    final isNearby = event.isHighImpactNearby;
    final isPast = event.isPast || event.isReleased;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isPast ? null : theme.cardTheme.color,
      child: Container(
        decoration: isNearby
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: impactColor.withValues(alpha: 0.5), width: 2),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: impactColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_impactLabel(event.impact),
                      style: TextStyle(color: impactColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(event.currency,
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  if (countdown != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 12, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(countdown!, style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                  if (isPast) ...[
                    const Spacer(),
                    Text(event.actual ?? 'Released', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(event.event, style: theme.textTheme.titleMedium),
                  ),
                  if (!isPast) Text(
                    '${event.date.month}/${event.date.day} ${event.timeSast}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (event.previous != null)
                    _DetailChip(label: 'Prev', value: event.previous!, theme: theme),
                  if (event.forecast != null)
                    _DetailChip(label: 'Forecast', value: event.forecast!, theme: theme),
                  if (event.actual != null)
                    _DetailChip(label: 'Actual', value: event.actual!, theme: theme, color: Colors.blue),
                ],
              ),
              if (isNearby) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text('High-impact event within 2 hours — signals adjusted',
                        style: TextStyle(color: Colors.red[700], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final Color? color;
  const _DetailChip({required this.label, required this.value, required this.theme, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
