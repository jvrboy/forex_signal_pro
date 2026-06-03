enum MsgType {
  authorize,
  activeSymbols,
  ticks,
  tickHistory,
  buy,
  sell,
  sellExpired,
  portfolio,
  profitTable,
  balance,
  proposal,
  proposalOpenContract,
  contractFor,
  tradingTimes,
  assets,
  ping,
  time,
  logout,
  websiteStatus,
  serverTime,
  accountList,
  statement,
  mt5LoginList,
  tradingPlatformInvestorLogin,
  tradingPlatformAccounts,
  accountToken,
  realityCheck,
  landingCompanyDetails,
  residenceList,
  statesList,
  tncApproval,
  setAccountCurrency,
  paymentMethods,
  paymentAgentList,
  paymentAgentTransfer,
  p2pAdvertList,
  p2pOrderCreate,
  p2pOrderList,
  p2pOrderDispute,
  exchangeRates,
  topUpVirtualMoney,
  copyStart,
  copyStop,
  copytradingList,
  copytradingStatistics,
  transaction,
  subscribe,
  forget,
  forgetAll;

  String get key {
    switch (this) {
      case MsgType.authorize:
        return 'authorize';
      case MsgType.activeSymbols:
        return 'active_symbols';
      case MsgType.ticks:
        return 'ticks';
      case MsgType.tickHistory:
        return 'tick_history';
      case MsgType.buy:
        return 'buy';
      case MsgType.sell:
        return 'sell';
      case MsgType.sellExpired:
        return 'sell_expired';
      case MsgType.portfolio:
        return 'portfolio';
      case MsgType.profitTable:
        return 'profit_table';
      case MsgType.balance:
        return 'balance';
      case MsgType.proposal:
        return 'proposal';
      case MsgType.proposalOpenContract:
        return 'proposal_open_contract';
      case MsgType.contractFor:
        return 'contracts_for';
      case MsgType.tradingTimes:
        return 'trading_times';
      case MsgType.assets:
        return 'assets';
      case MsgType.ping:
        return 'ping';
      case MsgType.time:
        return 'time';
      case MsgType.logout:
        return 'logout';
      case MsgType.websiteStatus:
        return 'website_status';
      case MsgType.serverTime:
        return 'server_time';
      case MsgType.accountList:
        return 'account_list';
      case MsgType.statement:
        return 'statement';
      case MsgType.mt5LoginList:
        return 'mt5_login_list';
      case MsgType.tradingPlatformInvestorLogin:
        return 'trading_platform_investor_login';
      case MsgType.tradingPlatformAccounts:
        return 'trading_platform_accounts';
      case MsgType.accountToken:
        return 'account_token';
      case MsgType.realityCheck:
        return 'reality_check';
      case MsgType.landingCompanyDetails:
        return 'landing_company_details';
      case MsgType.residenceList:
        return 'residence_list';
      case MsgType.statesList:
        return 'states_list';
      case MsgType.tncApproval:
        return 'tnc_approval';
      case MsgType.setAccountCurrency:
        return 'set_account_currency';
      case MsgType.paymentMethods:
        return 'payment_methods';
      case MsgType.paymentAgentList:
        return 'paymentagent_list';
      case MsgType.paymentAgentTransfer:
        return 'paymentagent_transfer';
      case MsgType.p2pAdvertList:
        return 'p2p_advert_list';
      case MsgType.p2pOrderCreate:
        return 'p2p_order_create';
      case MsgType.p2pOrderList:
        return 'p2p_order_list';
      case MsgType.p2pOrderDispute:
        return 'p2p_order_dispute';
      case MsgType.exchangeRates:
        return 'exchange_rates';
      case MsgType.topUpVirtualMoney:
        return 'topup_virtual';
      case MsgType.copyStart:
        return 'copy_start';
      case MsgType.copyStop:
        return 'copy_stop';
      case MsgType.copytradingList:
        return 'copytrading_list';
      case MsgType.copytradingStatistics:
        return 'copytrading_statistics';
      case MsgType.transaction:
        return 'transaction';
      case MsgType.subscribe:
        return 'subscribe';
      case MsgType.forget:
        return 'forget';
      case MsgType.forgetAll:
        return 'forget_all';
    }
  }

  static MsgType fromKey(String key) {
    return MsgType.values.firstWhere(
      (t) => t.key == key,
      orElse: () => throw ArgumentError('Unknown message type: $key'),
    );
  }
}
