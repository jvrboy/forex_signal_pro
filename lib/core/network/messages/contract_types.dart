enum ContractType {
  riseFall,
  higherLower,
  highLowTick,
  touchNoTouch,
  endsInOut,
  staysInOut,
  asianUpDown,
  callPutSpread,
  callPutEqual,
  resetCallPut,
  callPut,
  runHighLow,
  digits,
  digitsMatchDiff,
  lookBacks,
  ticks100,
  forwardStart;
}

enum DurationUnit { tick, second, minute, hour, day, week, month, year }

enum BarrierCategory { price, time, noBarrier, relative }

enum Basis { stake, payout }

enum ContractStatus { open, closed, won, lost, sold, expired, cancelled }

class ContractCategory {
  final String value;
  final String display;

  const ContractCategory({required this.value, required this.display});

  static final upDown = ContractCategory(value: 'updown', display: 'Up/Down');
  static final highLow = ContractCategory(value: 'highlow', display: 'High/Low');
  static final touchNoTouch = ContractCategory(value: 'touchnotouch', display: 'Touch/No Touch');
  static final ends = ContractCategory(value: 'ends', display: 'Ends');
  static final stays = ContractCategory(value: 'stays', display: 'Stays');
  static final asian = ContractCategory(value: 'asian', display: 'Asian');
  static final callPut = ContractCategory(value: 'callput', display: 'Call/Put');
  static final runHighLow = ContractCategory(value: 'runhighlow', display: 'Run High/Low');
  static final digits = ContractCategory(value: 'digits', display: 'Digits');
  static final lookBacks = ContractCategory(value: 'lookbacks', display: 'LookBacks');
  static final ticks100 = ContractCategory(value: 'ticks100', display: '100 Ticks');
  static final forwardStart = ContractCategory(value: 'forwardstart', display: 'Forward Start');
}
