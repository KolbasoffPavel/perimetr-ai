import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../state/app_state.dart';
import '../services/ai_service.dart';
import '../services/ai_tools.dart';
import '../theme/app_colors.dart';

class _PendingAttachment {
final String path;
final String name;
final String base64;
final String mediaType;
_PendingAttachment({required this.path, required this.name, required this.base64, required this.mediaType});
}

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
_PendingAttachment? _attachment;

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

Future<void> _pickAttachment() async {
final result = await FilePicker.platform.pickFiles(type: FileType.image);
if (result == null || result.files.single.path == null) return;
final path = result.files.single.path!;
final name = result.files.single.name;
final bytes = await File(path).readAsBytes();
final ext = name.toLowerCase().split('.').last;
final mediaType = switch (ext) {
'png' => 'image/png',
'webp' => 'image/webp',
'gif' => 'image/gif',
_ => 'image/jpeg',
};
setState(() {
_attachment = _PendingAttachment(path: path, name: name, base64: base64Encode(bytes), mediaType: mediaType);
});
}

void _removeAttachment() => setState(() => _attachment = null);
Future<void> _send(AppState appState) async {
final text = _controller.text.trim();
if ((text.isEmpty && _attachment == null) || _sending) return;
if (_listening) {
await _speech.stop();
setState(() => _listening = false);
}
final attachment = _attachment;
setState(() {
_sending = true;
_error = null;
});

final displayText = attachment != null
? (text.isEmpty ? '[Фото: ${attachment.name}]' : '$text\n[Фото: ${attachment.name}]')
: text;
appState.addChatMessage('user', displayText);
_controller.clear();
setState(() => _attachment = null);

try {
final history = appState.activeProject.chatMessages
.map((m) => <String, dynamic>{'role': m.role, 'content': m.text})
.toList();

if (attachment != null) {
history[history.length - 1] = {
'role': 'user',
'content': [
{
'type': 'image',
'source': {'type': 'base64', 'media_type': attachment.mediaType, 'data': attachment.base64},
},
{'type': 'text', 'text': text.isEmpty ? 'Проанализируй это изображение' : text},
],
};
}

var response = await AiService().chatRaw(history, tools: assistantTools, system: assistantSystemPrompt);
var content = response['content'] as List;
final toolUses = content.where((b) => b['type'] == 'tool_use').toList();

if (toolUses.isNotEmpty) {
final toolResults = <Map<String, dynamic>>[];
for (final tu in toolUses) {
final result = executeAssistantTool(tu['name'] as String, (tu['input'] as Map).cast<String, dynamic>(), appState);
toolResults.add({'type': 'tool_result', 'tool_use_id': tu['id'], 'content': jsonEncode(result)});
}
final followUp = [
...history,
{'role': 'assistant', 'content': content},
{'role': 'user', 'content': toolResults},
];
response = await AiService().chatRaw(followUp, tools: assistantTools, system: assistantSystemPrompt);
content = response['content'] as List;
}

final buffer = StringBuffer();
for (final block in content) {
if (block['type'] == 'text') buffer.write(block['text']);
}
final reply = buffer.toString();
appState.addChatMessage('assistant', reply.isEmpty ? 'Готово.' : reply);
if (_speakReplies && reply.isNotEmpty) {
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
child: Text(
'Задайте вопрос по ремонту, приложите фото или попросите добавить помещение/позицию в смету — ИИ умеет менять данные проекта сам',
style: TextStyle(color: c.secondaryLabel),
textAlign: TextAlign.center,
),
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
if (_attachment != null)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16),
child: Align(
alignment: Alignment.centerLeft,
child: Chip(
avatar: const Icon(Icons.image, size: 18),
label: Text(_attachment!.name, overflow: TextOverflow.ellipsis),
onDeleted: _removeAttachment,
),
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
icon: Icon(Icons.add_circle_outline, color: c.accent),
tooltip: 'Прикрепить фото',
onPressed: _sending ? null : _pickAttachment,
),
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
