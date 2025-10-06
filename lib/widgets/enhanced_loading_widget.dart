import 'package:flutter/material.dart';

enum LoadingType {
  circular,
  linear,
  dots,
  skeleton,
}

class EnhancedLoadingWidget extends StatefulWidget {
  final LoadingType type;
  final String? message;
  final double? size;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const EnhancedLoadingWidget({
    super.key,
    this.type = LoadingType.circular,
    this.message,
    this.size,
    this.color,
    this.padding,
  });

  const EnhancedLoadingWidget.circular({
    super.key,
    this.message,
    this.size = 40,
    this.color,
    this.padding,
  }) : type = LoadingType.circular;

  const EnhancedLoadingWidget.linear({
    super.key,
    this.message,
    this.size,
    this.color,
    this.padding,
  }) : type = LoadingType.linear;

  const EnhancedLoadingWidget.dots({
    super.key,
    this.message,
    this.size = 8,
    this.color,
    this.padding,
  }) : type = LoadingType.dots;

  const EnhancedLoadingWidget.skeleton({
    super.key,
    this.message,
    this.size,
    this.color,
    this.padding,
  }) : type = LoadingType.skeleton;

  @override
  State<EnhancedLoadingWidget> createState() => _EnhancedLoadingWidgetState();
}

class _EnhancedLoadingWidgetState extends State<EnhancedLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    Widget loadingWidget = _buildLoadingWidget(color);

    if (widget.message != null) {
      loadingWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingWidget,
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Center(child: loadingWidget),
    );
  }

  Widget _buildLoadingWidget(Color color) {
    switch (widget.type) {
      case LoadingType.circular:
        return SizedBox(
          width: widget.size ?? 40,
          height: widget.size ?? 40,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: 3,
          ),
        );

      case LoadingType.linear:
        return SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
          ),
        );

      case LoadingType.dots:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.33;
                final animValue = (_animation.value - delay).clamp(0.0, 1.0);
                final scale = 0.5 + (0.5 * (1 - (animValue - 0.5).abs() * 2).clamp(0.0, 1.0));
                
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: widget.size! / 4),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size!,
                      height: widget.size!,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );

      case LoadingType.skeleton:
        return _buildSkeletonLoader();
    }
  }

  Widget _buildSkeletonLoader() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value,
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ),
          ),
          width: widget.size ?? 200,
          height: 20,
        );
      },
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;
  final LoadingType loadingType;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
    this.loadingType = LoadingType.circular,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: EnhancedLoadingWidget(
              type: loadingType,
              message: loadingMessage,
            ),
          ),
      ],
    );
  }
}

class SkeletonListTile extends StatefulWidget {
  final EdgeInsetsGeometry? padding;

  const SkeletonListTile({super.key, this.padding});

  @override
  State<SkeletonListTile> createState() => _SkeletonListTileState();
}

class _SkeletonListTileState extends State<SkeletonListTile>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            children: [
              _buildSkeletonContainer(50, 50, isCircle: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonContainer(double.infinity, 16),
                    const SizedBox(height: 8),
                    _buildSkeletonContainer(200, 14),
                    const SizedBox(height: 8),
                    _buildSkeletonContainer(150, 14),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeletonContainer(double width, double height, {bool isCircle = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: isCircle ? null : BorderRadius.circular(4),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [
            (_controller.value - 0.3).clamp(0.0, 1.0),
            _controller.value,
            (_controller.value + 0.3).clamp(0.0, 1.0),
          ],
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
        ),
      ),
    );
  }
}