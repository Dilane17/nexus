import 'package:flutter/material.dart';
import '../app_shapes.dart';

/// Skeleton loader pour les listes et dashboards.
class NexusSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const NexusSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 8,
  });

  @override
  State<NexusSkeleton> createState() => _NexusSkeletonState();
}

class _NexusSkeletonState extends State<NexusSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E3E6).withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Squelette pour une carte entière (simule un contenu de carte)
class NexusCardSkeleton extends StatelessWidget {
  const NexusCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NexusShapes.radiusLg),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexusSkeleton(height: 20, width: 140),
          SizedBox(height: 12),
          NexusSkeleton(height: 32, width: 200),
          SizedBox(height: 12),
          NexusSkeleton(height: 14),
          SizedBox(height: 8),
          NexusSkeleton(height: 14, width: 180),
        ],
      ),
    );
  }
}
