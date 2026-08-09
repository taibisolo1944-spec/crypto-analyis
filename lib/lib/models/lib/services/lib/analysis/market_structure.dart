hereimport '../models/candle.dart';

enum SwingType { high, low }

class SwingPoint {
  final int index;
  final double price;
  final SwingType type;
  SwingPoint(this.index, this.price, this.type);
}

enum StructureLabel { hh, hl, lh, ll, none }

enum TrendDirection { bullish, bearish, neutral }

enum StructureEventType { bosBullish, bosBearish, chochBullish, chochBearish, none }

class MarketStructureResult {
  final List<SwingPoint> swings;
  final TrendDirection trend;
  final StructureEventType lastEvent;
  final String explanation;

  MarketStructureResult({
    required this.swings,
    required this.trend,
    required this.lastEvent,
    required this.explanation,
  });
}

class MarketStructureAnalyzer {
  static List<SwingPoint> findSwings(List<Candle> candles, {int lookback = 3}) {
    final swings = <SwingPoint>[];
    for (int i = lookback; i < candles.length - lookback; i++) {
      final windowHighs = candles
          .sublist(i - lookback, i + lookback + 1)
          .map((c) => c.high);
      final windowLows = candles
          .sublist(i - lookback, i + lookback + 1)
          .map((c) => c.low);

      if (candles[i].high == windowHighs.reduce((a, b) => a > b ? a : b)) {
        swings.add(SwingPoint(i, candles[i].high, SwingType.high));
      }
      if (candles[i].low == windowLows.reduce((a, b) => a < b ? a : b)) {
        swings.add(SwingPoint(i, candles[i].low, SwingType.low));
      }
    }
    return swings;
  }

  static MarketStructureResult analyze(List<Candle> candles, {int lookback = 3}) {
    if (candles.length < lookback * 2 + 5) {
      return MarketStructureResult(
        swings: [],
        trend: TrendDirection.neutral,
        lastEvent: StructureEventType.none,
        explanation: 'Not enough candles to determine structure reliably.',
      );
    }

    final swings = findSwings(candles, lookback: lookback);
    final highs = swings.where((s) => s.type == SwingType.high).toList();
    final lows = swings.where((s) => s.type == SwingType.low).toList();

    if (highs.length < 2 || lows.length < 2) {
      return MarketStructureResult(
        swings: swings,
        trend: TrendDirection.neutral,
        lastEvent: StructureEventType.none,
        explanation: 'Not enough confirmed swing points yet.',
      );
    }

    final lastHigh = highs.last;
    final prevHigh = highs[highs.length - 2];
    final lastLow = lows.last;
    final prevLow = lows[lows.length - 2];

    final higherHigh = lastHigh.price > prevHigh.price;
    final higherLow = lastLow.price > prevLow.price;
    final lowerHigh = lastHigh.price < prevHigh.price;
    final lowerLow = lastLow.price < prevLow.price;

    TrendDirection trend;
    if (higherHigh && higherLow) {
      trend = TrendDirection.bullish;
    } else if (lowerHigh && lowerLow) {
      trend = TrendDirection.bearish;
    } else {
      trend = TrendDirection.neutral;
    }

    final lastClose = candles.last.close;
    StructureEventType event = StructureEventType.none;
    String eventNote = 'No structural break yet.';

    if (lastClose > lastHigh.price) {
      if (trend == TrendDirection.bullish) {
        event = StructureEventType.bosBullish;
        eventNote = 'Price broke above the last swing high, continuing the bullish structure (BOS).';
      } else {
        event = StructureEventType.chochBullish;
        eventNote = 'Price broke above the last swing high against a bearish/neutral bias — possible bullish CHoCH.';
      }
    } else if (lastClose < lastLow.price) {
      if (trend == TrendDirection.bearish) {
        event = StructureEventType.bosBearish;
        eventNote = 'Price broke below the last swing low, continuing the bearish structure (BOS).';
      } else {
        event = StructureEventType.chochBearish;
        eventNote = 'Price broke below the last swing low against a bullish/neutral bias — possible bearish CHoCH.';
      }
    }

    final trendLabel = trend == TrendDirection.bullish
        ? 'bullish (HH+HL)'
        : trend == TrendDirection.bearish
            ? 'bearish (LH+LL)'
            : 'neutral / mixed';

    return MarketStructureResult(
      swings: swings,
      trend: trend,
      lastEvent: event,
      explanation: 'Structure is $trendLabel. $eventNote',
    );
  }
}
