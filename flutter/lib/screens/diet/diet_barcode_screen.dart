import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../../state/diet_log_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/gradient_background.dart';
import 'diet_meal_picker_screen.dart';

/// Barcode → Open Food Facts lookup. Falls back to manual pick when the
/// barcode isn't recognized or the lookup fails (no network, unlisted
/// product, etc).
class DietBarcodeScreen extends StatefulWidget {
  const DietBarcodeScreen({super.key, required this.dietLog});

  final DietLogController dietLog;

  @override
  State<DietBarcodeScreen> createState() => _DietBarcodeScreenState();
}

enum _LookupState { scanning, loading, found, notFound }

class _DietBarcodeScreenState extends State<DietBarcodeScreen> {
  final _scannerController = MobileScannerController();
  _LookupState _state = _LookupState.scanning;
  Product? _product;
  String? _error;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_state != _LookupState.scanning) return;
    if (capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;
    setState(() => _state = _LookupState.loading);
    await _scannerController.stop();
    try {
      OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'RestPodHUD');
      final config = ProductQueryConfiguration(
        barcode,
        version: ProductQueryVersion.v3,
        fields: [ProductField.NAME, ProductField.NUTRIMENTS, ProductField.QUANTITY],
      );
      final result = await OpenFoodAPIClient.getProductV3(config);
      if (!mounted) return;
      if (result.status == ProductResultV3.statusSuccess && result.product != null) {
        setState(() {
          _product = result.product;
          _state = _LookupState.found;
        });
      } else {
        setState(() {
          _error = '未在 Open Food Facts 找到该条码';
          _state = _LookupState.notFound;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '查询失败（$e）';
        _state = _LookupState.notFound;
      });
    }
  }

  int _kcal(Product product) =>
      (product.nutriments?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams) ?? 0).round();

  int _macro(Product product, Nutrient nutrient) =>
      (product.nutriments?.getValue(nutrient, PerSize.oneHundredGrams) ?? 0).round();

  Future<void> _confirm(Product product) async {
    await widget.dietLog.logBarcodeProduct(
      name: product.productName ?? '未命名商品',
      kcal: _kcal(product),
      proteinG: _macro(product, Nutrient.proteins),
      carbG: _macro(product, Nutrient.carbohydrates),
      fatG: _macro(product, Nutrient.fat),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已打卡：${product.productName ?? "条码商品"}')),
    );
  }

  void _retry() {
    setState(() {
      _state = _LookupState.scanning;
      _error = null;
      _product = null;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Column(
        children: [
          const BackBar(title: '扫码识别'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(controller: _scannerController, onDetect: _onDetect),
                    if (_state == _LookupState.loading)
                      const ColoredBox(
                        color: Colors.black38,
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildBottom(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    switch (_state) {
      case _LookupState.scanning:
        return Text(
          '对准商品条码，来自 Open Food Facts 的公开数据库',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.textMuted),
        );
      case _LookupState.loading:
        return const Text('查询中…', style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted));
      case _LookupState.found:
        final product = _product!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.productName ?? '未命名商品', style: AppTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text('${_kcal(product)} kcal / 100g', style: AppTextStyles.cardMeta),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: _retry, child: const Text('重新扫描')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.brandGreen, foregroundColor: AppColors.ink),
                      onPressed: () => _confirm(product),
                      child: const Text('确认打卡'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case _LookupState.notFound:
        return Column(
          children: [
            Text(_error ?? '未识别到条码', style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _retry, child: const Text('重新扫描'))),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.brandGreen, foregroundColor: AppColors.ink),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => DietMealPickerScreen(dietLog: widget.dietLog)),
                      );
                    },
                    child: const Text('手动选择'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
