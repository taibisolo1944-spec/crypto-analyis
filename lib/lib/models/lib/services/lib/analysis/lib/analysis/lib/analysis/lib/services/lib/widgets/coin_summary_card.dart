hereimport 'package:flutter/material.dart';
import '../analysis/signal_engine.dart';
import '../analysis/market_structure.dart';

class CoinSummaryCard extends StatelessWidget {
  final String label;
  final AsyncSnapshot<AnalysisResult> snapshot;
  final VoidCallback onTap;

  const CoinSummaryCard({
    super.key,
    required this.label,
    required this.snapshot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (snapshot.hasError) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      );
    }

    final result = snapshot.data!;
    final actionColor = _actionColor(result.action);
    final trend1d = result.byTimeframe[Timeframe.d1]?.structure.trend ?? TrendDirection.neutral;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: actionColor),
                    ),
                    child: Text(
                      result.action.name.toUpperCase(),
                      style: TextStyle(color: actionColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${result.currentPrice.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  Text(
                    '${result.priceChangePercent >= 0 ? '+' : ''}${result.priceChangePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: result.priceChangePercent >= 0 ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.trending_up, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Trend: ${trend1d.name} (1D)', style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  Text('Confidence: ${result.confidence}/100',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _actionColor(SignalAction action) {
    switch (action) {
      case SignalAction.buy:
        return Colors.greenAccent;
      case SignalAction.sell:
        return Colors.redAccent;
      case SignalAction.wait:
        return Colors.amberAccent;
    }
  }
}
