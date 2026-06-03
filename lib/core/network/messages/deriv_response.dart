import 'dart:convert';
import 'deriv_types.dart';

class DeriveResponse {
  final MsgType? msgType;
  final Map<String, dynamic> raw;
  final dynamic error;
  final int? reqId;
  final dynamic subscription;
  final String? subscriptionId;

  const DeriveResponse({
    this.msgType,
    required this.raw,
    this.error,
    this.reqId,
    this.subscription,
    this.subscriptionId,
  });

  factory DeriveResponse.fromJson(Map<String, dynamic> json) {
    dynamic error;
    if (json['error'] != null) {
      error = json['error'];
    }

    MsgType? msgType;
    for (final key in json.keys) {
      try {
        msgType = MsgType.fromKey(key);
        break;
      } catch (_) {
        // Key not found in MsgType enum
      }
    }

    int? reqId;
    if (json['req_id'] != null) {
      reqId = json['req_id'] as int;
    }

    dynamic subscription;
    String? subscriptionId;
    if (json['subscription'] is Map<String, dynamic>) {
      subscription = json['subscription'];
      subscriptionId = subscription?['id']?.toString();
    }

    if (msgType == null && json['msg_type'] != null) {
      try {
        msgType = MsgType.fromKey(json['msg_type'] as String);
      } catch (_) {
        // msg_type key not found in MsgType enum
      }
    }

    if (msgType == null && json['echo_req'] is Map<String, dynamic>) {
      final echoReq = json['echo_req'] as Map<String, dynamic>;
      for (final key in echoReq.keys) {
        try {
          msgType = MsgType.fromKey(key);
          break;
        } catch (_) {
        // echo_req key not found in MsgType enum
      }
      }
    }

    return DeriveResponse(
      msgType: msgType,
      raw: json,
      error: error,
      reqId: reqId,
      subscription: subscription,
      subscriptionId: subscriptionId,
    );
  }

  factory DeriveResponse.fromRawJson(String rawJson) {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return DeriveResponse.fromJson(decoded);
  }

  bool get isError => error != null;
  String get errorMessage => error?['message']?.toString() ?? 'Unknown error';
  int? get errorCode => error?['code'] as int?;

  T? getValue<T>(String key) {
    final parts = key.split('.');
    dynamic current = raw;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current as T?;
  }

  Map<String, dynamic>? get authorize => getValue<Map<String, dynamic>>('authorize');
  List<dynamic>? get activeSymbols => getValue<List<dynamic>>('active_symbols');
  Map<String, dynamic>? get tick => getValue<Map<String, dynamic>>('tick');
  Map<String, dynamic>? get buy => getValue<Map<String, dynamic>>('buy');
  Map<String, dynamic>? get sell => getValue<Map<String, dynamic>>('sell');
  Map<String, dynamic>? get balance => getValue<Map<String, dynamic>>('balance');
  List<dynamic>? get portfolio => getValue<List<dynamic>>('portfolio');
  Map<String, dynamic>? get proposal => getValue<Map<String, dynamic>>('proposal');
  List<dynamic>? get history => getValue<List<dynamic>>('history.prices');
  List<dynamic>? get candles => getValue<List<dynamic>>('candles');
  Map<String, dynamic>? get contractFor => getValue<Map<String, dynamic>>('contracts_for');
  Map<String, dynamic>? get tradingTimes => getValue<Map<String, dynamic>>('trading_times');
  Map<String, dynamic>? get websiteStatus => getValue<Map<String, dynamic>>('website_status');
  List<dynamic>? get profitTable => getValue<List<dynamic>>('profit_table.transactions');
  List<dynamic>? get statement => getValue<List<dynamic>>('statement.transactions');
  Map<String, dynamic>? get proposalOpenContract => getValue<Map<String, dynamic>>('proposal_open_contract');
  List<dynamic>? get accountList => getValue<List<dynamic>>('account_list');
}
