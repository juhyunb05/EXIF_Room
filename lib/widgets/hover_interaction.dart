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
    this.hoverScale = 1.06,
    this.hoverOpacity = 0.9,
    this.duration = const Duration(milliseconds: 250),
    this.enableScale = true,
    this.enableOpacity = true,
  });

  @override
  State<HoverInteraction> createState() => _HoverInteractionState();
}

class _HoverInteractionState extends State<HoverInteraction> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final CurvedAnimation curve = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      reverseCurve: const Cubic(0.7, 0.0, 0.84, 0.0),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.hoverScale,
    ).animate(curve);

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: widget.hoverOpacity,
    ).animate(curve);
  }

  @override
  void didUpdateWidget(covariant HoverInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        cursor: SystemMouseCursors.click,
        hitTestBehavior: HitTestBehavior.translucent,
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, childWidget) {
            Widget result = childWidget!;

            if (widget.enableOpacity && widget.hoverOpacity != 1.0) {
              result = Opacity(
                opacity: _opacityAnimation.value,
                child: result,
              );
            }

            if (widget.enableScale && widget.hoverScale != 1.0) {
              result = Transform.scale(
                scale: _scaleAnimation.value,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                child: result,
              );
            }

            return result;
          },
        ),
      ),
    );
  }
}
