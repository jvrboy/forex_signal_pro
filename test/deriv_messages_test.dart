import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/core/network/messages/deriv_types.dart';
import 'package:forex_signal_pro/core/network/messages/deriv_request.dart';
import 'package:forex_signal_pro/core/network/messages/deriv_response.dart';
import 'package:forex_signal_pro/core/network/messages/contract_types.dart';
import 'package:forex_signal_pro/core/network/messages/trade_models.dart';

void main() {
  group('MsgType', () {
    test('key returns correct string for each type', () {
      expect(MsgType.authorize.key, 'authorize');
      expect(MsgType.activeSymbols.key, 'active_symbols');
      expect(MsgType.ticks.key, 'ticks');
      expect(MsgType.buy.key, 'buy');
      expect(MsgType.sell.key, 'sell');
      expect(MsgType.ping.key, 'ping');
      expect(MsgType.forget.key, 'forget');
      expect(MsgType.forgetAll.key, 'forget_all');
      expect(MsgType.balance.key, 'balance');
      expect(MsgType.proposal.key, 'proposal');
      expect(MsgType.statement.key, 'statement');
    });

    test('fromKey roundtrip works for all types', () {
      for (final type in MsgType.values) {
        expect(MsgType.fromKey(type.key), type);
      }
    });

    test('fromKey throws ArgumentError for unknown key', () {
      expect(() => MsgType.fromKey('nonexistent'), throwsArgumentError);
      expect(() => MsgType.fromKey(''), throwsArgumentError);
    });

    test('all keys are unique', () {
      final keys = MsgType.values.map((t) => t.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('all keys are non-empty strings', () {
      for (final type in MsgType.values) {
        expect(type.key.isNotEmpty, isTrue);
      }
    });
  });

  group('DeriveRequest', () {
    test('authorize creates correct json', () {
      final req = DeriveRequest.authorize('test_token', reqId: 1);
      final json = req.toJson();
      expect(json['authorize'], 'test_token');
      expect(json['req_id'], 1);
    });

    test('subscribeTicks creates correct json', () {
      final req = DeriveRequest.subscribeTicks('EURUSD');
      final json = req.toJson();
      expect(json['ticks'], 'EURUSD');
      expect(json['subscribe'], 1);
    });

    test('buy creates correct json', () {
      final req = DeriveRequest.buy('contract_123', 10.0);
      final json = req.toJson();
      expect(json['buy'], 'contract_123');
      expect(json['price'], 10.0);
    });

    test('sell creates correct json', () {
      final req = DeriveRequest.sell('contract_123');
      final json = req.toJson();
      expect(json['sell'], 'contract_123');
    });

    test('sellExpired creates correct json', () {
      final req = DeriveRequest.sellExpired();
      final json = req.toJson();
      expect(json['sell_expired'], 1);
    });

    test('ping creates correct json without extra params', () {
      final req = DeriveRequest.ping();
      final json = req.toJson();
      expect(json['ping'], 1);
      expect(json.length, 1);
    });

    test('tickHistory creates correct json with defaults', () {
      final req = DeriveRequest.tickHistory('EURUSD', count: 100);
      final json = req.toJson();
      expect(json['ticks_history'], 'EURUSD');
      expect(json['count'], 100);
      expect(json['end'], 'latest');
      expect(json['style'], 'ticks');
    });

    test('tickHistory handles optional parameters', () {
      final req = DeriveRequest.tickHistory('EURUSD', count: 50, start: 1000000, end: 2000000);
      final json = req.toJson();
      expect(json['start'], 1000000);
      expect(json['end'], 2000000);
    });

    test('balance includes subscribe flag', () {
      final req = DeriveRequest.balance();
      final json = req.toJson();
      expect(json['balance'], 1);
      expect(json['subscribe'], 1);
    });

    test('portfolio creates correct json', () {
      final req = DeriveRequest.portfolio();
      final json = req.toJson();
      expect(json['portfolio'], 1);
    });

    test('forgetAll defaults to ticks', () {
      final req = DeriveRequest.forgetAll();
      final json = req.toJson();
      expect(json['forget_all'], 'ticks');
    });

    test('forgetAll accepts custom type', () {
      final req = DeriveRequest.forgetAll(type: 'ticks');
      final json = req.toJson();
      expect(json['forget_all'], 'ticks');
    });

    test('proposal creates correct json with all params', () {
      final req = DeriveRequest.proposal(
        'EURUSD', 'CALL', 10.0, 'USD',
        duration: 5, durationUnit: 'm',
      );
      final json = req.toJson();
      expect(json['proposal'], 1);
      expect(json['symbol'], 'EURUSD');
      expect(json['contract_type'], 'CALL');
      expect(json['amount'], 10.0);
      expect(json['duration'], 5);
      expect(json['duration_unit'], 'm');
    });

    test('profitTable creates correct json', () {
      final req = DeriveRequest.profitTable(limit: 50, offset: 0);
      final json = req.toJson();
      expect(json['profit_table'], 1);
      expect(json['limit'], 50);
      expect(json['offset'], 0);
    });

    test('statement creates correct json', () {
      final req = DeriveRequest.statement(limit: 25, offset: 0);
      final json = req.toJson();
      expect(json['statement'], 1);
      expect(json['limit'], 25);
    });

    test('req_id is omitted when null', () {
      final req = DeriveRequest.ping();
      final json = req.toJson();
      expect(json.containsKey('req_id'), isFalse);
    });
  });

  group('DeriveResponse', () {
    test('parses authorize response', () {
      final json = {
        'echo_req': {'authorize': '1'},
        'msg_type': 'authorize',
        'authorize': {'loginid': 'CR12345', 'currency': 'USD', 'balance': 1000.0},
      };
      final response = DeriveResponse.fromJson(json);
      expect(response.msgType, MsgType.authorize);
      expect(response.authorize!['loginid'], 'CR12345');
      expect(response.isError, isFalse);
    });

    test('parses tick response with subscription', () {
      final json = {
        'echo_req': {'ticks': 'EURUSD'},
        'msg_type': 'tick',
        'tick': {'symbol': 'EURUSD', 'quote': 1.1050, 'epoch': 1000000},
        'subscription': {'id': 'sub_123'},
      };
      final response = DeriveResponse.fromJson(json);
      expect(response.msgType, MsgType.ticks);
      expect(response.tick!['quote'], 1.1050);
      expect(response.subscriptionId, 'sub_123');
      expect(response.subscription, isNotNull);
    });

    test('detects error response', () {
      final json = {
        'echo_req': {'authorize': 'invalid'},
        'msg_type': 'authorize',
        'error': {'code': 'InvalidToken', 'message': 'Invalid token'},
      };
      final response = DeriveResponse.fromJson(json);
      expect(response.isError, isTrue);
      expect(response.errorMessage, 'Invalid token');
    });

    test('parses balance response', () {
      final json = {
        'echo_req': {'balance': '1'},
        'msg_type': 'balance',
        'balance': {'balance': 5000.0, 'currency': 'USD', 'is_virtual': 0},
      };
      final response = DeriveResponse.fromJson(json);
      expect(response.balance!['balance'], 5000.0);
      expect(response.balance!['currency'], 'USD');
    });

    test('parses ping pong response', () {
      const raw = '{"msg_type":"ping","ping":"pong","req_id":1}';
      final response = DeriveResponse.fromRawJson(raw);
      expect(response.msgType, MsgType.ping);
      expect(response.reqId, 1);
      expect(response.getValue<String>('ping'), 'pong');
    });

    test('handles active_symbols response', () {
      final json = {
        'echo_req': {'active_symbols': 'brief'},
        'msg_type': 'active_symbols',
        'active_symbols': [
          {'symbol': 'EURUSD', 'display_name': 'EUR/USD', 'market': 'forex', 'market_display_name': 'Forex',
           'submarket': 'major', 'submarket_display_name': 'Major Pairs', 'pip': 4},
        ],
      };
      final response = DeriveResponse.fromJson(json);
      expect(response.msgType, MsgType.activeSymbols);
      expect(response.activeSymbols!.length, 1);
    });

    test('parses error code correctly', () {
      final json = {
        'echo_req': {'buy': '1'},
        'msg_type': 'buy',
        'error': {'code': 'AuthorizationRequired', 'message': 'Not authorized'},
      };
      final response = DeriveResponse.fromJson(json);
      expect(response.isError, isTrue);
      expect(response.errorCode, isNotNull);
    });

    test('handles empty json gracefully', () {
      final response = DeriveResponse.fromJson({});
      expect(response.msgType, isNull);
      expect(response.isError, isFalse);
    });

    test('getValue traverses nested keys', () {
      final json = {
        'proposal_open_contract': {
          'contract_id': 'abc123',
          'entry_tick': 1.1050,
        },
      };
      final response = DeriveResponse.fromJson(json);
      expect(response.getValue<String>('proposal_open_contract.contract_id'), 'abc123');
      expect(response.getValue<double>('proposal_open_contract.entry_tick'), 1.1050);
      expect(response.getValue<String>('nonexistent.key'), isNull);
    });

    test('fromRawJson handles malformed JSON', () {
      expect(() => DeriveResponse.fromRawJson('not json'), throwsException);
    });
  });

  group('TradeModels', () {
    test('OpenContract.fromJson parses won contract', () {
      final json = {
        'contract_id': 'contract_123',
        'symbol': 'EURUSD',
        'contract_type': 'CALL',
        'buy_price': 50.0,
        'sell_price': 75.0,
        'profit_loss': 25.0,
        'status': 'won',
        'date_start': 1000000,
        'date_expiry': 1003600,
        'entry_tick': 1.1000,
        'exit_tick': 1.1050,
        'currency': 'USD',
        'is_sold': 1,
      };
      final contract = OpenContract.fromJson(json);
      expect(contract.contractId, 'contract_123');
      expect(contract.symbol, 'EURUSD');
      expect(contract.contractType, ContractType.callPut);
      expect(contract.buyPrice, 50.0);
      expect(contract.sellPrice, 75.0);
      expect(contract.profitLoss, 25.0);
      expect(contract.status, ContractStatus.won);
      expect(contract.isSold, isTrue);
      expect(contract.entryTick, 1.1000);
      expect(contract.exitTick, 1.1050);
      expect(contract.currency, 'USD');
    });

    test('OpenContract.fromJson parses lost contract', () {
      final json = {
        'contract_id': 'contract_456',
        'symbol': 'GBPUSD',
        'contract_type': 'PUT',
        'buy_price': 50.0,
        'profit_loss': -50.0,
        'status': 'lost',
        'date_start': 1000000,
        'currency': 'USD',
        'is_sold': 1,
      };
      final contract = OpenContract.fromJson(json);
      expect(contract.status, ContractStatus.lost);
      expect(contract.profitLoss, -50.0);
    });

    test('AccountBalance.fromJson parses virtual account', () {
      final json = {
        'balance': 10000.0,
        'currency': 'USD',
        'is_virtual': 1,
      };
      final balance = AccountBalance.fromJson(json);
      expect(balance.balance, 10000.0);
      expect(balance.isVirtual, isTrue);
    });

    test('AccountBalance.fromJson parses real account', () {
      final json = {
        'balance': 5000.0,
        'deposited_funds': 5000.0,
        'profit_loss': 250.0,
        'currency': 'USD',
        'is_virtual': 0,
      };
      final balance = AccountBalance.fromJson(json);
      expect(balance.depositedFunds, 5000.0);
      expect(balance.profitLoss, 250.0);
      expect(balance.isVirtual, isFalse);
    });

    test('ProfitTableEntry.fromJson parses', () {
      final json = {
        'transaction_id': 'tx_1',
        'symbol': 'EURUSD',
        'buy_price': 50.0,
        'sell_price': 75.0,
        'profit_loss': 25.0,
        'contract_type': 'CALL',
        'date_start': 1000000,
        'date_expiry': 1003600,
        'currency': 'USD',
        'app_id': '12345',
      };
      final entry = ProfitTableEntry.fromJson(json);
      expect(entry.transactionId, 'tx_1');
      expect(entry.profitLoss, 25.0);
      expect(entry.contractType, 'CALL');
      expect(entry.sellPrice, 75.0);
    });

    test('TradePosition.fromJson parses', () {
      final json = {
        'transaction_id': 'tx_1',
        'symbol': 'EURUSD',
        'action': 'buy',
        'amount': 100.0,
        'balance': 9900.0,
        'date': 1000000,
        'contract_id': 'c_123',
      };
      final pos = TradePosition.fromJson(json);
      expect(pos.transactionId, 'tx_1');
      expect(pos.amount, 100.0);
      expect(pos.action, 'buy');
      expect(pos.balance, 9900.0);
    });
  });

  group('ContractCategory', () {
    test('categories have value and display', () {
      expect(ContractCategory.upDown.value, 'updown');
      expect(ContractCategory.upDown.display, 'Up/Down');
      expect(ContractCategory.highLow.value, 'highlow');
      expect(ContractCategory.highLow.display, 'High/Low');
    });

    test('all categories are defined', () {
      expect(ContractCategory.upDown, isNotNull);
      expect(ContractCategory.highLow, isNotNull);
      expect(ContractCategory.touchNoTouch, isNotNull);
      expect(ContractCategory.ends, isNotNull);
      expect(ContractCategory.stays, isNotNull);
      expect(ContractCategory.asian, isNotNull);
      expect(ContractCategory.callPut, isNotNull);
      expect(ContractCategory.runHighLow, isNotNull);
      expect(ContractCategory.digits, isNotNull);
      expect(ContractCategory.lookBacks, isNotNull);
      expect(ContractCategory.ticks100, isNotNull);
      expect(ContractCategory.forwardStart, isNotNull);
    });
  });
}
