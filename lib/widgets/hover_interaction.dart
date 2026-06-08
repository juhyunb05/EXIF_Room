import 'package:flutter/material.dart';

class HoverInteraction extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final double hoverOpacity;
  final Duration duration;
  final bool enableScale;
  final bool enableOpacity;

  const HoverInteraction({
    super.key,
    required this.child,
    this.hoverScale = 1.03,
    this.hoverOpacity = 0.8,
    this.duration = const Duration(milliseconds: 150),
    this.enableScale = true,
    this.enableOpacity = true,
  });

  @override
  State<HoverInteraction> createState() => _HoverInteractionState();
}

class _HoverInteractionState extends State<HoverInteraction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    if (widget.enableOpacity) {
      content = AnimatedOpacity(
        opacity: _isHovered ? widget.hoverOpacity : 1.0,
        duration: widget.duration,
        child: content,
      );
    }

    if (widget.enableScale) {
      content = AnimatedScale(
        scale: _isHovered ? widget.hoverScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: content,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: content,
    );
  }
}
