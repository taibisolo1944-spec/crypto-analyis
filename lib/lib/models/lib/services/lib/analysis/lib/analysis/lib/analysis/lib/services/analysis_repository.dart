hereimport '../models/candle.dart';
import '../analysis/market_structure.dart';
import '../analysis/supply_demand.dart';
import '../analysis/signal_engine.dart';
import 'binance_api.dart';

class AnalysisRepository {
  final BinanceApi api;
  AnalysisRepository({BinanceApi? api}) : api = api ?? BinanceApi();

  static const List<Timeframe> _timeframes = [Timeframe.h1, Timeframe.h4, Timeframe.d1];

  Future<AnalysisResult> analyzeSymbol(String symbol) async {
    final ticker = await api.get24hTicker(symbol);

    final Map<Timeframe, TimeframeAnalysis> byTf = {};
    for (final tf in _timeframes) {
      final candles = await api.getKlines(symbol: symbol, timeframe: tf, limit: 200);
      final structure = MarketStructureAnalyzer.analyze(candles);
      final zones = SupplyDemandAnalyzer.findZones(candles);
      final srLevels = SupportResistanceAnalyzer.findLevels(candles);

      byTf[tf] = TimeframeAnalysis(
        timeframe: tf,
        structure: structure,
        zones: zones,
        srLevels: srLevels,
        lastClose: candles.last.close,
      );
    }

    return SignalEngine.evaluate(
      symbol: symbol,
      currentPrice: ticker.lastPrice,
      priceChangePercent: ticker.priceChangePercent,
      byTimeframe: byTf,
    );
  }
}
