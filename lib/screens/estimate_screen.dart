import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EstimateScreen extends StatelessWidget {
    const EstimateScreen({super.key});

    @override
    Widget build(BuildContext context) {
          final c = context.colors;
          return Scaffold(
                  backgroundColor: c.background,
                  body: Center(
                            child: Text('Смета — раздел в разработке', style: TextStyle(color: c.secondaryLabel)),
                          ),
                );
    }
}
