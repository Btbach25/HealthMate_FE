import 'package:flutter/material.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/constants/app_size.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final bool enableHover;
  final VoidCallback? onTap;

  const AnimatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.enableHover = true,
    this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppSize.animationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: widget.enableHover
            ? (_) {
                setState(() => _isHovered = true);
                _controller.forward();
              }
            : null,
        onExit: widget.enableHover
            ? (_) {
                setState(() => _isHovered = false);
                _controller.reverse();
              }
            : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: widget.margin,
                padding: widget.padding ?? const EdgeInsets.all(AppSize.p20),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? AppSize.r16,
                  ),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 1,
                  ),
                  boxShadow: _isHovered
                      ? AppColors.cardShadowHover
                      : AppColors.cardShadowList,
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

