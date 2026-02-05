import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../branch/domain/entities/branch.dart';

class DataInspectorFilterSheet extends StatefulWidget {
  final int tabIndex; // 0: Org, 1: Ops, 2: Audit
  final int subTabIndex; // For Org: 0=Company, 1=Branches, 2=Users

  // Global Params
  final String? currentBranchId;

  // Ops/Billing Params
  final bool? currentBillingEnabled;
  final bool? currentIsActive;

  // Sorting
  final String? currentSortOrder; // 'asc', 'desc'

  // User Params
  final String? currentUserRole;

  final List<Branch> branches;

  final Function({
    String? branchId,
    String? role,
    bool? billingEnabled,
    bool? isActive,
    String? sortOrder,
  })
  onApply;

  const DataInspectorFilterSheet({
    super.key,
    required this.tabIndex,
    this.subTabIndex = 0,
    this.currentBranchId,
    this.currentBillingEnabled,
    this.currentIsActive,
    this.currentSortOrder,
    this.currentUserRole,
    required this.branches,
    required this.onApply,
  });

  @override
  State<DataInspectorFilterSheet> createState() =>
      _DataInspectorFilterSheetState();
}

class _DataInspectorFilterSheetState extends State<DataInspectorFilterSheet> {
  late String? _branchId;
  late String? _role;
  late bool? _billingEnabled;
  late bool? _isActive;
  late String? _sortOrder;

  @override
  void initState() {
    super.initState();
    _branchId = widget.currentBranchId;
    _role = widget.currentUserRole;
    _billingEnabled = widget.currentBillingEnabled;
    _isActive = widget.currentIsActive;
    _sortOrder = widget.currentSortOrder;
  }

  void _reset() {
    setState(() {
      _branchId = null;
      _role = null;
      _billingEnabled = null;
      _isActive = null;
      _sortOrder = null;
    });
  }

  void _apply() {
    widget.onApply(
      branchId: _branchId,
      role: _role,
      billingEnabled: _billingEnabled,
      isActive: _isActive,
      sortOrder: _sortOrder,
    );
    Navigator.pop(context);
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
                  const Icon(Icons.filter_list_alt, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 12),
                  Text(
                    'Filtros',
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

          // -------------------------------------------------------------------
          // 1. SUCURSAL FILTER (Context Aware)
          // -------------------------------------------------------------------
          // Temporarily disabled in all views per user request
          // -------------------------------------------------------------------
          // 1. SUCURSAL FILTER (Context Aware)
          // -------------------------------------------------------------------
          // Temporarily disabled in all views per user request
          // Removed dead code here

          // -------------------------------------------------------------------
          // 2. ORG > BRANCHES SPECIFIC (Billing, Sort)
          // -------------------------------------------------------------------
          if (widget.tabIndex == 0 && widget.subTabIndex == 1) ...[
            _buildSectionTitle('FACTURACIÓN'),
            const SizedBox(height: 12),
            _buildDropdown<bool>(
              value: _billingEnabled,
              hint: 'Todas',
              items: const [
                DropdownMenuItem(value: null, child: Text('Todas')),
                DropdownMenuItem(
                  value: true,
                  child: Text('Con Facturación (SAR)'),
                ),
                DropdownMenuItem(value: false, child: Text('Sin Facturación')),
              ],
              onChanged: (val) => setState(() => _billingEnabled = val),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('ORDENAMIENTO'),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: _sortOrder,
              hint: 'Por Defecto',
              items: const [
                DropdownMenuItem(value: null, child: Text('Por Defecto')),
                DropdownMenuItem(value: 'asc', child: Text('Alfabético (A-Z)')),
                DropdownMenuItem(
                  value: 'desc',
                  child: Text('Alfabético (Z-A)'),
                ),
              ],
              onChanged: (val) => setState(() => _sortOrder = val),
            ),
            const SizedBox(height: 24),
          ],

          // -------------------------------------------------------------------
          // 3. USERS SPECIFIC (Role)
          // -------------------------------------------------------------------
          if (widget.tabIndex == 0 && widget.subTabIndex == 2) ...[
            _buildSectionTitle('ROL DE USUARIO'),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: _role,
              hint: 'Todos los Roles',
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos los Roles')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                DropdownMenuItem(value: 'user', child: Text('Empleado')),
              ],
              onChanged: (val) => setState(() => _role = val),
            ),
            const SizedBox(height: 24),
          ],

          // -------------------------------------------------------------------
          // 4. COMMON STATUS (Active)
          // -------------------------------------------------------------------
          // Show for Branches, Users
          if ((widget.tabIndex == 0 &&
                  (widget.subTabIndex == 1 || widget.subTabIndex == 2)) ||
              widget.tabIndex == 1) ...[
            _buildSectionTitle('ESTADO'),
            const SizedBox(height: 12),
            _buildDropdown<bool>(
              value: _isActive,
              hint: 'Todos',
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: true, child: Text('Activos')),
                DropdownMenuItem(value: false, child: Text('Inactivos')),
              ],
              onChanged: (val) => setState(() => _isActive = val),
            ),
            const SizedBox(height: 24),
          ],

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

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: GoogleFonts.outfit(color: Colors.black54)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items,
          onChanged: onChanged,
        ),
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
}
