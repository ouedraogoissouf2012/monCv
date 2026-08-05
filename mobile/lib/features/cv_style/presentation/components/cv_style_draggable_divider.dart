import 'package:flutter/material.dart';

/// Separateur draggable (poignee hover) entre le panneau options et l'apercu
/// en mode large (issue #247, B4a). Extrait de `_DraggableDivider`.
class CvStyleDraggableDivider extends StatefulWidget {
  const CvStyleDraggableDivider({super.key});

  @override
  State<CvStyleDraggableDivider> createState() =>
      _CvStyleDraggableDividerState();
}

class _CvStyleDraggableDividerState extends State<CvStyleDraggableDivider> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 16,
        color: _hovering
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.05),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Container(
                width: 4,
                height: 4,
                margin: EdgeInsets.only(bottom: i < 2 ? 3 : 0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _hovering ? 0.6 : 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
