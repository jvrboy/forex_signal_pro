import 'deriv_types.dart';

class DeriveRequest {
  final MsgType type;
  final Map<String, dynamic> params;
  final int? reqId;

  const DeriveRequest({
    required this.type,
    this.params = const {},
    this.reqId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      type.key: 1,
      ...params,
    };
    if (reqId != null) {
      json['req_id'] = reqId;
    }
    return json;
  }

  static DeriveRequest authorize(String token, {int? reqId}) {
    return DeriveRequest(
      type: MsgType.authorize,
      params: {'authorize': token},
      reqId: reqId,
    );
  }

  static DeriveRequest activeSymbols({String? landingCompany, int? reqId}) {
    final params = <String, dynamic>{
      'active_symbols': 'brief',
    };
    if (landingCompany != null) {
      params['landing_company'] = landingCompany;
    }
    return DeriveRequest(type: MsgType.activeSymbols, params: params, reqId: reqId);
  }

  static DeriveRequest subscribeTicks(String symbol, {int? reqId}) {
    return DeriveRequest(
      type: MsgType.ticks,
      params: {'ticks': symbol, 'subscribe': 1},
      reqId: reqId,
    );
  }

  static DeriveRequest tickHistory(String symbol, {
    int? end,
    int? start,
    int? count,
    String? style,
    int? adjustStartTime,
    int? reqId,
  }) {
    final params = <String, dynamic>{
      'ticks_history': symbol,
      'end': end ?? 'latest',
      'style': style ?? 'ticks',
    };
    if (count != null) params['count'] = count;
    if (start != null) params['start'] = start;
    if (adjustStartTime != null) params['adjust_start_time'] = adjustStartTime;
    return DeriveRequest(type: MsgType.tickHistory, params: params, reqId: reqId);
  }

  static DeriveRequest buy(String contractId, double amount, {int? reqId}) {
    return DeriveRequest(
      type: MsgType.buy,
      params: {'buy': contractId, 'price': amount},
      reqId: reqId,
    );
  }

  static DeriveRequest sell(String contractId, {int? reqId}) {
    return DeriveRequest(
      type: MsgType.sell,
      params: {'sell': contractId},
      reqId: reqId,
    );
  }

  static DeriveRequest sellExpired({int? reqId}) {
    return DeriveRequest(
      type: MsgType.sellExpired,
      params: {'sell_expired': 1},
      reqId: reqId,
    );
  }

  static DeriveRequest portfolio({int? reqId}) {
    return DeriveRequest(
      type: MsgType.portfolio,
      params: {'portfolio': 1},
      reqId: reqId,
    );
  }

  static DeriveRequest balance({int? reqId}) {
    return DeriveRequest(
      type: MsgType.balance,
      params: {'balance': 1, 'subscribe': 1},
      reqId: reqId,
    );
  }

  static DeriveRequest proposal(String symbol, String contractType, double amount, String currency, {
    int? duration,
    String? durationUnit,
    int? barrier,
    String? barrier2,
    String? dateStart,
    int? reqId,
  }) {
    final params = <String, dynamic>{
      'proposal': 1,
      'amount': amount,
      'basis': 'stake',
      'contract_type': contractType,
      'currency': currency,
      'symbol': symbol,
    };
    if (duration != null) {
      params['duration'] = duration;
      params['duration_unit'] = durationUnit ?? 'm';
    }
    if (barrier != null) params['barrier'] = barrier;
    if (barrier2 != null) params['barrier2'] = barrier2;
    if (dateStart != null) params['date_start'] = dateStart;
    return DeriveRequest(type: MsgType.proposal, params: params, reqId: reqId);
  }

  static DeriveRequest ping({int? reqId}) {
    return DeriveRequest(type: MsgType.ping, reqId: reqId);
  }

  static DeriveRequest forget(String subscriptionId, {int? reqId}) {
    return DeriveRequest(
      type: MsgType.forget,
      params: {'forget': subscriptionId},
      reqId: reqId,
    );
  }

  static DeriveRequest forgetAll({String? type, int? reqId}) {
    final params = <String, dynamic>{};
    if (type != null) {
      params['forget_all'] = type;
    } else {
      params['forget_all'] = 'ticks';
    }
    return DeriveRequest(type: MsgType.forgetAll, params: params, reqId: reqId);
  }

  static DeriveRequest profitTable({
    int? limit,
    int? offset,
    String? sort,
    int? startTime,
    int? endTime,
    int? reqId,
  }) {
    final params = <String, dynamic>{
      'profit_table': 1,
    };
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;
    if (sort != null) params['sort'] = sort;
    if (startTime != null) params['start_time'] = startTime;
    if (endTime != null) params['end_time'] = endTime;
    return DeriveRequest(type: MsgType.profitTable, params: params, reqId: reqId);
  }

  static DeriveRequest statement({
    int? limit,
    int? offset,
    int? reqId,
  }) {
    final params = <String, dynamic>{
      'statement': 1,
    };
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;
    return DeriveRequest(type: MsgType.statement, params: params, reqId: reqId);
  }

  static DeriveRequest tradingTimes(String date, {int? reqId}) {
    return DeriveRequest(
      type: MsgType.tradingTimes,
      params: {'trading_times': date},
      reqId: reqId,
    );
  }
}
