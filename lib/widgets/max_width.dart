import 'package:flutter/widgets.dart';

/// Clamps [child] to [maxWidth] and centers it — keeps forms and feeds
/// readable on wide (web/desktop) viewports without touching phone layouts.
class MaxWidthBox extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidthBox({super.key, this.maxWidth = 720, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
