class AppPermissions {
  // Vehicles (Entradas)
  // "Ingreso de Vehículo" - Access to the screen implies ability to create.
  static const String createVehicle = 'create_vehicle';

  // Active Vehicles Check
  static const String viewVehicles = 'view_vehicles'; // Just see the list
  static const String changeVehicleStatus =
      'change_vehicle_status'; // Terminar y Avisar
  static const String editVehicle = 'edit_vehicle'; // Modify details
  static const String deleteVehicle = 'delete_vehicle'; // Delete ticket

  // Billing (Caja)
  static const String viewBilling = 'view_billing'; // See list of ready to bill
  static const String emitInvoice = 'emit_invoice'; // Actually process billing

  // Clients
  static const String viewClients = 'view_clients';
  static const String createClient = 'create_client';
  static const String editClient = 'edit_client';
  static const String manageClientCredit = 'manage_client_credit';

  // Inventory (Products & Services)
  static const String viewInventory = 'view_inventory';
  static const String createInventory = 'create_inventory';
  static const String editInventory = 'edit_inventory';

  // Branches (Sucursales)
  static const String viewBranches = 'view_branches';
  static const String manageBranches = 'manage_branches'; // Create/Edit/Delete

  // Reports
  static const String viewReports = 'view_reports';
  static const String exportReports = 'export_reports';

  // Admin / Management
  // Users
  static const String viewUsers = 'view_users';
  static const String createUser = 'create_users';
  static const String editUser = 'edit_users';
  static const String deleteUser = 'delete_users';

  // Company Settings
  static const String viewSettings = 'view_settings';
  static const String editSettings = 'edit_settings';

  // Groups for UI Selection
  static const Map<String, List<String>> groups = {
    'Vehículos (Ingreso)': [createVehicle],
    'Vehículos (Activos)': [
      viewVehicles,
      changeVehicleStatus,
      editVehicle,
      deleteVehicle,
    ],
    'Caja y Facturación': [viewBilling, emitInvoice],
    'Clientes': [viewClients, createClient, editClient, manageClientCredit],
    'Sucursales': [viewBranches, manageBranches],
    'Inventario (Precios y Servicios)': [
      viewInventory,
      createInventory,
      editInventory,
    ],
    'Gestión de Usuarios': [viewUsers, createUser, editUser, deleteUser],
    'Configuración de Empresa': [viewSettings, editSettings],
    'Reportes': [viewReports, exportReports],
    // 'Administración': [manageUsers, manageSettings], // Removed
  };

  static const Map<String, String> labels = {
    createVehicle: 'Ingresar Vehículos (Pantalla de Entrada)',
    viewVehicles: 'Ver Vehículos Activos',
    changeVehicleStatus: 'Terminar y Avisar (Cambiar Estado)',
    editVehicle: 'Editar Ficha (Placa, Modelo, etc.)',
    deleteVehicle: 'Eliminar Ticket',
    viewBilling: 'Ver Lista para Facturar',
    emitInvoice: 'Emitir Factura/Cobrar',

    viewClients: 'Ver Directorio de Clientes',
    createClient: 'Registrar Nuevo Cliente',
    editClient: 'Editar Datos de Cliente',
    manageClientCredit: 'Gestionar Crédito (Límite/Plazo)',
    viewInventory: 'Ver Lista de Precios/Productos',
    createInventory: 'Crear Nuevo Producto/Servicio',
    editInventory: 'Editar Precio/Detalles',

    viewBranches: 'Ver Lista de Sucursales',
    manageBranches: 'Crear/Editar Sucursales',

    viewReports: 'Ver Reportes y Balance',
    exportReports: 'Exportar Datos',

    viewUsers: 'Ver Lista de Usuarios',
    createUser: 'Crear Nuevos Usuarios',
    editUser: 'Editar Perfiles de Usuario',
    deleteUser: 'Eliminar/Desactivar Usuarios',

    viewSettings: 'Ver Configuración de Empresa',
    editSettings: 'Modificar Configuración (CAI, Datos)',
  };
}
