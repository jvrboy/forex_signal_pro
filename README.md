# Forex Signal Pro

A high-quality, open-source, cross-platform forex trading signal application with AI-powered analysis, self-optimizing neural network, and 350+ technical indicators.

## Features

- **AI-Powered Signal Engine** - High-probability trading signals using multi-strategy confluence scoring
- **Self-Optimizing Neural Network** - On-device ML that learns from signal outcomes and auto-adjusts parameters
- **350+ Technical Indicators** - Complete catalog across all categories (MA, Oscillators, Volatility, Patterns, Statistics)
- **400+ Trading Strategies** - Pre-built strategies covering all major trading styles
- **Deriv API Integration** - Real-time market data, trading execution, portfolio tracking
- **Forex Factory News Scraper** - Background web automation fetches economic calendar in SAST timezone
- **Liquid Glass UI** - iOS 26-style glassmorphism theme (4 themes available)
- **On-Device LLM Agent** - GGUF model via llamadart for contextual market analysis
- **Cross-Platform** - Flutter: Web, iOS, Android, macOS, Windows, Linux

## Architecture

```
lib/
├── core/                 # Constants, theme engine, network, storage, background services
├── features/
│   ├── auth/             # Deriv OAuth2 + PAT login
│   ├── market_data/      # Real-time prices, symbols, ticks
│   ├── charting/         # Interactive charts, drawing tools, 9 timeframes
│   ├── indicators/       # 350+ technical indicator implementations
│   ├── strategies/       # 400+ trading strategies + backtesting
│   ├── signals/          # Signal generator, neural tracker, failure analyzer
│   ├── news/             # Forex Factory scraper, SAST timezone
│   ├── ai_agent/         # LLM integration, tool-calling, market analysis
│   ├── trading/          # Deriv trade execution, portfolio
│   └── settings/         # Theme picker, API config, model management
└── shared/               # Reusable widgets
```

## Getting Started

### Prerequisites
- Flutter SDK 3.5+
- Dart 3.5+
- A Deriv API app ID (free from developers.deriv.com)

### Installation

```bash
git clone https://github.com/yourusername/forex_signal_pro
cd forex_signal_pro
flutter pub get
flutter run
```

### Configuration

1. Get a free Deriv App ID from https://developers.deriv.com
2. Set it in `lib/core/constants/app_constants.dart`
3. (Optional) Download a GGUF model for AI agent features

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.5+ / Dart 3.5+ |
| State Mgmt | Riverpod 2.x |
| Charts | trading_chart_flutter (CustomPainter) |
| Indicators | Pure Dart (deriv_technical_analysis + custom) |
| Neural Net | Pure Dart FFNN with backprop |
| LLM | llamadart (llama.cpp FFI) |
| ONNX | onnxruntime_v2 (GPU-accelerated) |
| WebSocket | Deriv API (ws.derivws.com) |
| Storage | Isar (local database) |
| Background | workmanager |
| News Scraping | Puppeteer (desktop) / XML feed (mobile) |
| UI Themes | 4 themes incl. Liquid Glass glassmorphism |

## License

MIT License - see LICENSE file.

## Contributing

Contributions welcome! See CONTRIBUTING.md for guidelines.
