import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:carwash/features/auth/domain/entities/user_entity.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:carwash/features/branch/domain/entities/branch.dart';
import '../widgets/data_inspector_filter_sheet.dart';
// import '../widgets/organization_filter_sheet.dart'; // Removed
import '../providers/data_inspector_provider.dart';
import '../../../audit/domain/entities/audit_log.dart';

class DataInspectorScreen extends StatefulWidget {
  const DataInspectorScreen({super.key});

  @override
  State<DataInspectorScreen> createState() => _DataInspectorScreenState();
}

class _DataInspectorScreenState extends State<DataInspectorScreen>
    with TickerProviderStateMixin {
  int? _selectedIndex;

  // Organization Tab Controller
  late TabController _orgTabController;
  // Operations Tab Controller
  late TabController _opsTabController;

  // -- FILTER STATES --
  // Branch Filters
  // Note: provider.selectedBranchId handles Branch selection for global context,
  // but for "Organization > Users" filters, we might want to filter users by branch WITHOUT changing global context?
  // The user request implies "un filtro para sucursal, solo para eso".
  // However, the provider structure seems to be built around `selectedBranchId` influencing fetch.
  // I will continue to use provider.selectedBranchId for consistent "Branch Filter" across the app if possible,
  // OR use local filter if it's meant to be just for the view.
  // Let's use local state for flexibility in this view, as provider affects fetch.
  // Provider `selectedBranchId` is used to fetch specific data. If we filter locally, we just hide items.
  // I will use `provider.selectedBranchId` as the source of truth for "Selected Branch".

  bool? _filterBranchBillingEnabled;
  bool? _filterBranchIsActive;
  String? _filterSortOrder;

  // User Filters
  String? _filterUserRole;
  bool? _filterUserIsActive;

  // Operations - Vehicle Filters
  String _vehicleSearchQuery = '';
  String? _vehicleStatusFilter;

  // Metadata for Menu Items
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Organización',
      'icon': Icons.business_rounded,
      'color': Colors.blue,
      'index': 0,
    },
    {
      'title': 'Operaciones',
      'icon': Icons.local_car_wash_rounded,
      'color': Colors.orange,
      'index': 1,
    },
    {
      'title': 'Auditoría',
      'icon': Icons.history_edu_rounded,
      'color': Colors.purple,
      'index': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _orgTabController = TabController(length: 3, vsync: this);
    _opsTabController = TabController(length: 3, vsync: this);
    _orgTabController.addListener(() {
      setState(() {
        // Rebuild to update AppBar title/actions if needed based on internal tab
      });
    });

    // Initial Data Fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<DataInspectorProvider>().init(user.companyId);
      }
    });
  }

  @override
  void dispose() {
    _orgTabController.dispose();
    _opsTabController.dispose();
    super.dispose();
  }

  void _showFilters() {
    final provider = context.read<DataInspectorProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DataInspectorFilterSheet(
        tabIndex: _selectedIndex ?? 0,
        subTabIndex: _selectedIndex == 0 ? _orgTabController.index : 0,
        branches: provider.branches,

        // Pass current value
        currentBranchId: provider.selectedBranchId,

        // Pass specific filters
        currentBillingEnabled: _filterBranchBillingEnabled,
        currentIsActive: _filterBranchIsActive,
        currentSortOrder: _filterSortOrder,
        currentUserRole: _filterUserRole, // For Users Tab

        onApply: ({branchId, billingEnabled, isActive, role, sortOrder}) {
          setState(() {
            // Apply Global Branch Filter
            if (provider.selectedBranchId != branchId) {
              provider.setSelectedBranch(branchId);
            }

            // Apply specific filters based on context
            if (_orgTabController.index == 1) {
              _filterBranchBillingEnabled = billingEnabled;
              _filterBranchIsActive = isActive;
              _filterSortOrder = sortOrder;
            } else if (_orgTabController.index == 2) {
              // Users Context
              _filterUserRole = role;
              _filterUserIsActive = isActive;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataInspectorProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: _selectedIndex != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => setState(() => _selectedIndex = null),
              )
            : const BackButton(
                color: Colors.black87,
              ), // Standard back to close screen
        actions: [
          // Filter Button - Visible only in sub-sections (excluding Operations/Vehicles which has own filter)
          if (_selectedIndex != null && _selectedIndex != 1)
            IconButton(
              icon: Icon(
                Icons.filter_list_alt,
                color: _hasActiveFilters(provider)
                    ? Colors.blue
                    : Colors.black87,
              ),
              onPressed: _showFilters,
            ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(provider),
    );
  }

  bool _hasActiveFilters(DataInspectorProvider provider) {
    // Check if any filter is active
    if (provider.selectedBranchId != null) return true;
    if (_orgTabController.index == 1) {
      return _filterBranchBillingEnabled != null ||
          _filterBranchIsActive != null;
    }
    if (_orgTabController.index == 2) {
      return _filterUserRole != null || _filterUserIsActive != null;
    }
    return false;
  }

  String _getTitle() {
    if (_selectedIndex == null) return 'Centro de Datos';
    return _menuItems[_selectedIndex!]['title'];
  }

  Widget _buildBody(DataInspectorProvider provider) {
    if (_selectedIndex == null) {
      return _buildMenuGrid();
    }

    switch (_selectedIndex) {
      case 0:
        return _OrganizationTabContent(
          // Using static helper or extracting widget?
          // I will define _OrganizationTab class separately below but pass parameters
          provider: provider,
          tabController: _orgTabController,
          filterBranchBillingEnabled: _filterBranchBillingEnabled,
          filterBranchIsActive: _filterBranchIsActive,
          filterSortOrder: _filterSortOrder,
          filterUserRole: _filterUserRole,
          filterUserIsActive: _filterUserIsActive,
        );
      case 1:
        return _OperationsTab(
          provider: provider,
          tabController: _opsTabController,
          searchQuery: _vehicleSearchQuery,
          statusFilter: _vehicleStatusFilter,
          onFilterChanged: (query, status) {
            setState(() {
              _vehicleSearchQuery = query;
              _vehicleStatusFilter = status;
            });
          },
        );
      case 2:
        return _AuditTab(provider: provider);
      default:
        return const Center(child: Text('Opción no válida'));
    }
  }

  Widget _buildMenuGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: _menuItems.map((item) {
          return _InspectorMenuCard(
            title: item['title'],
            icon: item['icon'],
            color: item['color'],
            onTap: () => setState(() => _selectedIndex = item['index']),
          );
        }).toList(),
      ),
    );
  }
}

class _InspectorMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _InspectorMenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.8)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ), // Container
      ), // InkWell
    ); // Material
  }
}

// -----------------------------------------------------------------------------
// PLACEHOLDERS FOR TABS
// -----------------------------------------------------------------------------

class _OrganizationTabContent extends StatelessWidget {
  // Renamed from _OrganizationTab to avoid confusions with previous
  final DataInspectorProvider provider;
  final TabController tabController;

  final bool? filterBranchBillingEnabled;
  final bool? filterBranchIsActive;
  final String? filterSortOrder;

  final String? filterUserRole;
  final bool? filterUserIsActive;

  const _OrganizationTabContent({
    required this.provider,
    required this.tabController,
    this.filterBranchBillingEnabled,
    this.filterBranchIsActive,
    this.filterSortOrder,
    this.filterUserRole,
    this.filterUserIsActive,
  });

  @override
  Widget build(BuildContext context) {
    // Prepare Data
    final company = provider.company;
    final fiscalConfigs = provider.fiscalConfigs;

    // --- FILTER LOGIC ---

    // 1. BRANCHES
    List<Branch> displayedBranches = provider.branches;
    // Filter by Selected Branch (Provider)
    if (provider.selectedBranchId != null) {
      displayedBranches = displayedBranches
          .where((b) => b.id == provider.selectedBranchId)
          .toList();
    }
    // Filter by Billing Enabled / CAI
    displayedBranches = displayedBranches.where((b) {
      // Check Fiscal Config for this branch
      final config = fiscalConfigs.firstWhere(
        (f) => f['sucursal_id'] == b.id,
        orElse: () => <String, dynamic>{},
      );
      final hasBilling = config.isNotEmpty;

      if (filterBranchBillingEnabled != null) {
        if (filterBranchBillingEnabled == true && !hasBilling) return false;
        if (filterBranchBillingEnabled == false && hasBilling) return false;
      }

      // filterBranchIsActive -> No field in model, ignored for now or assume always active
      return true;
    }).toList();

    // Sort Branches
    if (filterSortOrder == 'asc') {
      displayedBranches.sort((a, b) => a.name.compareTo(b.name));
    } else if (filterSortOrder == 'desc') {
      displayedBranches.sort((a, b) => b.name.compareTo(a.name));
    }

    // 2. USERS
    List<UserEntity> displayedUsers = provider.users;
    // Filter by Role
    if (filterUserRole != null) {
      displayedUsers = displayedUsers
          .where((u) => u.role == filterUserRole)
          .toList();
    }
    // Filter by Status (Ignored for now as no field)
    // Filter by Branch (Provider selectedBranchId already filters usually, but let's ensure)
    if (provider.selectedBranchId != null) {
      displayedUsers = displayedUsers
          .where((u) => u.branchId == provider.selectedBranchId)
          .toList();
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Empresa', icon: Icon(Icons.business_outlined)),
              Tab(text: 'Sucursales', icon: Icon(Icons.store_outlined)),
              Tab(text: 'Usuarios', icon: Icon(Icons.people_outlined)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // 1. COMPANY TAB
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: company != null
                    ? _InfoCard(
                        title: 'Datos de Empresa',
                        icon: Icons.business,
                        color: Colors.blue,
                        children: [
                          _DetailRow('Nombre', company.name),
                          _DetailRow('RTN', company.rtn),
                          _DetailRow('Email', company.email),
                          _DetailRow(
                            'Registrado',
                            DateFormat('dd/MM/yyyy').format(company.createdAt),
                          ),
                        ],
                      )
                    : const Center(
                        child: Text('No hay información de empresa'),
                      ),
              ),

              // 2. BRANCHES TAB
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: displayedBranches.isEmpty
                    ? 1
                    : displayedBranches.length,
                itemBuilder: (context, index) {
                  if (displayedBranches.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron sucursales con el filtro actual.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final b = displayedBranches[index];
                  // Check for active CAI
                  final config = fiscalConfigs.firstWhere(
                    (f) => f['sucursal_id'] == b.id,
                    orElse: () => <String, dynamic>{},
                  );
                  final hasCai = config.isNotEmpty;
                  final cai = hasCai ? (config['cai'] as String?) : null;

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: const Icon(
                                  Icons.store,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.name,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Establecimiento: ${b.establishmentNumber}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          _StatusRow(
                            label: 'Facturación SAR',
                            isActive: hasCai,
                            activeText: 'Activa',
                            inactiveText: 'No Factura',
                          ),
                          if (hasCai && cai != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'CAI Actual:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              cai,
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 3. USERS TAB
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: displayedUsers.isEmpty ? 1 : displayedUsers.length,
                itemBuilder: (context, index) {
                  if (displayedUsers.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron usuarios con el filtro actual.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final u = displayedUsers[index];
                  // Find branch name
                  final branch = provider.branches.cast<Branch>().firstWhere(
                    (b) => b.id == u.branchId,
                    orElse: () => Branch(
                      id: '',
                      name: 'Sin Asignar',
                      establishmentNumber: '',
                      companyId: '',
                      address: '',
                      phone: '',
                    ),
                  );

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: u.role == 'admin'
                            ? Colors.purple.shade50
                            : Colors.grey.shade100,
                        child: Icon(
                          u.role == 'admin'
                              ? Icons.admin_panel_settings
                              : Icons.person,
                          color: u.role == 'admin'
                              ? Colors.purple
                              : Colors.grey,
                        ),
                      ),
                      title: Text(
                        u.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.email),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                u.role == 'admin'
                                    ? 'Administrador'
                                    : 'Empleado',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.store_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                branch.name,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool isActive;
  final String activeText;
  final String inactiveText;

  const _StatusRow({
    required this.label,
    required this.isActive,
    required this.activeText,
    required this.inactiveText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isActive ? Colors.green : Colors.grey),
          ),
          child: Text(
            isActive ? activeText : inactiveText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green[700] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _OperationsTab extends StatelessWidget {
  final DataInspectorProvider provider;
  final TabController tabController;
  final String searchQuery;
  final String? statusFilter;
  final Function(String, String?) onFilterChanged;

  const _OperationsTab({
    required this.provider,
    required this.tabController,
    required this.searchQuery,
    required this.statusFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final vehicles = provider.vehicles;
    final services = provider.washTypes;
    final products = provider.products;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter Vehicles Logic
    final filteredVehicles = vehicles.where((v) {
      final matchesSearch =
          searchQuery.isEmpty ||
          v.clientName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (v.plate?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesStatus = statusFilter == null || v.status == statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: tabController,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Vehículos', icon: Icon(Icons.directions_car)),
              Tab(text: 'Servicios', icon: Icon(Icons.local_car_wash)),
              Tab(text: 'Productos', icon: Icon(Icons.shopping_bag)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // 1. VEHICLES TAB
              Column(
                children: [
                  // Filters Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) =>
                              onFilterChanged(val, statusFilter),
                          decoration: InputDecoration(
                            hintText: 'Buscar por cliente o placa...',
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          controller: TextEditingController(text: searchQuery)
                            ..selection = TextSelection.fromPosition(
                              TextPosition(offset: searchQuery.length),
                            ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Filtrar por Estado',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          key: ValueKey(statusFilter),
                          initialValue: statusFilter,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: 'washing',
                              child: Text('Lavando'),
                            ),
                            DropdownMenuItem(
                              value: 'finished',
                              child: Text('Terminado'),
                            ),
                          ],
                          onChanged: (val) => onFilterChanged(searchQuery, val),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Tipo')),
                              DataColumn(label: Text('Cliente')),
                              DataColumn(label: Text('Ingreso')),
                              DataColumn(label: Text('Estado')),
                            ],
                            rows: filteredVehicles.take(100).map((v) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(v.vehicleType?.toUpperCase() ?? 'N/A'),
                                  ),
                                  DataCell(Text(v.clientName)),
                                  DataCell(
                                    Text(
                                      DateFormat(
                                        'dd/MM HH:mm',
                                      ).format(v.entryDate),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          v.status,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        v.status.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(v.status),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. SERVICES TAB
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                itemBuilder: (ctx, i) {
                  final s = services[i];
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: s.isActive
                            ? Colors.green[50]
                            : Colors.red[50],
                        child: Icon(
                          Icons.water_drop,
                          color: s.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        s.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${s.category} • ${s.description}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Precios:',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${s.prices.length} Tarifas',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 3. PRODUCTS TAB
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p.isActive
                            ? Colors.blue[50]
                            : Colors.red[50],
                        child: Icon(
                          Icons.inventory_2,
                          color: p.isActive ? Colors.blue : Colors.red,
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${p.category} • ${p.description}'),
                      trailing: Text(
                        'L. ${p.price.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'washing':
        return Colors.blue;
      case 'finished':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _AuditTab extends StatelessWidget {
  final DataInspectorProvider provider;

  const _AuditTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.selectedAuditUser != null) {
      return _buildUserLogsView(context);
    }
    return _buildUsersListView(context);
  }

  Widget _buildUsersListView(BuildContext context) {
    final users = provider.users.cast<UserEntity>();

    if (users.isEmpty) {
      return const Center(child: Text('No hay usuarios registrados.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blueGrey[700],
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              user.name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              user.role == 'admin' ? 'Administrador' : 'Empleado',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              provider.fetchAuditLogsForUser(user);
            },
          ),
        );
      },
    );
  }

  Widget _buildUserLogsView(BuildContext context) {
    final logs = provider.auditLogs;
    final selectedUser = provider.selectedAuditUser;

    return Column(
      children: [
        // Header with Back Button
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  provider.clearSelectedAuditUser();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial de:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      selectedUser?.name ?? 'Usuario',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Logs List
        Expanded(
          child: logs.isEmpty
              ? const Center(
                  child: Text(
                    'No hay registros para este usuario.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _AuditLogCard(
                      log: log,
                      user: selectedUser!,
                      provider: provider,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLog log;
  final UserEntity user;
  final DataInspectorProvider provider;

  const _AuditLogCard({
    required this.log,
    required this.user,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp);

    // Lookup Branch
    final branch = provider.branches.cast<Branch>().firstWhere(
      (b) => b.id == log.branchId,
      orElse: () => Branch(
        id: '',
        name: 'Global / Sin Sucursal',
        establishmentNumber: '',
        companyId: '',
        address: '',
        phone: '',
      ),
    );

    IconData iconData = Icons.info_outline;
    Color iconColor = Colors.grey;

    if (log.action.contains('CREATE')) {
      iconData = Icons.add_circle_outline;
      iconColor = Colors.green;
    } else if (log.action.contains('UPDATE')) {
      iconData = Icons.edit_outlined;
      iconColor = Colors.blue;
    } else if (log.action.contains('DELETE')) {
      iconData = Icons.delete_outline;
      iconColor = Colors.red;
    } else {
      iconData = Icons.history;
      iconColor = Colors.purple;
    }

    final actionDesc = _getActionDescription(log);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          actionDesc,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.store, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    branch.name,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        onTap: () => _showLogDetails(context, branch, actionDesc),
      ),
    );
  }

  String _getActionDescription(AuditLog log) {
    if (log.action == 'UPDATE_VEHICLE_STATUS') {
      final newStatus = log.details['newStatus'] ?? '?';
      return 'Cambio de Estado a "${newStatus.toUpperCase()}"';
    }
    if (log.action == 'CREATE_CLIENT') {
      final name = log.details['nombre_completo'] ?? 'Cliente';
      return 'Creó Cliente: $name';
    }
    if (log.action == 'CREATE_VEHICLE') {
      final client = log.details['client'] ?? 'Cliente';
      return 'Ingresó Vehículo de $client';
    }
    return log.action.replaceAll('_', ' ');
  }

  void _showLogDetails(BuildContext context, Branch branch, String actionDesc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Detalle de Auditoría',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailLine('Acción:', actionDesc),
              const Divider(),
              _DetailLine('Usuario:', user.name),
              _DetailLine(
                'Rol:',
                user.role == 'admin' ? 'Administrador' : 'Empleado',
              ),
              const Divider(),
              _DetailLine('Sucursal:', branch.name),
              if (branch.establishmentNumber.isNotEmpty)
                _DetailLine('Establecimiento:', branch.establishmentNumber),
              const Divider(),
              _DetailLine(
                'Fecha:',
                DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  const _DetailLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
