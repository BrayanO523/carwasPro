import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FilterSheet extends StatefulWidget {
  final bool? currentStatus; // null=all, true=active, false=inactive
  final DateTime? currentDateStart;
  final DateTime? currentDateEnd;
  final String? currentCategory;
  final List<String> categories;
  final Function(bool? status, DateTime? start, DateTime? end, String? category)
  onApply;

  const FilterSheet({
    super.key,
    required this.currentStatus,
    required this.currentDateStart,
    required this.currentDateEnd,
    required this.currentCategory,
    required this.categories,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late bool? _status;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String? _category;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _startDate = widget.currentDateStart;
    _endDate = widget.currentDateEnd;
    _category = widget.currentCategory;
  }

  void _reset() {
    setState(() {
      _status = null;
      _startDate = null;
      _endDate = null;
      _category = null;
    });
  }

  void _apply() {
    widget.onApply(_status, _startDate, _endDate, _category);
    Navigator.pop(context);
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 12),
                  Text(
                    'Configurar Vista',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _reset,
                child: Text(
                  'Restablecer',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E88E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // STATUS
          _buildSectionTitle('ESTADO'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildStatusOption('Todas', null),
                _buildStatusOption('Activas', true),
                _buildStatusOption('Inactivas', false),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // DATE RANGE
          _buildSectionTitle('RANGO DE FECHAS'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'Desde',
                  _startDate,
                  () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  'Hasta',
                  _endDate,
                  () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // CATEGORY
          _buildSectionTitle('CATEGORÍA'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip('Todas', null),
              ...widget.categories.map((c) => _buildCategoryChip(c, c)),
            ],
          ),

          const SizedBox(height: 32),
          // Apply Button
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Aplicar Filtros',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildStatusOption(String label, bool? value) {
    final isSelected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: isSelected
                ? Border.all(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
                  )
                : null,
          ),
          child: Column(
            children: [
              Icon(
                value == null
                    ? Icons.list
                    : (value
                          ? Icons.check_circle_outline
                          : Icons.remove_circle_outline),
                size: 18,
                color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1E88E5)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? DateFormat('dd/MM/yyyy').format(date)
                  : 'Seleccionar',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _category == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _category = value),
      selectedColor: const Color(0xFFE3F2FD),
      backgroundColor: const Color(0xFFF5F5F5),
      labelStyle: GoogleFonts.outfit(
        color: isSelected ? const Color(0xFF1E88E5) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: isSelected
          ? const BorderSide(color: Color(0xFF1E88E5))
          : const BorderSide(color: Colors.transparent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
