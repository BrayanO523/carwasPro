import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carwash/features/branch/data/models/branch_model.dart';
// import '../../../branch/domain/entities/branch.dart'; // Using BranchModel directly to avoid cast issues if provider uses models

class OrganizationFilterSheet extends StatefulWidget {
  final int tabIndex; // 0: Company, 1: Branches, 2: Users

  // Branch Filter Params
  final String? currentBranchId;
  final bool? currentBillingEnabled; // For "Factura o No Factura"
  final String? currentCai; // For CAI
  final bool? currentIsActive; // For "Activa / Desactivada" (Branch Status)

  // User Filter Params
  final String? currentUserRole;
  // final String? userBranchId; // reusing currentBranchId for user filtering too

  final List<BranchModel> branches;
  final List<Map<String, dynamic>> fiscalConfigs; // To populate CAI list

  final Function({
    String? branchId,
    String? role,
    bool? billingEnabled,
    String? cai,
    bool? isActive,
  })
  onApply;

  const OrganizationFilterSheet({
    super.key,
    required this.tabIndex,
    this.currentBranchId,
    this.currentBillingEnabled,
    this.currentCai,
    this.currentIsActive,
    this.currentUserRole,
    required this.branches,
    required this.fiscalConfigs,
    required this.onApply,
  });

  @override
  State<OrganizationFilterSheet> createState() =>
      _OrganizationFilterSheetState();
}

class _OrganizationFilterSheetState extends State<OrganizationFilterSheet> {
  late String? _branchId;
  late String? _role;
  late bool? _billingEnabled;
  late String? _cai;
  late bool? _isActive;

  @override
  void initState() {
    super.initState();
    _branchId = widget.currentBranchId;
    _role = widget.currentUserRole;
    _billingEnabled = widget.currentBillingEnabled;
    _cai = widget.currentCai;
    _isActive = widget.currentIsActive;
  }

  void _reset() {
    setState(() {
      _branchId = null;
      _role = null;
      _billingEnabled = null;
      _cai = null;
      _isActive = null;
    });
  }

  void _apply() {
    widget.onApply(
      branchId: _branchId,
      role: _role,
      billingEnabled: _billingEnabled,
      cai: _cai,
      isActive: _isActive,
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
              Expanded(
                // Fix overflow
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_alt, color: Color(0xFF1E88E5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getTitle(),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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

          // DYNAMIC BODY BASED ON TAB INDEX
          if (widget.tabIndex == 1) ..._buildBranchFilters(),
          if (widget.tabIndex == 2) ..._buildUserFilters(),
          if (widget.tabIndex == 0)
            const Center(
              child: Text('No hay filtros disponibles para Empresa'),
            ),

          const SizedBox(height: 32),

          // Apply Button
          if (widget.tabIndex != 0)
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

  String _getTitle() {
    switch (widget.tabIndex) {
      case 1:
        return 'Filtros de Sucursales';
      case 2:
        return 'Filtros de Usuarios';
      default:
        return 'Filtros';
    }
  }

  // ---------------------------------------------------------------------------
  // BRANCH FILTERS
  // ---------------------------------------------------------------------------
  List<Widget> _buildBranchFilters() {
    // Collect available CAIs from fiscalConfigs
    // Filter CAIs by selected branch if any
    final caiList = widget.fiscalConfigs
        .where((f) => _branchId == null || f['sucursal_id'] == _branchId)
        .map((f) => f['cai'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    return [
      _buildSectionTitle('SUCURSAL'),
      const SizedBox(height: 12),
      _buildDropdown<String>(
        value: _branchId,
        hint: 'Todas las Sucursales',
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Todas las Sucursales'),
          ),
          ...widget.branches.map(
            (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
          ),
        ],
        onChanged: (val) {
          setState(() {
            _branchId = val;
            // Clear CAI if not valid for new branch?
            // Logic handled by reusing caiList which will update on rebuild
            // But selected _cai might need reset if it's not in the new list?
            // For simplicity, let's keep it unless user changes it, or reset if strict.
            // _cai = null;
          });
        },
      ),
      const SizedBox(height: 24),

      _buildSectionTitle('FACTURACIÓN'),
      const SizedBox(height: 12),
      _buildDropdown<bool>(
        value: _billingEnabled,
        hint: 'Todas',
        items: const [
          DropdownMenuItem(value: null, child: Text('Todas')),
          DropdownMenuItem(value: true, child: Text('Con Facturación (SAR)')),
          DropdownMenuItem(value: false, child: Text('Sin Facturación')),
        ],
        onChanged: (val) => setState(() => _billingEnabled = val),
      ),
      const SizedBox(height: 24),

      _buildSectionTitle('CAI / SERIE'),
      const SizedBox(height: 12),
      _buildDropdown<String>(
        value: _cai,
        hint: 'Todos los CAI',
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos los CAI')),
          ...caiList.map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (val) => setState(() => _cai = val),
      ),
      const SizedBox(height: 24),

      _buildSectionTitle('ESTADO'),
      const SizedBox(height: 12),
      _buildDropdown<bool>(
        value: _isActive,
        hint: 'Todas',
        items: const [
          DropdownMenuItem(value: null, child: Text('Todas')),
          DropdownMenuItem(value: true, child: Text('Activas')),
          DropdownMenuItem(value: false, child: Text('Inactivas')),
        ],
        onChanged: (val) => setState(() => _isActive = val),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // USER FILTERS
  // ---------------------------------------------------------------------------
  List<Widget> _buildUserFilters() {
    return [
      _buildSectionTitle('SUCURSAL'),
      const SizedBox(height: 12),
      _buildDropdown<String>(
        value: _branchId,
        hint: 'Todas las Sucursales',
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Todas las Sucursales'),
          ),
          ...widget.branches.map(
            (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
          ),
        ],
        onChanged: (val) => setState(() => _branchId = val),
      ),
      const SizedBox(height: 24),

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
    ];
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
