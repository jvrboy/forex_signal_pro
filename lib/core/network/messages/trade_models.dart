import 'contract_types.dart';

class OpenContract {
  final String contractId;
  final String symbol;
  final ContractType contractType;
  final double buyPrice;
  final double? sellPrice;
  final double? profitLoss;
  final ContractStatus status;
  final DateTime dateStart;
  final DateTime? dateExpiry;
  final double? entryTick;
  final double? exitTick;
  final double? barrier;
  final double? barrier2;
  final String currency;
  final bool isSold;

  const OpenContract({
    required this.contractId,
    required this.symbol,
    required this.contractType,
    required this.buyPrice,
    this.sellPrice,
    this.profitLoss,
    required this.status,
    required this.dateStart,
    this.dateExpiry,
    this.entryTick,
    this.exitTick,
    this.barrier,
    this.barrier2,
    required this.currency,
    this.isSold = false,
  });

  factory OpenContract.fromJson(Map<String, dynamic> json) {
    return OpenContract(
      contractId: json['contract_id'] as String,
      symbol: json['symbol'] as String,
      contractType: _parseContractType(json['contract_type'] as String?),
      buyPrice: (json['buy_price'] as num).toDouble(),
      sellPrice: json['sell_price'] != null ? (json['sell_price'] as num).toDouble() : null,
      profitLoss: json['profit_loss'] != null ? (json['profit_loss'] as num).toDouble() : null,
      status: _parseContractStatus(json['status'] as String?),
      dateStart: DateTime.fromMillisecondsSinceEpoch((json['date_start'] as int) * 1000),
      dateExpiry: json['date_expiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['date_expiry'] as int) * 1000)
          : null,
      entryTick: json['entry_tick'] != null ? (json['entry_tick'] as num).toDouble() : null,
      exitTick: json['exit_tick'] != null ? (json['exit_tick'] as num).toDouble() : null,
      barrier: json['barrier'] != null ? (json['barrier'] as num).toDouble() : null,
      barrier2: json['barrier2'] != null ? (json['barrier2'] as num).toDouble() : null,
      currency: json['currency'] as String? ?? 'USD',
      isSold: json['is_sold'] == 1,
    );
  }

  static ContractType _parseContractType(String? type) {
    if (type == null) return ContractType.riseFall;
    switch (type.toUpperCase()) {
      case 'RISE_FALL':
      case 'RISE':
      case 'FALL':
        return ContractType.riseFall;
      case 'HIGHER_LOWER':
      case 'HIGHER':
      case 'LOWER':
        return ContractType.higherLower;
      case 'TOUCH':
      case 'NO_TOUCH':
        return ContractType.touchNoTouch;
      case 'ENDS_IN':
      case 'ENDS_OUT':
        return ContractType.endsInOut;
      case 'STAYS_IN':
      case 'STAYS_OUT':
        return ContractType.staysInOut;
      case 'ASIAN_UP':
      case 'ASIAN_DOWN':
        return ContractType.asianUpDown;
      case 'CALL':
      case 'PUT':
        return ContractType.callPut;
      case 'DIGITS_MATCH':
      case 'DIGITS_DIFF':
        return ContractType.digitsMatchDiff;
      case 'EXPIRYRANGE':
      case 'EXPIRYMISS':
        return ContractType.digits;
      case 'RESET_CALL':
      case 'RESET_PUT':
        return ContractType.resetCallPut;
      case 'RUN_HIGH':
      case 'RUN_LOW':
        return ContractType.runHighLow;
      case 'CALLSPREAD':
      case 'PUTSPREAD':
        return ContractType.callPutSpread;
      case 'TICK100':
        return ContractType.ticks100;
      case 'FORWARDSTART':
        return ContractType.forwardStart;
      default:
        return ContractType.riseFall;
    }
  }

  static ContractStatus _parseContractStatus(String? status) {
    if (status == null) return ContractStatus.open;
    switch (status.toLowerCase()) {
      case 'open':
        return ContractStatus.open;
      case 'closed':
        return ContractStatus.closed;
      case 'won':
        return ContractStatus.won;
      case 'lost':
        return ContractStatus.lost;
      case 'sold':
        return ContractStatus.sold;
      case 'expired':
        return ContractStatus.expired;
      default:
        return ContractStatus.open;
    }
  }
}

class TradePosition {
  final String transactionId;
  final String symbol;
  final String action;
  final double amount;
  final double balance;
  final DateTime date;
  final double? profitLoss;
  final String contractId;

  const TradePosition({
    required this.transactionId,
    required this.symbol,
    required this.action,
    required this.amount,
    required this.balance,
    required this.date,
    this.profitLoss,
    required this.contractId,
  });

  factory TradePosition.fromJson(Map<String, dynamic> json) {
    return TradePosition(
      transactionId: json['transaction_id']?.toString() ?? '',
      symbol: json['symbol'] as String? ?? '',
      action: json['action'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch((json['date'] as int) * 1000),
      profitLoss: json['profit_loss'] != null ? (json['profit_loss'] as num).toDouble() : null,
      contractId: json['contract_id']?.toString() ?? '',
    );
  }
}

class AccountBalance {
  final double balance;
  final double? depositedFunds;
  final double? profitLoss;
  final String currency;
  final bool isVirtual;

  const AccountBalance({
    required this.balance,
    this.depositedFunds,
    this.profitLoss,
    required this.currency,
    this.isVirtual = false,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      balance: (json['balance'] as num).toDouble(),
      depositedFunds: json['deposited_funds'] != null ? (json['deposited_funds'] as num).toDouble() : null,
      profitLoss: json['profit_loss'] != null ? (json['profit_loss'] as num).toDouble() : null,
      currency: json['currency'] as String? ?? 'USD',
      isVirtual: json['is_virtual'] == 1,
    );
  }
}

class ProfitTableEntry {
  final String transactionId;
  final String symbol;
  final double buyPrice;
  final double? sellPrice;
  final double profitLoss;
  final String contractType;
  final DateTime dateStart;
  final DateTime? dateExpiry;
  final String currency;
  final String appId;

  const ProfitTableEntry({
    required this.transactionId,
    required this.symbol,
    required this.buyPrice,
    this.sellPrice,
    required this.profitLoss,
    required this.contractType,
    required this.dateStart,
    this.dateExpiry,
    required this.currency,
    required this.appId,
  });

  factory ProfitTableEntry.fromJson(Map<String, dynamic> json) {
    return ProfitTableEntry(
      transactionId: json['transaction_id']?.toString() ?? '',
      symbol: json['symbol'] as String? ?? '',
      buyPrice: (json['buy_price'] as num).toDouble(),
      sellPrice: json['sell_price'] != null ? (json['sell_price'] as num).toDouble() : null,
      profitLoss: (json['profit_loss'] as num).toDouble(),
      contractType: json['contract_type'] as String? ?? '',
      dateStart: DateTime.fromMillisecondsSinceEpoch((json['date_start'] as int) * 1000),
      dateExpiry: json['date_expiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['date_expiry'] as int) * 1000)
          : null,
      currency: json['currency'] as String? ?? 'USD',
      appId: json['app_id']?.toString() ?? '',
    );
  }
}
