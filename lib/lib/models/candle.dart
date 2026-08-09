Enterclass Candle {
  final DateTime openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  Candle({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.fromBinanceKline(List<dynamic> raw) {
    return Candle(
      openTime: DateTime.fromMillisecondsSinceEpoch(raw[0] as int),
      open: double.parse(raw[1] as String),
      high: double.parse(raw[2] as String),
      low: double.parse(raw[3] as String),
      close: double.parse(raw[4] as String),
      volume: double.parse(raw[5] as String),
    );
  }
}

enum Timeframe { h1, h4, d1 }

extension TimeframeBinance on Timeframe {
  String get binanceInterval {
    switch (this) {
      case Timeframe.h1:
        return '1h';
      case Timeframe.h4:
        return '4h';
      case Timeframe.d1:
        return '1d';
    }
  }

  String get label {
    switch (this) {
      case Timeframe.h1:
        return '1H';
      case Timeframe.h4:
        return '4H';
      case Timeframe.d1:
        return '1D';
    }
  }

  double get weight {
    switch (this) {
      case Timeframe.h1:
        return 0.25;
      case Timeframe.h4:
        return 0.35;
      case Timeframe.d1:
        return 0.40;
    }
  }
}
