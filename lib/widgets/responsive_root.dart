import 'package:flutter/material.dart';

class ResponsiveRoot extends StatelessWidget {
  final Widget child;

  const ResponsiveRoot({super.key, required this.child});

  /// Kompaktný režim (mobil)
  static bool isCompact(double width) => width < 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        double scale;
        if (width >= 1200) {
          scale = 1.0;
        } else if (width >= 800) {
          scale = 0.95;
        } else if (width >= 600) {
          scale = 0.90;
        } else {
          scale = 0.85;
        }

        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child,
        );
      },
    );
  }
}
