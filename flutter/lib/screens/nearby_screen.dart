import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/nearby_person.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/back_bar.dart';
import '../widgets/gradient_background.dart';

/// flutter_map + OpenStreetMap tiles — no Google Maps key. The people shown
/// are mock offsets around the device's (or a fallback) location; a real
/// "who's nearby" feed needs accounts + consented location upload, which is
/// out of scope until login is backed by a real service.
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  static const _fallbackCenter = LatLng(39.9042, 116.4074); // Beijing, used if location is unavailable.

  static const _mockPeople = [
    NearbyPerson(name: '林晨', initials: 'LC', activity: '力量训练中', offset: LatLng(0.004, 0.003)),
    NearbyPerson(name: '陈可', initials: 'CK', activity: '刚结束夜跑', offset: LatLng(-0.003, 0.005)),
    NearbyPerson(name: '阿宇', initials: 'AY', activity: '在附近的训练舱', offset: LatLng(0.002, -0.004)),
  ];

  LatLng _center = _fallbackCenter;
  bool _loading = true;
  String? _locationNote;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _locationNote = '未授权定位，显示示例位置';
          _loading = false;
        });
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationNote = '定位服务未开启，显示示例位置';
          _loading = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationNote = '定位失败，显示示例位置';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Column(
        children: [
          const BackBar(title: '附近的人'),
          if (_locationNote != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_locationNote!, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.textMuted)),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _loading
                    ? const ColoredBox(color: Colors.black12, child: Center(child: CircularProgressIndicator()))
                    : FlutterMap(
                        options: MapOptions(initialCenter: _center, initialZoom: 14),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.restpod.hud',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _center,
                                width: 40,
                                height: 40,
                                child: const _PersonPin(initials: '我', color: AppColors.brandGreen),
                              ),
                              for (final person in _mockPeople)
                                Marker(
                                  point: LatLng(_center.latitude + person.offset.latitude, _center.longitude + person.offset.longitude),
                                  width: 40,
                                  height: 40,
                                  child: _PersonPin(initials: person.initials, color: AppColors.cardioBlue),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final person in _mockPeople)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: AppColors.cardioBlue, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(person.initials, style: const TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.ink)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(person.name, style: AppTextStyles.cardName)),
                        Text(person.activity, style: AppTextStyles.cardMeta),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonPin extends StatelessWidget {
  const _PersonPin({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.ink)),
    );
  }
}
