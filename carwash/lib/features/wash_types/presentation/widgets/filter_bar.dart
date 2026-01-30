import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final String hintText;

  // Active Filter States (Used for badge indicator)
  final bool? filterActive;
  final String? selectedCategory;
  final DateTime? dateStart;
  final DateTime? dateEnd;

  const FilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.filterActive,
    required this.selectedCategory,
    this.dateStart,
    this.dateEnd,
    this.hintText = 'Buscar...',
  });

  @override
  Widget build(BuildContext context) {
    // Check if any filter is active
    final hasActiveFilters =
        filterActive != null ||
        selectedCategory != null ||
        (dateStart != null && dateEnd != null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Bar (Expanded)
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50], // Very light grey
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E88E5),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                style: GoogleFonts.outfit(fontSize: 15),
                onChanged: onSearchChanged,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Filter Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton.filled(
                  onPressed: onOpenFilters,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5), // App Blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.tune, color: Colors.white, size: 24),
                ),
              ),
              // Notification Badge if filters are active
              if (hasActiveFilters)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
