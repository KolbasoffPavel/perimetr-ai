import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProjectScreen extends StatelessWidget {
    const ProjectScreen({super.key});

    @override
    Widget build(BuildContext context) {
          final c = context.colors;
          return Scaffold(
                  backgroundColor: c.background,
                  body: Center(
                            child: Text('Замеры — раздел в разработке', style: TextStyle(color: c.secondaryLabel)),
                          ),
                );
    }
}
