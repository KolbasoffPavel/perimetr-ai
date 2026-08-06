import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../state/app_state.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';

class AiChatScreen extends StatefulWidget {
const AiChatScreen({super.key});
@override
State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
final _controller = TextEditingController();
final _speech = stt.SpeechToText();
final _tts = FlutterTts();
bool _sending = false;
bool _listening = false;
bool _speakReplies = false;
String? _error;

@override
void initState() {
super.initState();
_tts.setLanguage('ru-RU');
}

@override
void dispose() {
_speech.stop();
_tts.stop();
super.dispose();
}

Future<void> _toggleListening() async {
if (_listening) {
await _speech.stop();
setState(() => _listening = false);
return;
}
final available = await _speech.initialize(
onError: (e) => setState(() => _error = 'Ошибка распознавания: ${e.errorMsg}'),
);
if (!available) {
setState(() => _error = 'Голосовой ввод недоступен на этом устройстве');
return;
}
setState(() {
_listening = true;
_error = null;
});
await _speech.listen(
localeId: 'ru_RU',
onResult: (result) {
setState(() => _controller.text = result.recognizedWords);
if (result.finalResult) {
setState(() => _listening = false);
}
},
);
}

Future<void> _send(AppState appState) async {
final text = _controller.text.trim();
if (text.isEmpty || _sending) return;
if (_listening) {
await _speech.stop();
setState(() => _listening = false);
}
setState(() {
_sending = true;
_error = null;
});
appState.addChatMessage('user', text);
_controller.clear();
try {
final history = appState.activeProject.chatMessages
.map((m) => {'role': m.role, 'text': m.text})
.toList();
final reply = await AiService().chat(history);
appState.addChatMessage('assistant', reply);
if (_speakReplies) {
await _tts.speak(reply);
}
} catch (e) {
setState(() => _error = 'Ошибка: $e');
} finally {
setState(() => _sending = false);
}
}

void _confirmClearChat(AppState appState) {
showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: const Text('Очистить переписку?'),
content: const Text('Все сообщения этого объекта будут удалены без возможности восстановления.'),
actions: [
TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
TextButton(
onPressed: () {
appState.clearChat();
Navigator.pop(ctx);
},
child: const Text('Очистить'),
),
],
),
);
}
@override
Widget build(BuildContext context) {
final c = context.colors;
final appState = context.watch<AppState>();
final messages = appState.activeProject.chatMessages;

return Scaffold(
backgroundColor: c.background,
appBar: AppBar(
title: const Text('ИИ Чат'),
actions: [
IconButton(
icon: Icon(_speakReplies ? Icons.volume_up : Icons.volume_off, color: c.label),
tooltip: 'Озвучивать ответы',
onPressed: () => setState(() => _speakReplies = !_speakReplies),
),
if (messages.isNotEmpty)
IconButton(
icon: Icon(Icons.delete_sweep, color: c.label),
tooltip: 'Очистить переписку',
onPressed: () => _confirmClearChat(appState),
),
],
),
body: Column(
children: [
Expanded(
child: messages.isEmpty
? Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Text('Задайте вопрос по ремонту — ИИ поможет с советом',
style: TextStyle(color: c.secondaryLabel), textAlign: TextAlign.center),
),
)
: ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: messages.length,
itemBuilder: (context, i) {
final m = messages[i];
final isUser = m.role == 'user';
final bubble = Flexible(
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
decoration: BoxDecoration(
color: isUser ? c.accent : c.cardBackground,
borderRadius: BorderRadius.circular(16),
),
child: Text(m.text, style: TextStyle(color: isUser ? Colors.white : c.label)),
),
);
final deleteBtn = GestureDetector(
onTap: () => appState.removeChatMessage(m.id),
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 4),
child: Icon(Icons.close, size: 16, color: c.tertiaryLabel),
),
);
return Padding(
padding: const EdgeInsets.only(bottom: 10),
child: Row(
mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
crossAxisAlignment: CrossAxisAlignment.start,
children: isUser ? [deleteBtn, bubble] : [bubble, deleteBtn],
),
);
},
),
),
if (_error != null)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16),
child: Text(_error!, style: TextStyle(color: c.destructive, fontSize: 12)),
),
SafeArea(
top: false,
child: Padding(
padding: const EdgeInsets.all(12),
child: Row(
children: [
IconButton(
icon: Icon(_listening ? Icons.mic : Icons.mic_none, color: _listening ? c.destructive : c.accent),
onPressed: _toggleListening,
),
Expanded(
child: TextField(
controller: _controller,
style: TextStyle(color: c.label),
decoration: InputDecoration(hintText: _listening ? 'Слушаю...' : 'Сообщение...'),
onSubmitted: (_) => _send(appState),
),
),
const SizedBox(width: 8),
_sending
? const SizedBox(
width: 40,
height: 40,
child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)),
)
: IconButton(
icon: Icon(Icons.send, color: c.accent),
onPressed: () => _send(appState),
),
],
),
),
),
],
),
);
}
}
