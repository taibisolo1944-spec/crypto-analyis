hereimport 'package:flutter/material.dart';
import '../analysis/market_structure.dart';
import '../analysis/signal_engine.dart';
import '../models/candle.dart';
import '../services/analysis_repository.dart';

class CoinDetailScreen extends StatefulWidget {
  final String symbol;
  final String label;
  final AnalysisResult initialResult;
  final AnalysisRepository repo;

  const CoinDetailScreen({
    super.key,
    required this.symbol,
    required this.label,
    required this.initialResult,
    required this.repo,
  });

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  late AnalysisResult _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final r = await widget.repo.analyzeSymbol(widget.symbol);
      setState(() => _result = r);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: _loading
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(r),
          const SizedBox(height: 16),
          const Text('TIMEFRAME ANALYSIS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          for (final tf in [Timeframe.h1, Timeframe.h4, Timeframe.d1])
            if (r.byTimeframe[tf] != null) _timeframeTile(r.byTimeframe[tf]!),
          const SizedBox(height: 16),
          if (r.setup != null) _setupCard(r) else _waitCard(r),
          const SizedBox(height: 16),
          _whyCard(r),
        ],
      ),
    );
  }

  Widget _headerCard(AnalysisResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${r.currentPrice.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Signal: ${r.action.name.toUpperCase()}   ·   Confidence: ${r.confidence}/100'),
          ],
        ),
      ),
    );
  }

  Widget _timeframeTile(TimeframeAnalysis tfa) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(tfa.timeframe.label),
        subtitle: Text(tfa.structure.explanation),
        trailing: Text(
          tfa.structure.trend.name,
          style: TextStyle(
            color: tfa.structure.trend == TrendDirection.bullish
                ? Colors.greenAccent
                : tfa.structure.trend == TrendDirection.bearish
                    ? Colors.redAccent
                    : Colors.amberAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _setupCard(AnalysisResult r) {
    final s = r.setup!;
    return Card(
      color: Colors.greenAccent.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.greenAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BUY SETUP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            const SizedBox(height: 10),
            _row('Entry', '${s.entryLow.toStringAsFixed(4)} - ${s.entryHigh.toStringAsFixed(4)}'),
            _row('Stop Loss', s.stopLoss.toStringAsFixed(4)),
            _row('TP1', s.tp1.toStringAsFixed(4)),
            _row('TP2', s.tp2.toStringAsFixed(4)),
            _row('TP3', s.tp3.toStringAsFixed(4)),
            _row('Risk/Reward', '1:${s.riskReward.toStringAsFixed(2)}'),
            _row('Confidence', '${r.confidence}/100'),
            const SizedBox(height: 8),
            Text('Invalidation: ${s.invalidation}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _waitCard(AnalysisResult r) {
    return Card(
      color: Colors.amberAccent.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.amberAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WAIT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
            const SizedBox(height: 8),
            for (final reason in r.waitReasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $reason', style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _whyCard(AnalysisResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WHY THIS SIGNAL?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final reason in r.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $reason', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
