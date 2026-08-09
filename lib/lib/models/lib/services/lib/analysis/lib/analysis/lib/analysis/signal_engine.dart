Enterimport '../models/candle.dart';
import 'market_structure.dart';
import 'supply_demand.dart';

enum SignalAction { buy, sell, wait }

class TimeframeAnalysis {
  final Timeframe timeframe;
  final MarketStructureResult structure;
  final List<Zone> zones;
  final List<double> srLevels;
  final double lastClose;

  TimeframeAnalysis({
    required this.timeframe,
    required this.structure,
    required this.zones,
    required this.srLevels,
    required this.lastClose,
  });
}

class TradeSetup {
  final double entryLow;
  final double entryHigh;
  final double stopLoss;
  final double tp1;
  final double tp2;
  final double tp3;
  final double riskReward;
  final String invalidation;

  TradeSetup({
    required this.entryLow,
    required this.entryHigh,
    required this.stopLoss,
    required this.tp1,
    required this.tp2,
    required this.tp3,
    required this.riskReward,
    required this.invalidation,
  });
}

class AnalysisResult {
  final String symbol;
  final double currentPrice;
  final double priceChangePercent;
  final Map<Timeframe, TimeframeAnalysis> byTimeframe;
  final SignalAction action;
  final int confidence;
  final TradeSetup? setup;
  final List<String> reasons;
  final List<String> waitReasons;

  AnalysisResult({
    required this.symbol,
    required this.currentPrice,
    required this.priceChangePercent,
    required this.byTimeframe,
    required this.action,
    required this.confidence,
    required this.setup,
    required this.reasons,
    required this.waitReasons,
  });
}

class SignalEngine {
  static AnalysisResult evaluate({
    required String symbol,
    required double currentPrice,
    required double priceChangePercent,
    required Map<Timeframe, TimeframeAnalysis> byTimeframe,
  }) {
    final reasons = <String>[];
    final waitReasons = <String>[];

    double bullScore = 0;
    double bearScore = 0;

    for (final tf in byTimeframe.keys) {
      final tfa = byTimeframe[tf]!;
      final w = tf.weight;
      if (tfa.structure.trend == TrendDirection.bullish) {
        bullScore += w;
        reasons.add('${tf.label} structure is bullish.');
      } else if (tfa.structure.trend == TrendDirection.bearish) {
        bearScore += w;
        reasons.add('${tf.label} structure is bearish.');
      }
    }

    final higherTf = byTimeframe[Timeframe.d1] ?? byTimeframe[Timeframe.h4];
    final entryTf = byTimeframe[Timeframe.h1];

    double score = 50;
    score += (bullScore - bearScore) * 35;

    Zone? demandZone;
    Zone? supplyZone;
    if (entryTf != null) {
      demandZone = SupplyDemandAnalyzer.nearestDemandBelow(entryTf.zones, currentPrice);
      supplyZone = SupplyDemandAnalyzer.nearestSupplyAbove(entryTf.zones, currentPrice);

      if (demandZone != null) {
        final distancePct = (currentPrice - demandZone.high).abs() / currentPrice;
        if (distancePct < 0.02) {
          score += 15 * demandZone.strength;
          reasons.add('Price is near a demand zone on ${entryTf.timeframe.label} '
              '(${demandZone.isFresh ? "fresh" : "${demandZone.touches} touches"}).');
        }
      }
    }

    score = score.clamp(0, 100);
    final confidence = score.round();

    final higherBullish = higherTf?.structure.trend == TrendDirection.bullish;
    final entryBullishEvent = entryTf?.structure.lastEvent == StructureEventType.bosBullish ||
        entryTf?.structure.lastEvent == StructureEventType.chochBullish;

    if (!higherBullish) {
      waitReasons.add('Higher timeframe (1D/4H) is not bullish — no long bias.');
    }
    if (demandZone == null) {
      waitReasons.add('No valid fresh demand zone near current price.');
    }
    if (!entryBullishEvent) {
      waitReasons.add('No confirmed bullish BOS/CHoCH on the entry timeframe (1H).');
    }

    SignalAction action = SignalAction.wait;
    TradeSetup? setup;

    final conditionsMet = higherBullish && demandZone != null && entryBullishEvent;

    if (conditionsMet && demandZone != null) {
      final entryLow = demandZone.low;
      final entryHigh = demandZone.high;
      final buffer = (entryHigh - entryLow) * 0.15 + entryLow * 0.001;
      final stopLoss = entryLow - buffer;

      final risk = entryHigh - stopLoss;
      final tp1 = entryHigh + risk * 1.5;
      final tp2 = supplyZone != null ? supplyZone.low : entryHigh + risk * 2.5;
      final tp3 = supplyZone != null ? supplyZone.high : entryHigh + risk * 3.5;

      final rr = (tp1 - entryHigh) / risk;

      if (rr < 2.0) {
        waitReasons.add('Risk/Reward to TP1 is ${rr.toStringAsFixed(2)}, below the required 1:2 minimum.');
      } else {
        action = SignalAction.buy;
        setup = TradeSetup(
          entryLow: entryLow,
          entryHigh: entryHigh,
          stopLoss: stopLoss,
          tp1: tp1,
          tp2: tp2,
          tp3: tp3,
          riskReward: rr,
          invalidation: 'Idea is invalidated if price closes below ${stopLoss.toStringAsFixed(4)} '
              '(below the demand zone), which would break the bullish structure this setup relies on.',
        );
        reasons.add('Risk/Reward to TP1 is 1:${rr.toStringAsFixed(2)}, meeting the minimum requirement.');
      }
    }

    if (action == SignalAction.wait && waitReasons.isEmpty) {
      waitReasons.add('Signals across timeframes are mixed or inconclusive.');
    }

    return AnalysisResult(
      symbol: symbol,
      currentPrice: currentPrice,
      priceChangePercent: priceChangePercent,
      byTimeframe: byTimeframe,
      action: action,
      confidence: confidence,
      setup: setup,
      reasons: reasons,
      waitReasons: action == SignalAction.wait ? waitReasons : [],
    );
  }
}
