import 'package:flutter/material.dart';

class AnimatedCardButton extends StatefulWidget {
  final Widget Function(bool hovering, double scale) childBuilder;
  final VoidCallback onTap;

  const AnimatedCardButton({
    super.key,
    required this.childBuilder,
    required this.onTap,
  });

  @override
  State<AnimatedCardButton> createState() => _AnimatedCardButtonState();
}

class _AnimatedCardButtonState extends State<AnimatedCardButton> {
  double _scale = 1.0;
  bool _hovering = false;

  void _onTapDown(_) {
    setState(() => _scale = 1.05);
  }

  void _onTapUp(_) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _hovering = true;
        _scale = 1.02;
      }),
      onExit: (_) => setState(() {
        _hovering = false;
        _scale = 1.0;
      }),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: widget.childBuilder(_hovering, _scale),
      ),
    );
  }
}