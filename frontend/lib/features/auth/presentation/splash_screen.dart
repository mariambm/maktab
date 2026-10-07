import 'package:flutter/material.dart';

import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/maktab_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MaktabLogo(size: 48),
            SizedBox(height: MaktabSpacing.lg),
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}
