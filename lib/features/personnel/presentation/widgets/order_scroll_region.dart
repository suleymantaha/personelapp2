import 'dart:async';
import 'package:flutter/material.dart';

/// Scrolls the outer team list while a nested personnel drag rests at an edge.
class OrderScrollRegion extends StatefulWidget {
  const OrderScrollRegion({super.key, required this.builder});
  final Widget Function(ScrollController, ValueChanged<bool>) builder;
  @override
  State<OrderScrollRegion> createState() => _OrderScrollRegionState();
}

class _OrderScrollRegionState extends State<OrderScrollRegion> {
  final _controller = ScrollController();
  Timer? _timer;
  bool _dragging = false;
  double _step = 0;
  void _drag(bool active) {
    _dragging = active;
    if (!active) {
      _timer?.cancel();
      _timer = null;
      _step = 0;
    }
  }

  void _pointer(PointerEvent event) {
    if (!_dragging) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final y = box.globalToLocal(event.position).dy;
    _step = y < 64
        ? -12
        : y > box.size.height - 64
            ? 12
            : 0;
    _timer ??= Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_controller.hasClients || _step == 0) return;
      final next = (_controller.offset + _step)
          .clamp(0.0, _controller.position.maxScrollExtent);
      if (next != _controller.offset) _controller.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
      onPointerMove: _pointer,
      onPointerUp: (_) => _drag(false),
      onPointerCancel: (_) => _drag(false),
      child: widget.builder(_controller, _drag));
}
