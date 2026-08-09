Enterimport 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/candle.dart';

class BinanceApi {
  static const String _baseUrl = 'https://data-api.binance.vision/api/v3';

  final http.Client _client;
  BinanceApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Candle>> getKlines({
    required String symbol,
    required Timeframe timeframe,
    int limit = 200,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/klines?symbol=$symbol&interval=${timeframe.binanceInterval}&limit=$limit',
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw BinanceApiException(
        'Binance klines error (${res.statusCode}) for $symbol/${timeframe.label}: ${res.body}',
      );
    }
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((k) => Candle.fromBinanceKline(k as List<dynamic>)).toList();
  }

  Future<TickerSnapshot> get24hTicker(String symbol) async {
    final uri = Uri.parse('$_baseUrl/ticker/24hr?symbol=$symbol');
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw BinanceApiException(
        'Binance ticker error (${res.statusCode}) for $symbol: ${res.body}',
      );
    }
    final Map<String, dynamic> j = jsonDecode(res.body) as Map<String, dynamic>;
    return TickerSnapshot(
      lastPrice: double.parse(j['lastPrice'] as String),
      priceChangePercent: double.parse(j['priceChangePercent'] as String),
    );
  }
}

class TickerSnapshot {
  final double lastPrice;
  final double priceChangePercent;
  TickerSnapshot({required this.lastPrice, required this.priceChangePercent});
}

class BinanceApiException implements Exception {
  final String message;
  BinanceApiException(this.message);
  @override
  String toString() => message;
}
