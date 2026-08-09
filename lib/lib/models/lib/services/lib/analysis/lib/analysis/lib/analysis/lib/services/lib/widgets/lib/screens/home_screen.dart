hereimport 'package:flutter/material.dart';
import '../analysis/signal_engine.dart';
import '../services/analysis_repository.dart';
import '../widgets/coin_summary_card.dart';
import 'coin_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = AnalysisRepository();

  static const symbols = {
    'LINKUSDT': 'LINK/USDT',
    'BCHUSDT': 'BCH/USDT',
  };

  late Map<String, Future<AnalysisResult>> _futures;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _futures = {for (final s in symbols.keys) s: _repo.analyzeSymbol(s)};
  }

  Future<void> _refresh() async {
    setState(() => _loadAll());
    await Future.wait(_futures.values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto AI Analyzer'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _DisclaimerBanner(),
            const SizedBox(height: 8),
            for (final entry in symbols.entries)
              FutureBuilder<AnalysisResult>(
                future: _futures[entry.key],
                builder: (context, snapshot) => CoinSummaryCard(
                  label: entry.value,
                  snapshot: snapshot,
                  onTap: () {
                    if (!snapshot.hasData) return;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CoinDetailScreen(
                        symbol: entry.key,
                        label: entry.value,
                        initialResult: snapshot.data!,
                        repo: _repo,
                      ),
                    ));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: const Text(
        'Technical analysis tool only — not financial advice. Signals can be WAIT '
        'when conditions are insufficient. Always do your own research.',
        style: TextStyle(fontSize: 12, color: Colors.amberAccent),
      ),
    );
  }
}
