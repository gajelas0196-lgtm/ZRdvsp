import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);

  // Currency
  Map<String, double> _rates = {};
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  final TextEditingController _amountCtrl = TextEditingController(text: '1');
  double? _convertedAmount;
  bool _loadingRates = false;
  String? _ratesError;

  // Unit converter
  String _unitCategory = 'Panjang';
  String _fromUnit = 'Meter';
  String _toUnit = 'Kilometer';
  final TextEditingController _unitInputCtrl = TextEditingController(text: '1');
  String _unitResult = '';

  final List<String> _currencies = [
    'IDR', 'USD', 'EUR', 'GBP', 'JPY', 'SGD', 'MYR', 'AUD', 'CAD',
    'CHF', 'CNY', 'KRW', 'THB', 'PHP', 'INR', 'SAR', 'AED', 'HKD',
  ];

  final Map<String, Map<String, Map<String, double>>> _unitData = {
    'Panjang': {
      'Meter': {'Kilometer': 0.001, 'Centimeter': 100, 'Millimeter': 1000, 'Inch': 39.3701, 'Feet': 3.28084, 'Mile': 0.000621371, 'Yard': 1.09361},
      'Kilometer': {'Meter': 1000, 'Centimeter': 100000, 'Millimeter': 1000000, 'Inch': 39370.1, 'Feet': 3280.84, 'Mile': 0.621371, 'Yard': 1093.61},
      'Centimeter': {'Meter': 0.01, 'Kilometer': 0.00001, 'Millimeter': 10, 'Inch': 0.393701, 'Feet': 0.0328084, 'Mile': 0.0000062137, 'Yard': 0.0109361},
      'Inch': {'Meter': 0.0254, 'Centimeter': 2.54, 'Feet': 0.0833333, 'Yard': 0.0277778, 'Mile': 0.0000157828},
      'Feet': {'Meter': 0.3048, 'Centimeter': 30.48, 'Inch': 12, 'Yard': 0.333333, 'Mile': 0.000189394},
      'Mile': {'Kilometer': 1.60934, 'Meter': 1609.34, 'Feet': 5280, 'Yard': 1760},
      'Yard': {'Meter': 0.9144, 'Feet': 3, 'Inch': 36},
      'Millimeter': {'Meter': 0.001, 'Centimeter': 0.1},
    },
    'Berat': {
      'Kilogram': {'Gram': 1000, 'Milligram': 1000000, 'Pound': 2.20462, 'Ounce': 35.274, 'Ton': 0.001},
      'Gram': {'Kilogram': 0.001, 'Milligram': 1000, 'Pound': 0.00220462, 'Ounce': 0.035274},
      'Pound': {'Kilogram': 0.453592, 'Gram': 453.592, 'Ounce': 16},
      'Ounce': {'Pound': 0.0625, 'Gram': 28.3495, 'Kilogram': 0.0283495},
      'Ton': {'Kilogram': 1000, 'Pound': 2204.62},
      'Milligram': {'Gram': 0.001, 'Kilogram': 0.000001},
    },
    'Suhu': {}, // Handled separately
    'Luas': {
      'M²': {'KM²': 0.000001, 'CM²': 10000, 'Hektar': 0.0001, 'Are': 0.01},
      'KM²': {'M²': 1000000, 'Hektar': 100},
      'Hektar': {'M²': 10000, 'KM²': 0.01, 'Are': 100},
      'Are': {'M²': 100, 'Hektar': 0.01},
      'CM²': {'M²': 0.0001},
    },
    'Data': {
      'Byte': {'KB': 0.001, 'MB': 0.000001, 'GB': 0.000000001, 'TB': 0.000000000001},
      'KB': {'Byte': 1024, 'MB': 0.0009765625, 'GB': 0.00000095367},
      'MB': {'Byte': 1048576, 'KB': 1024, 'GB': 0.000976563, 'TB': 0.00000095367},
      'GB': {'Byte': 1073741824, 'KB': 1048576, 'MB': 1024, 'TB': 0.000976563},
      'TB': {'GB': 1024, 'MB': 1048576, 'KB': 1073741824},
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _unitInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    setState(() => _loadingRates = true);
    try {
      final resp = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _rates = Map<String, double>.from(
            data['rates'].map((k, v) => MapEntry(k, v.toDouble()))));
      }
    } catch (_) {
      setState(() => _ratesError = "Gagal memuat kurs. Pastikan koneksi internet aktif.");
    } finally {
      setState(() => _loadingRates = false);
    }
  }

  void _convertCurrency() {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || _rates.isEmpty) return;
    final fromRate = _rates[_fromCurrency] ?? 1;
    final toRate = _rates[_toCurrency] ?? 1;
    final inUSD = amount / fromRate;
    setState(() => _convertedAmount = inUSD * toRate);
  }

  void _convertUnit() {
    final val = double.tryParse(_unitInputCtrl.text);
    if (val == null) return;

    if (_unitCategory == 'Suhu') {
      double result;
      if (_fromUnit == 'Celsius' && _toUnit == 'Fahrenheit') result = val * 9/5 + 32;
      else if (_fromUnit == 'Fahrenheit' && _toUnit == 'Celsius') result = (val - 32) * 5/9;
      else if (_fromUnit == 'Celsius' && _toUnit == 'Kelvin') result = val + 273.15;
      else if (_fromUnit == 'Kelvin' && _toUnit == 'Celsius') result = val - 273.15;
      else if (_fromUnit == 'Fahrenheit' && _toUnit == 'Kelvin') result = (val - 32) * 5/9 + 273.15;
      else if (_fromUnit == 'Kelvin' && _toUnit == 'Fahrenheit') result = (val - 273.15) * 9/5 + 32;
      else result = val;
      setState(() => _unitResult = result.toStringAsFixed(4));
      return;
    }

    final catData = _unitData[_unitCategory];
    if (catData == null) return;
    final convTable = catData[_fromUnit];
    if (convTable == null) return;
    final factor = convTable[_toUnit];
    if (factor == null) {
      setState(() => _unitResult = "Konversi tidak tersedia");
      return;
    }
    setState(() => _unitResult = (val * factor).toStringAsFixed(6));
  }

  List<String> get _currentUnits {
    if (_unitCategory == 'Suhu') return ['Celsius', 'Fahrenheit', 'Kelvin'];
    return _unitData[_unitCategory]?.keys.toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "CONVERTER",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(color: lightPurple.withOpacity(0.8), blurRadius: 10)],
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: lightPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: lightPurple,
          labelStyle: const TextStyle(fontFamily: 'Orbitron', fontSize: 11),
          tabs: const [Tab(text: "MATA UANG"), Tab(text: "SATUAN")],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple.withOpacity(0.4), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Currency Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_loadingRates)
                  const Center(child: CircularProgressIndicator(color: Colors.purple))
                else if (_ratesError != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(_ratesError!,
                        style: const TextStyle(
                            color: Colors.red, fontFamily: 'ShareTechMono')),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: primaryPurple.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Orbitron',
                              fontSize: 24),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                        ),
                        const Divider(color: Colors.white12),
                        Row(
                          children: [
                            Expanded(child: _buildCurrencyDropdown(_fromCurrency, (v) => setState(() => _fromCurrency = v!))),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryPurple.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  final tmp = _fromCurrency;
                                  _fromCurrency = _toCurrency;
                                  _toCurrency = tmp;
                                }),
                                child: Icon(Icons.swap_horiz, color: lightPurple),
                              ),
                            ),
                            Expanded(child: _buildCurrencyDropdown(_toCurrency, (v) => setState(() => _toCurrency = v!))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _convertCurrency,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("KONVERSI",
                          style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_convertedAmount != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryPurple.withOpacity(0.3), accentPurple.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lightPurple.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${_amountCtrl.text} $_fromCurrency =",
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontFamily: 'ShareTechMono'),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => Clipboard.setData(
                                ClipboardData(text: _convertedAmount!.toStringAsFixed(2))),
                            child: Text(
                              "${_convertedAmount!.toStringAsFixed(2)} $_toCurrency",
                              style: TextStyle(
                                color: lightPurple,
                                fontFamily: 'Orbitron',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tap untuk menyalin",
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontFamily: 'ShareTechMono',
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Unit Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Category selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Panjang', 'Berat', 'Suhu', 'Luas', 'Data'].map((cat) {
                      final selected = _unitCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _unitCategory = cat;
                            final units = cat == 'Suhu'
                                ? ['Celsius', 'Fahrenheit', 'Kelvin']
                                : _unitData[cat]!.keys.toList();
                            _fromUnit = units.first;
                            _toUnit = units.length > 1 ? units[1] : units.first;
                            _unitResult = '';
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? primaryPurple.withOpacity(0.5) : cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? lightPurple.withOpacity(0.6) : Colors.white12,
                            ),
                          ),
                          child: Text(cat,
                              style: TextStyle(
                                  color: selected ? Colors.white : Colors.grey,
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: primaryPurple.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _unitInputCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                            color: Colors.white, fontFamily: 'Orbitron', fontSize: 22),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                            hintStyle: TextStyle(color: Colors.white24)),
                      ),
                      const Divider(color: Colors.white12),
                      Row(
                        children: [
                          Expanded(child: _buildUnitDropdown(_fromUnit, (v) => setState(() => _fromUnit = v!))),
                          Icon(Icons.arrow_forward, color: lightPurple),
                          Expanded(child: _buildUnitDropdown(_toUnit, (v) => setState(() => _toUnit = v!))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _convertUnit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("KONVERSI",
                        style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                  ),
                ),

                if (_unitResult.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryPurple.withOpacity(0.3), accentPurple.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lightPurple.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Text("${_unitInputCtrl.text} $_fromUnit =",
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontFamily: 'ShareTechMono')),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => Clipboard.setData(
                              ClipboardData(text: "$_unitResult $_toUnit")),
                          child: Text(
                            "$_unitResult $_toUnit",
                            style: TextStyle(
                              color: lightPurple,
                              fontFamily: 'Orbitron',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown(String value, Function(String?) onChanged) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: cardDark,
      style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontSize: 16),
      underline: const SizedBox(),
      isExpanded: true,
      items: _currencies
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildUnitDropdown(String value, Function(String?) onChanged) {
    final units = _currentUnits;
    return DropdownButton<String>(
      value: units.contains(value) ? value : units.first,
      dropdownColor: cardDark,
      style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono', fontSize: 12),
      underline: const SizedBox(),
      isExpanded: true,
      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: onChanged,
    );
  }
}
