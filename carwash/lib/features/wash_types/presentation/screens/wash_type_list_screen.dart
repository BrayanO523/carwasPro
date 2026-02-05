import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/wash_type_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';

import '../../../products/presentation/providers/product_provider.dart';
import '../widgets/filter_bar.dart';
import '../widgets/filter_sheet.dart';

class WashTypeListScreen extends StatefulWidget {
  const WashTypeListScreen({super.key});

  @override
  State<WashTypeListScreen> createState() => _WashTypeListScreenState();
}

class _WashTypeListScreenState extends State<WashTypeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final companyId = authProvider.currentUser?.companyId ?? '';
      final branchId = authProvider.currentUser?.branchId;

      // Load both
      context.read<WashTypeProvider>().loadWashTypes(
        companyId,
        branchId: branchId,
      );
      context.read<ProductProvider>().loadProducts(
        companyId,
        branchId: branchId,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración de Precios',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'SERVICIOS', icon: Icon(Icons.local_car_wash)),
            Tab(text: 'PRODUCTOS', icon: Icon(Icons.shopping_bag)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/wash-types/add');
          } else {
            context.push('/products/add');
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Item'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_ServicesList(), _ProductsList()],
      ),
    );
  }
}

class _ServicesList extends StatefulWidget {
  @override
  State<_ServicesList> createState() => _ServicesListState();
}

class _ServicesListState extends State<_ServicesList> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool? _filterActive; // null = all, true = active, false = inactive
  DateTime? _dateStart;
  DateTime? _dateEnd;

  void _openFilters(List<String> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        currentStatus: _filterActive,
        currentDateStart: _dateStart,
        currentDateEnd: _dateEnd,
        currentCategory: _selectedCategory,
        categories: categories,
        onApply: (status, start, end, category) {
          setState(() {
            _filterActive = status;
            _dateStart = start;
            _dateEnd = end;
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WashTypeProvider>();
    final washTypes = provider.washTypes;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error cargando servicios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final authProvider = context.read<AuthProvider>();
                final companyId = authProvider.currentUser?.companyId ?? '';
                final branchId = authProvider.currentUser?.branchId;
                provider.loadWashTypes(
                  companyId,
                  branchId: branchId,
                  force: true,
                );
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // 1. Get Unique Categories
    final categories = washTypes
        .map((e) => e.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    // 2. Filter Data
    final filteredList = washTypes.where((item) {
      // Search
      final matchesSearch = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      // Category
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      // Active Status
      final matchesStatus =
          _filterActive == null || item.isActive == _filterActive;

      // Date Filter (Placeholder: WashTypes typically don't have created_at filter here,
      // but implementing logic as requested. If item has date, logic goes here.)
      // bool matchesDate = true;
      // if (_dateStart != null && _dateEnd != null) { ... }

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Filters Area
        FilterBar(
          searchQuery: _searchQuery,
          onSearchChanged: (val) => setState(() => _searchQuery = val),
          onOpenFilters: () => _openFilters(categories),
          filterActive: _filterActive,
          selectedCategory: _selectedCategory,
          dateStart: _dateStart,
          dateEnd: _dateEnd,
          hintText: 'Buscar servicio...',
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final authProvider = context.read<AuthProvider>();
              final companyId = authProvider.currentUser?.companyId ?? '';
              final branchId = authProvider.currentUser?.branchId;
              await provider.loadWashTypes(
                companyId,
                branchId: branchId,
                force: true,
              );
            },
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No hay servicios con estos filtros.'),
                        const SizedBox(height: 16),
                        if (filteredList.isEmpty &&
                            _searchQuery.isEmpty &&
                            _selectedCategory == null)
                          FilledButton.icon(
                            onPressed: () async {
                              final authProvider = context.read<AuthProvider>();
                              final user = authProvider.currentUser;
                              if (user != null) {
                                await provider.seedDefaultCatalog(
                                  user.companyId,
                                  user.branchId ?? '',
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_all),
                            label: const Text('Crear Servicios Básicos'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.category == 'base'
                                ? Colors.blue[50]
                                : Colors.purple[50],
                            child: Icon(
                              item.category == 'base'
                                  ? Icons.local_car_wash
                                  : Icons.star,
                              color: item.category == 'base'
                                  ? Colors.blue
                                  : Colors.purple,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  // Dynamic Price Chips
                                  ...item.prices.entries
                                      .where(
                                        (e) => e.value > 0,
                                      ) // Only show set prices
                                      .map((e) {
                                        return _PriceChip(
                                          label:
                                              e.key[0].toUpperCase() +
                                              e.key.substring(1), // Capitalize
                                          price: e.value,
                                        );
                                      }),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(
                            item.isActive ? Icons.check_circle : Icons.cancel,
                            color: item.isActive ? Colors.green : Colors.grey,
                          ),
                          onTap: () =>
                              context.push('/wash-types/edit', extra: item),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ProductsList extends StatefulWidget {
  @override
  State<_ProductsList> createState() => _ProductsListState();
}

class _ProductsListState extends State<_ProductsList> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool? _filterActive;
  DateTime? _dateStart;
  DateTime? _dateEnd;

  void _openFilters(List<String> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        currentStatus: _filterActive,
        currentDateStart: _dateStart,
        currentDateEnd: _dateEnd,
        currentCategory: _selectedCategory,
        categories: categories,
        onApply: (status, start, end, category) {
          setState(() {
            _filterActive = status;
            _dateStart = start;
            _dateEnd = end;
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.products;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. Get Unique Categories
    final categories = products
        .map((e) => e.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    // 2. Filter Data
    final filteredList = products.where((item) {
      // Search
      final matchesSearch = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      // Category
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      // Active Status
      final matchesStatus =
          _filterActive == null || item.isActive == _filterActive;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Filters Area
        FilterBar(
          searchQuery: _searchQuery,
          onSearchChanged: (val) => setState(() => _searchQuery = val),
          onOpenFilters: () => _openFilters(categories),
          filterActive: _filterActive,
          selectedCategory: _selectedCategory,
          dateStart: _dateStart,
          dateEnd: _dateEnd,
          hintText: 'Buscar producto...',
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final authProvider = context.read<AuthProvider>();
              final companyId = authProvider.currentUser?.companyId ?? '';
              await provider.loadProducts(companyId, force: true);
            },
            child: filteredList.isEmpty
                ? const Center(
                    child: Text('No hay productos con estos filtros.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange[50],
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Colors.orange,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.category} - L.${item.price.toStringAsFixed(2)}',
                          ),
                          trailing: Icon(
                            item.isActive ? Icons.check_circle : Icons.cancel,
                            color: item.isActive ? Colors.green : Colors.grey,
                          ),
                          onTap: () =>
                              context.push('/products/edit', extra: item),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final double? price;

  const _PriceChip({required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    if (price == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        '$label: L.${price!.toStringAsFixed(0)}',
        style: TextStyle(fontSize: 10, color: Colors.grey[800]),
      ),
    );
  }
}
