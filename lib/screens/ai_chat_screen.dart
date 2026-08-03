import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: Text('ИИ Чат — раздел в разработке', style: TextStyle(color: c.secondaryLabel)),
        ),
      );
  }
}
