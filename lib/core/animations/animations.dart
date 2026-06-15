import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Spring easing from the design — fast-out with gentle overshoot.
const kSpring = Cubic(0.16, 1.0, 0.3, 1.0);

const kSheetDuration = Duration(milliseconds: 360);
const kFadeUpDuration = Duration(milliseconds: 280);

// BobWidget — gentle float ±amplitude dp, 3 s ease-in-out loop
class BobWidget extends StatefulWidget {
  const BobWidget({super.key, required this.child, this.amplitude = 5.0, this.duration = const Duration(seconds: 3)});
  final Widget child;
  final double amplitude;
  final Duration duration;
  @override
  State<BobWidget> createState() => _BobWidgetState();
}
class _BobWidgetState extends State<BobWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _curved;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.repeat(reverse: true);
  }
  @override
  void dispose() {
    _curved.dispose();
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final dy = -widget.amplitude * sin(_curved.value * pi);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

// RingWidget — pulse ring scale 1→2.2, opacity 0.55→0, 2.6 s loop
class RingWidget extends StatefulWidget {
  const RingWidget({super.key, required this.child, required this.color, this.size = 52.0, this.maxScale = 2.2});
  final Widget child;
  final Color color;
  final double size;
  final double maxScale;
  @override
  State<RingWidget> createState() => _RingWidgetState();
}
class _RingWidgetState extends State<RingWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _scale = Tween(begin: 1.0, end: widget.maxScale).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.55), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.0), weight: 60),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
    ]).animate(_ctrl);
    _ctrl.repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size, height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withOpacity(_opacity.value), width: 2),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

// FadeUpWidget — fade in + slide up 9 dp, optional stagger delay
class FadeUpWidget extends StatefulWidget {
  const FadeUpWidget({super.key, required this.child, this.delay = Duration.zero, this.duration = kFadeUpDuration});
  final Widget child;
  final Duration delay;
  final Duration duration;
  @override
  State<FadeUpWidget> createState() => _FadeUpWidgetState();
}
class _FadeUpWidgetState extends State<FadeUpWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _ctrl, curve: kSpring);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(curved);
    _slide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(curved);
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
    }
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide, child: widget.child));
  }
}

// PopWidget — scale 0.6→1.06→1.0 + fade, spring easing
class PopWidget extends StatefulWidget {
  const PopWidget({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;
  @override
  State<PopWidget> createState() => _PopWidgetState();
}
class _PopWidgetState extends State<PopWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _scale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4)));
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
    }
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(opacity: _opacity.value, child: Transform.scale(scale: _scale.value, child: child)),
      child: widget.child,
    );
  }
}

// BlinkingCursor — 1.1 s step blink (550 ms on / 550 ms off)
class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({super.key, this.color, this.width = 1.5, this.height = 18.0});
  final Color? color;
  final double width;
  final double height;
  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}
class _BlinkingCursorState extends State<BlinkingCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _ctrl.repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _ctrl.value < 0.5 ? 1.0 : 0.0,
        child: Container(
          width: widget.width, height: widget.height,
          decoration: BoxDecoration(color: widget.color ?? AppColors.accent, borderRadius: BorderRadius.circular(1)),
        ),
      ),
    );
  }
}

// AnimatedDot — pill/circle for onboarding progress indicator
class AnimatedDot extends StatelessWidget {
  const AnimatedDot({super.key, required this.active, required this.past});
  final bool active;
  final bool past;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: kSpring,
      width: active ? 20.0 : 7.0,
      height: 7.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active ? AppColors.accent : past ? AppColors.accentDim : const Color(0x1FFFFFFF),
      ),
    );
  }
}
