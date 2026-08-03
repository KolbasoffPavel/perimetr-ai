import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PricesScreen extends StatelessWidget {
    const PricesScreen({super.key});

    @override
    Widget build(BuildContext context) {
          final c = context.colors;
          return Scaffold(
                  backgroundColor: c.background,
                  body: Center(
                            child: Text('Цены — раздел в разработке', style: TextStyle(color: c.secondaryLabel)),
                          ),
                );
    }
}
