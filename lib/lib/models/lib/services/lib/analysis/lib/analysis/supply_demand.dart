Enterimport '../models/candle.dart';

enum ZoneType { demand, supply }

class Zone {
  final ZoneType type;
  final double low;
  final double high;
  final int originIndex;
  int touches;
  final double strength;

  Zone({
    required this.type,
    required this.low,
    required this.high,
    required this.originIndex,
    this.touches = 0,
    required this.strength,
  });

  double get mid => (low + high) / 2;
  bool get isFresh => touches == 0;

  bool contains(double price) => price >= low && price <= high;
}

class SupplyDemandAnalyzer {
  static List<Zone> findZones(
    List<Candle> candles, {
    double impulseMultiplier = 1.8,
    int minZones = 0,
  }) {
    if (candles.length < 10) return [];

    final bodies = candles.map((c) => (c.close - c.open).abs()).toList();
    final avgBody = bodies.reduce((a, b) => a + b) / bodies.length;

    final zones = <Zone>[];

    for (int i = 1; i < candles.length - 1; i++) {
      final origin = candles[i];
      final next = candles[i + 1];
      final nextBody = (next.close - next.open).abs();

      if (next.close > next.open && nextBody > avgBody * impulseMultiplier) {
        zones.add(Zone(
          type: ZoneType.demand,
          low: origin.low,
          high: origin.open < origin.close ? origin.open : origin.close,
          originIndex: i,
          strength: (nextBody / avgBody).clamp(0, 3) / 3,
        ));
      }

      if (next.close < next.open && nextBody > avgBody * impulseMultiplier) {
        zones.add(Zone(
          type: ZoneType.supply,
          low: origin.open > origin.close ? origin.open : origin.close,
          high: origin.high,
          originIndex: i,
          strength: (nextBody / avgBody).clamp(0, 3) / 3,
        ));
      }
    }

    for (final zone in zones) {
      for (int j = zone.originIndex + 2; j < candles.length; j++) {
        final c = candles[j];
        if (zone.contains(c.low) || zone.contains(c.high) || zone.contains(c.close)) {
          zone.touches++;
        }
      }
    }

    zones.removeWhere((z) => z.touches > 3);
    return zones;
  }

  static Zone? nearestDemandBelow(List<Zone> zones, double price) {
    final candidates = zones.where((z) => z.type == ZoneType.demand && z.high <= price).toList()
      ..sort((a, b) => b.high.compareTo(a.high));
    return candidates.isEmpty ? null : candidates.first;
  }

  static Zone? nearestSupplyAbove(List<Zone> zones, double price) {
    final candidates = zones.where((z) => z.type == ZoneType.supply && z.low >= price).toList()
      ..sort((a, b) => a.low.compareTo(b.low));
    return candidates.isEmpty ? null : candidates.first;
  }
}

class SupportResistanceAnalyzer {
  static List<double> findLevels(List<Candle> candles, {double tolerancePct = 0.006}) {
    if (candles.isEmpty) return [];
    final prices = <double>[];
    for (final c in candles) {
      prices.add(c.high);
      prices.add(c.low);
    }
    prices.sort();

    final clusters = <List<double>>[];
    for (final p in prices) {
      if (clusters.isEmpty || (p - clusters.last.last).abs() > clusters.last.last * tolerancePct) {
        clusters.add([p]);
      } else {
        clusters.last.add(p);
      }
    }

    return clusters
        .where((c) => c.length >= 3)
        .map((c) => c.reduce((a, b) => a + b) / c.length)
        .toList();
  }
}
