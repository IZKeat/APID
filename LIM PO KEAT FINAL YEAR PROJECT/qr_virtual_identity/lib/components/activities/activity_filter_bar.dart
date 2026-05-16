import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivityFilterBar extends StatefulWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const ActivityFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<ActivityFilterBar> createState() => _ActivityFilterBarState();
}

class _ActivityFilterBarState extends State<ActivityFilterBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<FilterOption> _filters = [
    FilterOption(
      key: 'all',
      label: 'All',
      icon: Icons.all_inclusive,
      color: const Color(0xFF6A1B9A), // Stronger purple
    ),
    FilterOption(
      key: 'library',
      label: 'Library',
      icon: Icons.library_books,
      color: const Color(0xFF1565C0), // Stronger blue
    ),
    FilterOption(
      key: 'commerce',
      label: 'Shopping',
      icon: Icons.shopping_cart,
      color: const Color(0xFF2E7D32), // Stronger green
    ),
    FilterOption(
      key: 'access',
      label: 'Access',
      icon: Icons.door_front_door,
      color: const Color(0xFFE65100), // Stronger orange
    ),
    FilterOption(
      key: 'booking',
      label: 'Booking',
      icon: Icons.event_note,
      color: const Color(0xFF7B1FA2), // Stronger purple variant
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = widget.selectedFilter == filter.key;

              return Container(
                margin: EdgeInsets.only(
                  right: index < _filters.length - 1 ? 12 : 0,
                ),
                child: Transform.scale(
                  scale: _animation.value,
                  child: _buildFilterChip(filter, isSelected),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(FilterOption filter, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onFilterChanged(filter.key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF6A1B9A), // Stronger purple
                    const Color(0xFF8E24AA), // Stronger purple variant
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(
                    0xFF6A1B9A,
                  ).withOpacity(0.6), // Higher opacity for better visibility
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(
                      0xFF6A1B9A,
                    ).withOpacity(0.4), // Stronger shadow
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : const Color(
                      0xFF6A1B9A,
                    ).withOpacity(0.8), // Higher opacity for better visibility
            ),
            const SizedBox(width: 8),
            Text(
              filter.label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF6A1B9A).withOpacity(
                        0.9,
                      ), // Higher opacity for better visibility
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const FilterOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}
