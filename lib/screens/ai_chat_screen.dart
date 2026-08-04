import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
bool _sending = false;
String? _error;

Future<void> _send(AppState appState) async {
final text = _controller.text.trim();
if (text.isEmpty || _sending) return;
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
} catch (e) {
setState(() => _error = 'Ошибка: $e');
} finally {
setState(() => _sending = false);
}
}

@override
Widget build(BuildContext context) {
final c = context.colors;
final appState = context.watch<AppState>();
final messages = appState.activeProject.chatMessages;

return Scaffold(
backgroundColor: c.background,
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
return Align(
alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
child: Container(
margin: const EdgeInsets.only(bottom: 10),
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
decoration: BoxDecoration(
color: isUser ? c.accent : c.cardBackground,
borderRadius: BorderRadius.circular(16),
),
child: Text(m.text, style: TextStyle(color: isUser ? Colors.white : c.label)),
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
Expanded(
child: TextField(
controller: _controller,
style: TextStyle(color: c.label),
decoration: const InputDecoration(hintText: 'Сообщение...'),
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
