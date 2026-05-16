import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyState extends StatefulWidget {
  final String? message;
  final String? submessage;
  final IconData? fallbackIcon;
  final String? animationAsset;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyState({
    super.key,
    this.message,
    this.submessage,
    this.fallbackIcon,
    this.animationAsset,
    this.onAction,
    this.actionText,
  });

  const EmptyState.noActivities({Key? key, VoidCallback? onRefresh})
    : this(
        key: key,
        message: 'No activity records today',
        submessage: 'Scan any QR code to start your campus journey!',
        fallbackIcon: Icons.timeline,
        animationAsset: 'assets/animations/empty_activities.json',
        onAction: onRefresh,
        actionText: 'Refresh',
      );

  const EmptyState.noData({
    Key? key,
    String? customMessage,
    VoidCallback? onRetry,
  }) : this(
         key: key,
         message: customMessage ?? 'No data available',
         submessage: 'Please try again later or check your connection',
         fallbackIcon: Icons.cloud_off,
         onAction: onRetry,
         actionText: 'Retry',
       );

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation or Icon
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildMainVisual(),
                  ),

                  const SizedBox(height: 32),

                  // Main message
                  Text(
                    widget.message ?? 'No data available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Submessage
                  if (widget.submessage != null)
                    Text(
                      widget.submessage!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 32),

                  // Action button
                  if (widget.onAction != null && widget.actionText != null)
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: ElevatedButton.icon(
                        onPressed: widget.onAction,
                        icon: const Icon(Icons.refresh),
                        label: Text(widget.actionText!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF6A1B9A,
                          ), // Stronger purple
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainVisual() {
    // Try to load Lottie animation first
    if (widget.animationAsset != null) {
      return SizedBox(
        width: 200,
        height: 200,
        child: FutureBuilder<bool>(
          future: _checkAssetExists(widget.animationAsset!),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Lottie.asset(
                widget.animationAsset!,
                width: 200,
                height: 200,
                repeat: true,
                animate: true,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackIcon();
                },
              );
            } else {
              return _buildFallbackIcon();
            }
          },
        ),
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(
          0xFF6A1B9A,
        ).withOpacity(0.12), // Stronger purple with better contrast
        borderRadius: BorderRadius.circular(60),
      ),
      child: Icon(
        widget.fallbackIcon ?? Icons.inbox,
        size: 64,
        color: const Color(0xFF6A1B9A).withOpacity(0.8), // Stronger purple
      ),
    );
  }

  Future<bool> _checkAssetExists(String assetPath) async {
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Specialized empty state for activities
class ActivitiesEmptyState extends StatelessWidget {
  final String selectedFilter;
  final VoidCallback? onRefresh;

  const ActivitiesEmptyState({
    super.key,
    required this.selectedFilter,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final message = _getMessageForFilter();

    return EmptyState(
      message: message['title'],
      submessage: message['subtitle'],
      fallbackIcon: message['icon'],
      animationAsset: 'assets/animations/empty_activities.json',
      onAction: onRefresh,
      actionText: 'Refresh',
    );
  }

  Map<String, dynamic> _getMessageForFilter() {
    switch (selectedFilter) {
      case 'library':
        return {
          'title': 'No library activities yet',
          'subtitle': 'Visit the library to borrow or return books!',
          'icon': Icons.library_books,
        };
      case 'commerce':
        return {
          'title': 'No shopping records yet',
          'subtitle': 'Purchase items at campus stores to see records here',
          'icon': Icons.shopping_cart,
        };
      case 'access':
        return {
          'title': 'No access records yet',
          'subtitle': 'Use QR code to enter/exit campus or classrooms',
          'icon': Icons.door_front_door,
        };
      case 'booking':
        return {
          'title': 'No booking records yet',
          'subtitle': 'Book labs or meeting rooms to see records here',
          'icon': Icons.event_note,
        };
      default:
        return {
          'title': 'No activity records today',
          'subtitle': 'Scan any QR code to start your campus journey!',
          'icon': Icons.timeline,
        };
    }
  }
}

// Loading state widget
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(0xFF6A1B9A),
            ), // Stronger purple
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'Loading...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
