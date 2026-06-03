import 'package:equatable/equatable.dart';

class SymbolInfo extends Equatable {
  final String symbol;
  final String displayName;
  final String market;
  final String marketDisplayName;
  final String submarket;
  final String submarketDisplayName;
  final int pipSize;
  final double? minStake;
  final double? maxStake;

  const SymbolInfo({
    required this.symbol,
    required this.displayName,
    required this.market,
    required this.marketDisplayName,
    required this.submarket,
    required this.submarketDisplayName,
    this.pipSize = 0,
    this.minStake,
    this.maxStake,
  });

  factory SymbolInfo.fromJson(Map<String, dynamic> json) {
    return SymbolInfo(
      symbol: json['symbol'] as String,
      displayName: json['display_name'] as String,
      market: json['market'] as String,
      marketDisplayName: json['market_display_name'] as String,
      submarket: json['submarket'] as String,
      submarketDisplayName: json['submarket_display_name'] as String,
      pipSize: json['pip'] as int? ?? 0,
      minStake: json['min_stake'] != null ? (json['min_stake'] as num).toDouble() : null,
      maxStake: json['max_stake'] != null ? (json['max_stake'] as num).toDouble() : null,
    );
  }

  @override
  List<Object?> get props => [
    symbol,
    displayName,
    market,
    marketDisplayName,
    submarket,
    submarketDisplayName,
    pipSize,
    minStake,
    maxStake,
  ];
}
