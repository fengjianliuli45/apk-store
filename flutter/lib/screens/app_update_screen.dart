import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppRelease {
  AppRelease(this.version, this.build, this.url, this.notes);
  final String version;
  final int build;
  final String url;
  final String notes;
  factory AppRelease.parse(Map<String, dynamic> json) {
    final url = Uri.tryParse(json['url'] as String? ?? '');
    final build = json['build'];
    if (build is! int ||
        build < 1 ||
        json['version'] is! String ||
        url == null ||
        url.scheme != 'https' ||
        url.host != 'mainleaf.top' ||
        url.hasPort ||
        url.userInfo.isNotEmpty ||
        !url.path.startsWith('/apk/') ||
        !url.path.endsWith('.apk')) {
      throw const FormatException('Invalid release');
    }
    return AppRelease(
      json['version'] as String,
      build,
      url.toString(),
      json['notes'] as String? ?? '',
    );
  }
}

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});
  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  static const _channel = MethodChannel('com.restpod.hud/update');
  bool _busy = false;
  String _status = '检查是否有新版本';
  AppRelease? _release;

  Future<void> _check() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _release = null;
      _status = '正在检查…';
    });
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final local = await _channel.invokeMapMethod<String, dynamic>('version');
      final request = await client
          .getUrl(Uri.parse('https://mainleaf.top/apk/latest.json'))
          .timeout(const Duration(seconds: 10));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) {
        throw const HttpException('Update unavailable');
      }
      final bytes = <int>[];
      await response.timeout(const Duration(seconds: 10)).forEach((chunk) {
        bytes.addAll(chunk);
        if (bytes.length > 65536) {
          throw const FormatException('Manifest too large');
        }
      });
      final release = AppRelease.parse(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        _release = release.build > (local?['build'] as int? ?? 0)
            ? release
            : null;
        _status = _release == null
            ? '当前已是最新版本（${local?['version']}）'
            : '发现新版本 ${release.version}';
      });
    } catch (_) {
      if (mounted) setState(() => _status = '暂时无法检查更新，请稍后重试');
    } finally {
      client.close(force: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    try {
      await _channel.invokeMethod<void>('openDownload', _release!.url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开浏览器，请访问 mainleaf.top/apk/')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('应用更新')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_status),
          const SizedBox(height: 16),
          if (_release != null) ...[
            Text(_release!.notes),
            const SizedBox(height: 16),
            const Text('将在浏览器下载 APK，由系统确认安装。'),
            FilledButton(onPressed: _download, child: const Text('下载更新')),
          ],
          OutlinedButton(
            onPressed: _busy ? null : _check,
            child: Text(_busy ? '检查中…' : '检查更新'),
          ),
        ],
      ),
    ),
  );
}
