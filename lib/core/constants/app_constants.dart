class AppConstants {
  AppConstants._();

  static const String appName = 'Forex Signal Pro';
  static const String appVersion = '0.1.0';
  static const String derivWsUrl = 'wss://ws.derivws.com/websockets/v3';
  static const String derivApiUrl = 'https://api.derivws.com';
  static const String derivAppId = 'YOUR_APP_ID';
  static const String forexFactoryXmlUrl = 'https://www.forexfactory.com/ffcal_week_this.xml';
  static const String forexFactoryCalendarUrl = 'https://www.forexfactory.com/calendar';
  static const String sastTimezone = 'Africa/Johannesburg';
  static const int wsPingIntervalSeconds = 30;
  static const int wsReconnectMaxRetries = 5;
  static const int newsPollIntervalMinutes = 60;
  static const int signalMonitorIntervalMinutes = 15;
  static const int nnTrainingIntervalHours = 24;
  static const double defaultSelfFixThreshold = 0.15;
  static const int maxSignalsInMemory = 1000;
}
