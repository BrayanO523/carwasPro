import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:carwash/features/auth/data/models/user_model.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:carwash/features/branch/data/models/branch_model.dart';
import '../widgets/organization_filter_sheet.dart';
import '../providers/data_inspector_provider.dart';

class DataInspectorScreen extends StatefulWidget {
  const DataInspectorScreen({super.key});

  @override
  State<DataInspectorScreen> createState() => _DataInspectorScreenState();
}

class _DataInspectorScreenState extends State<DataInspectorScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;

  // Organization Tab Controller
  late TabController _orgTabController;

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
  String? _filterBranchCai;
  bool? _filterBranchIsActive;

  // User Filters
  String? _filterUserRole;
  bool? _filterUserIsActive;

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
      'title': 'Finanzas',
      'icon': Icons.attach_money_rounded,
      'color': Colors.green,
      'index': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _orgTabController = TabController(length: 3, vsync: this);
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
    super.dispose();
  }

  void _showOrganizationFilters() {
    final provider = context.read<DataInspectorProvider>();
    // If we are in "Company" tab (index 0), maybe show nothing or generic.
    // If in "Branches" (index 1)
    // If in "Users" (index 2)

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow full height if needed
      builder: (ctx) => OrganizationFilterSheet(
        tabIndex: _orgTabController.index,

        // Pass current values
        currentBranchId: provider.selectedBranchId,
        currentBillingEnabled: _filterBranchBillingEnabled,
        currentCai: _filterBranchCai,
        currentIsActive: _filterBranchIsActive,
        currentUserRole: _filterUserRole,

        branches: provider.branches,
        fiscalConfigs: provider.fiscalConfigs,

        onApply: ({branchId, role, billingEnabled, cai, isActive}) {
          setState(() {
            // Apply based on active tab mostly, but some might be shared?
            // OrganizationFilterSheet callback sends all.
            provider.setSelectedBranch(branchId); // Sync with provider

            if (_orgTabController.index == 1) {
              // Branches Context
              _filterBranchBillingEnabled = billingEnabled;
              _filterBranchCai = cai;
              _filterBranchIsActive = isActive;
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
          if (_selectedIndex == 0 &&
              _orgTabController.index !=
                  0) // Show filter only for Organization (and not Company tab)
            IconButton(
              icon: Icon(
                Icons.filter_list_alt,
                color: _hasActiveFilters(provider)
                    ? Colors.blue
                    : Colors.black87,
              ),
              onPressed: _showOrganizationFilters,
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
          _filterBranchCai != null ||
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
          filterBranchCai: _filterBranchCai,
          filterBranchIsActive: _filterBranchIsActive,
          filterUserRole: _filterUserRole,
          filterUserIsActive: _filterUserIsActive,
        );
      case 1:
        return _OperationsTab(provider: provider);
      case 2:
        return _FinanceTab(provider: provider);
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
  final String? filterBranchCai;
  final bool? filterBranchIsActive;

  final String? filterUserRole;
  final bool? filterUserIsActive;

  const _OrganizationTabContent({
    required this.provider,
    required this.tabController,
    this.filterBranchBillingEnabled,
    this.filterBranchCai,
    this.filterBranchIsActive,
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
    List<BranchModel> displayedBranches = provider.branches;
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
      final cai = hasBilling ? config['cai'] : null;

      if (filterBranchBillingEnabled != null) {
        if (filterBranchBillingEnabled == true && !hasBilling) return false;
        if (filterBranchBillingEnabled == false && hasBilling) return false;
      }

      if (filterBranchCai != null) {
        if (cai != filterBranchCai) return false;
      }

      // filterBranchIsActive -> No field in model, ignored for now or assume always active
      return true;
    }).toList();

    // 2. USERS
    List<UserModel> displayedUsers = provider.users;
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
                  final branch = provider.branches.firstWhere(
                    (b) => b.id == u.branchId,
                    orElse: () => BranchModel(
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
  const _OperationsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final vehicles = provider.vehicles;
    final services = provider.washTypes;
    final products = provider.products;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicles Section
          _SectionHeader(
            title: 'Vehículos Registrados (${vehicles.length})',
            icon: Icons.directions_car,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Placa')),
                  DataColumn(label: Text('Marca/Modelo')),
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('Fecha Ingreso')),
                  DataColumn(label: Text('Estado')),
                ],
                rows: vehicles.take(50).map((v) {
                  // Limit view to 50 for performance
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          v.plate ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(v.brand ?? 'Unknown')),
                      DataCell(Text(v.clientName)),
                      DataCell(Text(v.entryDate.toString().split('.')[0])),
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

          const SizedBox(height: 24),

          // Services Section
          _SectionHeader(
            title: 'Catálogo de Servicios (${services.length})',
            icon: Icons.local_car_wash,
          ),
          const SizedBox(height: 8),
          ...services.map(
            (s) => Card(
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
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      '${s.prices.length} Tarifas',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Products Section
          _SectionHeader(
            title: 'Productos (${products.length})',
            icon: Icons.shopping_bag,
          ),
          const SizedBox(height: 8),
          ...products.map(
            (p) => Card(
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
            ),
          ),
        ],
      ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700], size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

class _FinanceTab extends StatelessWidget {
  final DataInspectorProvider provider;
  const _FinanceTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final invoices = provider.invoices;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (invoices.isEmpty) {
      return const Center(
        child: Text(
          'No hay facturas registradas (o faltan permisos de índice).',
        ),
      );
    }

    // Calculate Totals
    final totalBilled = invoices.fold(
      0.0,
      (acc, inv) => acc + (inv['total'] ?? 0),
    );
    final totalCount = invoices.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Facturación Total',
                  value: 'L. ${totalBilled.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KpiCard(
                  title: 'Facturas Emitidas',
                  value: '$totalCount',
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _SectionHeader(
            title: 'Historial de Facturación',
            icon: Icons.table_chart,
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Factura #')),
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('CAI')),
                  DataColumn(label: Text('Monto')),
                ],
                rows: invoices.take(100).map((inv) {
                  final date = (inv['fecha_creacion'] as Timestamp).toDate();
                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('dd/MM HH:mm').format(date))),
                      DataCell(
                        Text(
                          inv['numero_factura'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(inv['cliente_nombre'] ?? 'Consumidor Final'),
                      ),
                      DataCell(
                        Text(
                          (inv['cai'] as String?)?.substring(0, 8) ?? '...',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      DataCell(
                        Text(
                          'L. ${(inv['total'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Quick alias to avoid fixing imports everywhere
// final stdColors = Colors.cyan; // Just a dummy, using Colors directly
