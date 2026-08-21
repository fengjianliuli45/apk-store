import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../state/diet_log_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'diet_barcode_screen.dart';
import 'diet_estimate_sheet.dart';
import 'diet_history_screen.dart';
import 'diet_meal_picker_screen.dart';
import 'diet_recipes_screen.dart';

/// Figma screen-camera (199:65). The bundled meal image is only used when a
/// live camera preview is unavailable.
class DietCaptureScreen extends StatefulWidget {
  const DietCaptureScreen({super.key, required this.dietLog});

  final DietLogController dietLog;

  @override
  State<DietCaptureScreen> createState() => _DietCaptureScreenState();
}

class _DietCaptureScreenState extends State<DietCaptureScreen> {
  CameraController? _controller;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await controller.initialize();
        if (!mounted) return;
        setState(() => _controller = controller);
      }
    } catch (_) {
      // Fallback image keeps the designed state useful without permission.
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      try {
        await controller.takePicture();
      } catch (_) {}
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DietEstimateSheet(
          dietLog: widget.dietLog,
          initial: widget.dietLog.estimateForPhoto(),
          onReroll: widget.dietLog.estimateForPhoto,
          onConfirm: widget.dietLog.logTemplate,
          onManualPick: _openPicker,
        ),
      ),
    );
  }

  void _openPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DietMealPickerScreen(dietLog: widget.dietLog),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0C0F11),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _RoundAction(
                  icon: Icons.cancel_outlined,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedBuilder(
                  animation: widget.dietLog,
                  builder: (context, _) {
                    final remaining =
                        widget.dietLog.goals.kcal - widget.dietLog.todayKcal;
                    final line = remaining > 0
                        ? '拍一张你的餐食吧 · 还差 $remaining kcal'
                        : remaining == 0
                            ? '今日热量已达标'
                            : '今日已超 ${-remaining} kcal';
                    return Row(
                      children: [
                        const _GlowIndicator(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            line,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _cameraPreview(),
                      ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
                      const CustomPaint(painter: _ViewfinderPainter()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _initializing ? '正在准备相机…' : '对准食物进行识别',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundAction(
                    icon: Icons.qr_code_scanner,
                    label: '条码',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DietBarcodeScreen(dietLog: widget.dietLog),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  _RoundAction(
                    icon: Icons.more_horiz,
                    label: '更多',
                    onTap: () => _showMore(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraPreview() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 720,
          height: controller.value.previewSize?.width ?? 1280,
          child: CameraPreview(controller),
        ),
      );
    }
    return Image.asset('assets/diet/camera-meal.png', fit: BoxFit.cover);
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: _SheetAction(
                  icon: Icons.edit_note,
                  label: '手动记录',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openPicker();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetAction(
                  icon: Icons.history,
                  label: '饮食记录',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DietHistoryScreen(dietLog: widget.dietLog),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetAction(
                  icon: Icons.restaurant_menu,
                  label: '推荐食谱',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DietRecipesScreen(dietLog: widget.dietLog),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowIndicator extends StatelessWidget {
  const _GlowIndicator();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.brandGreen,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.brandGreen, blurRadius: 8)],
        ),
      ),
      const SizedBox(width: 5),
      Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: AppColors.brandGreen,
          shape: BoxShape.circle,
        ),
      ),
    ],
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap, this.label});
  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (label != null) ...[
            const SizedBox(height: 5),
            Text(
              label!,
              style: const TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      grid,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      grid,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      grid,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      grid,
    );
    final corner = Paint()
      ..color = AppColors.brandGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const i = 20.0;
    const l = 24.0;
    final paths = [
      Path()
        ..moveTo(i, i + l)
        ..lineTo(i, i)
        ..lineTo(i + l, i),
      Path()
        ..moveTo(size.width - i - l, i)
        ..lineTo(size.width - i, i)
        ..lineTo(size.width - i, i + l),
      Path()
        ..moveTo(i, size.height - i - l)
        ..lineTo(i, size.height - i)
        ..lineTo(i + l, size.height - i),
      Path()
        ..moveTo(size.width - i - l, size.height - i)
        ..lineTo(size.width - i, size.height - i)
        ..lineTo(size.width - i, size.height - i - l),
    ];
    for (final path in paths) {
      canvas.drawPath(path, corner);
    }
    canvas.drawCircle(
      size.center(Offset.zero),
      10,
      Paint()..color = AppColors.brandGreen.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      size.center(Offset.zero),
      4,
      Paint()..color = AppColors.brandGreen,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}
