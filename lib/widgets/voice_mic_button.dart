import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/app_colors.dart';

/// Компактная кнопка-микрофон для быстрой диктовки текста в любое поле
/// ввода — надиктованный текст сразу подставляется в [controller].
/// Используется в диалогах добавления (помещение, прайс, смета), в
/// отличие от "умного" голосового ввода в ИИ-чате не обращается к ИИ —
/// просто быстрая замена набора текста с клавиатуры.
class VoiceMicButton extends StatefulWidget {
final TextEditingController controller;
final double size;
const VoiceMicButton({super.key, required this.controller, this.size = 20});

@override
State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton> {
final _speech = stt.SpeechToText();
bool _listening = false;

Future<void> _toggle() async {
if (_listening) {
await _speech.stop();
if (mounted) setState(() => _listening = false);
return;
}
final available = await _speech.initialize();
if (!available || !mounted) return;
setState(() => _listening = true);
await _speech.listen(
localeId: 'ru_RU',
onResult: (result) {
widget.controller.text = result.recognizedWords;
widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
if (result.finalResult && mounted) setState(() => _listening = false);
},
);
}

@override
void dispose() {
_speech.stop();
super.dispose();
}

@override
Widget build(BuildContext context) {
final c = context.colors;
return IconButton(
padding: EdgeInsets.zero,
constraints: const BoxConstraints(),
icon: Icon(
_listening ? Icons.mic : Icons.mic_none,
color: _listening ? c.destructive : c.secondaryLabel,
size: widget.size,
),
onPressed: _toggle,
);
}
}
