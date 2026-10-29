import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Restored imperative matches can reach builders without running redirects.
class MissingRouteExtra extends StatefulWidget {
  const MissingRouteExtra({super.key, required this.location});
  final String location;

  @override
  State<MissingRouteExtra> createState() => _MissingRouteExtraState();
}

class _MissingRouteExtraState extends State<MissingRouteExtra> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(widget.location);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
