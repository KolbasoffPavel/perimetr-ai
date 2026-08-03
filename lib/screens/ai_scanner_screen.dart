import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AiScannerScreen extends StatelessWidget {
    const AiScannerScreen({super.key});

    @override
    Widget build(BuildContext context) {
          final c = context.colors;
          return Scaffold(
                  backgroundColor: c.background,
                  body: Center(
                            child: Text('AI-Сканер — раздел в разработке', style: TextStyle(color: c.secondaryLabel)),
                          ),
                );
    }
}
