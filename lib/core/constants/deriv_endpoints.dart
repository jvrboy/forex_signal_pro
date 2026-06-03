class DerivEndpoints {
  DerivEndpoints._();

  static const String wsPublic = 'wss://ws.derivws.com/websockets/v3';
  static const String wsOtp = 'wss://api.derivws.com/trading/v1/options/ws';
  static const String restOtp = 'https://api.derivws.com/trading/v1/options/accounts';

  static String wsWithAppId(String appId) => '$wsPublic?app_id=$appId';

  static String restOtpForAccount(String accountId) => '$restOtp/$accountId/otp';

  static const String wsDemo =
      'wss://api.derivws.com/trading/v1/options/ws/demo';
  static const String wsReal =
      'wss://api.derivws.com/trading/v1/options/ws/real';

  static const String publicEndpoint = 'wss://ws.binaryws.com/websockets/v3';
}
