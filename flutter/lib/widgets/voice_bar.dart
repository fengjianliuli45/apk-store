import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The limited command set the voice bar understands. No cloud/LLM parsing —
/// just keyword matching against the recognized text.
enum VoiceCommand { startTraining, openSocial, openDiet }

/// "有什么可以帮你的？" pill on Home. Tap to talk; on-device speech_to_text
/// maps the transcript to [VoiceCommand]. If the mic/recognizer isn't
/// available (no permission, no engine on device) it silently falls back to
/// an idle hint instead of erroring.
class VoiceBar extends StatefulWidget {
  const VoiceBar({super.key, required this.onCommand});

  final ValueChanged<VoiceCommand> onCommand;

  @override
  State<VoiceBar> createState() => _VoiceBarState();
}

class _VoiceBarState extends State<VoiceBar> {
  final _speech = stt.SpeechToText();
  bool _listening = false;
  String _hint = '有什么可以帮你的？';

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _listening = false);
        }
      },
    );
    if (!available) {
      if (mounted) {
        setState(() => _hint = '没有语音权限，说"开始训练/社交/饮食"');
      }
      return;
    }
    setState(() {
      _listening = true;
      _hint = '在听...';
    });
    await _speech.listen(
      onResult: _handleResult,
      listenOptions: stt.SpeechListenOptions(localeId: 'zh_CN'),
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;
    if (!mounted) return;
    setState(() => _hint = text.isEmpty ? '在听...' : text);
    if (!result.finalResult) return;
    final command = _matchCommand(text);
    setState(() {
      _listening = false;
      _hint = command == null ? '没听懂，试试"开始训练"' : '有什么可以帮你的？';
    });
    if (command != null) widget.onCommand(command);
  }

  VoiceCommand? _matchCommand(String text) {
    if (text.contains('训练') || text.contains('开始')) return VoiceCommand.startTraining;
    if (text.contains('社交')) return VoiceCommand.openSocial;
    if (text.contains('饮食') || text.contains('拍照') || text.contains('吃饭')) {
      return VoiceCommand.openDiet;
    }
    return null;
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleListening,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Row(
          children: [
            Icon(
              _listening ? Icons.mic : Icons.mic_none,
              color: _listening ? AppColors.brandGreen : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.inter,
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
