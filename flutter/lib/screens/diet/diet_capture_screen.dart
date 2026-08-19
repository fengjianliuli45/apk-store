import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../state/diet_log_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/gradient_background.dart';
import 'diet_barcode_screen.dart';
import 'diet_estimate_sheet.dart';
import 'diet_history_screen.dart';
import 'diet_meal_picker_screen.dart';
import 'diet_recipes_screen.dart';

/// Replaces the old CameraPlaceholderScreen. Take a photo → the app shows a
/// local-catalog *estimate* (never framed as AI vision), or scan a barcode →
/// Open Food Facts lookup, or skip straight to picking a meal by hand.
class DietCaptureScreen extends StatefulWidget {
  const DietCaptureScreen({super.key, required this.dietLog});

  final DietLogController dietLog;

  @override
  State<DietCaptureScreen> createState() => _DietCaptureScreenState();
}

class _DietCaptureScreenState extends State<DietCaptureScreen> {
  CameraController? _controller;
  String? _cameraError;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = '没有可用摄像头';
          _initializing = false;
        });
        return;
      }
      final controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = '相机不可用（$e）';
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.takePicture();
    } catch (_) {
      // Fall through to the catalog estimate regardless — the photo is only
      // a visual record, the log itself comes from the local catalog.
    }
    if (!mounted) return;
    _showEstimate();
  }

  void _showEstimate() {
    final template = widget.dietLog.estimateForPhoto();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DietEstimateSheet(
        initial: template,
        onReroll: widget.dietLog.estimateForPhoto,
        onConfirm: (t) async {
          await widget.dietLog.logTemplate(t);
          if (!mounted) return;
          Navigator.of(context).pop();
          _showLoggedSnack(t.name);
        },
        onManualPick: () {
          Navigator.of(context).pop();
          _openPicker();
        },
      ),
    );
  }

  void _showLoggedSnack(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已打卡：$name')),
    );
  }

  void _openBarcodeScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DietBarcodeScreen(dietLog: widget.dietLog)),
    );
  }

  void _openPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DietMealPickerScreen(dietLog: widget.dietLog)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Column(
        children: [
          BackBar(
            title: '饮食打卡',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconChip(
                  icon: Icons.history,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DietHistoryScreen(dietLog: widget.dietLog)),
                  ),
                ),
                const SizedBox(width: 8),
                _IconChip(
                  icon: Icons.restaurant_menu,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DietRecipesScreen(dietLog: widget.dietLog)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildPreview(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '拍照仅作记录留存，餐次热量来自本地目录估算，不是 AI 视觉识别',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: '拍照记录',
                        icon: Icons.camera_alt,
                        filled: true,
                        onTap: _takePhoto,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: '扫条码',
                        icon: Icons.qr_code_scanner,
                        filled: false,
                        onTap: _openBarcodeScan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  label: '手动选择食物',
                  icon: Icons.list_alt,
                  filled: false,
                  onTap: _openPicker,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_initializing) {
      return const ColoredBox(color: Colors.black12, child: Center(child: CircularProgressIndicator()));
    }
    final controller = _controller;
    if (controller == null || _cameraError != null) {
      return ColoredBox(
        color: Colors.black12,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _cameraError ?? '相机不可用',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }
    return CameraPreview(controller);
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
