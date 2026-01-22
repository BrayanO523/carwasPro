import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart'; // Restored
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/vehicle_entry_repository.dart';
import '../../../wash_types/domain/repositories/wash_type_repository.dart'; // Correct relative path from features/entry/presentation/providers/
import '../../domain/entities/vehicle.dart';
import '../../data/models/client_model.dart';
import '../../data/models/vehicle_model.dart';

class VehicleEntryProvider extends ChangeNotifier {
  final VehicleEntryRepository _repository;
  final WashTypeRepository _washTypeRepository;

  // Form Controllers
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final modelController = TextEditingController();

  // State
  List<File> _selectedImages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _washTypes = [];
  String _selectedVehicleType = 'turismo'; // Default
  String? _selectedBaseServiceId;
  final Set<String> _selectedExtrasIds = {};

  final List<String> vehicleTypes = ['moto', 'turismo', 'camioneta', 'grande'];

  VehicleEntryProvider({
    required VehicleEntryRepository repository,
    required WashTypeRepository washTypeRepository,
  }) : _repository = repository,
       _washTypeRepository = washTypeRepository;
  // _loadWashTypes(); // Now called explicitly from UI

  List<File> get selectedImages => _selectedImages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get washTypes => _washTypes;
  String get selectedVehicleType => _selectedVehicleType;
  String? get selectedBaseServiceId => _selectedBaseServiceId;
  Set<String> get selectedExtrasIds => _selectedExtrasIds;

  StreamSubscription? _washTypeSubscription;

  // Subscribe to wash types for Real-time updates
  void subscribeToWashTypes(String companyId, String branchId) {
    // Cancel previous subscription if any
    _washTypeSubscription?.cancel();

    _washTypeSubscription = _washTypeRepository
        .getWashTypesStream(companyId: companyId)
        .listen(
          (allTypes) {
            // 2. Filter by Active and Branch Availability
            final filtered = allTypes.where((type) {
              if (!type.isActive) return false;

              // Branch Check: Empty = All. Or must contain current branchId.
              if (type.branchIds.isEmpty) return true;
              return type.branchIds.contains(branchId);
            }).toList();

            // 3. Convert to Map for current UI compatibility
            _washTypes = filtered.map((e) {
              return {
                'id': e.id,
                'nombre': e.name,
                'descripcion': e.description,
                'categoria': e.category,
                'activo': e.isActive,
                'precios': e.prices,
                'empresa_id': e.companyId,
                'sucursal_ids': e.branchIds,
              };
            }).toList();

            // Select first base service by default if available and nothing selected
            final baseServices = _washTypes
                .where((w) => w['categoria'] == 'base')
                .toList();

            // Ensure current selection is still valid, else reset
            if (_selectedBaseServiceId == null ||
                !baseServices.any((x) => x['id'] == _selectedBaseServiceId)) {
              if (baseServices.isNotEmpty) {
                _selectedBaseServiceId = baseServices.first['id'];
              } else {
                _selectedBaseServiceId = null;
              }
            }

            notifyListeners();
          },
          onError: (e) {
            print('Error loading wash types stream: $e');
            _errorMessage = 'Error de conexión con servicios: $e';
            notifyListeners();
          },
        );
  }

  void setVehicleType(String type) {
    _selectedVehicleType = type;
    notifyListeners();
  }

  void setBaseService(String id) {
    _selectedBaseServiceId = id;
    notifyListeners();
  }

  void toggleExtra(String id) {
    if (_selectedExtrasIds.contains(id)) {
      _selectedExtrasIds.remove(id);
    } else {
      _selectedExtrasIds.add(id);
    }
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    ); // Or camera
    if (pickedFile != null) {
      _selectedImages.add(File(pickedFile.path));
      notifyListeners();
    }
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }

  Future<bool> submitEntry(String companyId, {String? branchId}) async {
    if (nameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        modelController.text.isEmpty ||
        _selectedImages.isEmpty ||
        _selectedBaseServiceId == null) {
      _errorMessage =
          'Por favor complete todos los campos, seleccione un lavado y añada al menos una foto';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check for existing client
      String clientId;
      ClientModel client;

      final existingClient = await _repository.getClientByPhone(
        phoneController.text.trim(),
        companyId,
      );

      if (existingClient != null) {
        clientId = existingClient.id;
        client = ClientModel(
          id: clientId,
          name: nameController.text.trim(),
          lastName: lastNameController.text.trim(),
          phone: phoneController.text.trim(),
          companyId: companyId,
        );
      } else {
        clientId = const Uuid().v4();
        client = ClientModel(
          id: clientId,
          name: nameController.text.trim(),
          lastName: lastNameController.text.trim(),
          phone: phoneController.text.trim(),
          companyId: companyId,
        );
      }

      // 2. Save/Update Client
      await _repository.saveClient(client);

      final vehicleId = const Uuid().v4();
      final effectiveBranchId = branchId ?? 'main';

      // 3. Upload Images
      List<String> photoUrls = [];
      for (var image in _selectedImages) {
        final url = await _repository.uploadVehicleImage(
          imageFile: image,
          companyId: companyId,
          branchId: effectiveBranchId,
          clientId: clientId,
          vehicleId: vehicleId,
        );
        photoUrls.add(url);
      }

      // Collect Services
      List<String> selectedServices = [];
      if (_selectedBaseServiceId != null)
        selectedServices.add(_selectedBaseServiceId!);
      selectedServices.addAll(_selectedExtrasIds);

      // 4. Save Vehicle
      final vehicle = VehicleModel(
        id: vehicleId,
        model: modelController.text.trim(),
        clientId: clientId,
        companyId: companyId,
        entryDate: DateTime.now(),
        photoUrls: photoUrls,
        status: Vehicle.statusWashing, // Use constant
        branchId: effectiveBranchId,
        clientName: '${client.name} ${client.lastName}', // Use client object
        vehicleType: _selectedVehicleType,
        services: selectedServices,
      );
      await _repository.saveVehicle(vehicle);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearForm() {
    nameController.clear();
    lastNameController.clear();
    phoneController.clear();
    modelController.clear();
    _selectedImages.clear();
    _selectedBaseServiceId = null;
    _selectedExtrasIds.clear();
    _selectedVehicleType = 'turismo';
    _errorMessage = null;
    notifyListeners();
  }

  // Price Calculations
  double get subtotal {
    double total = 0;

    // Base Service Price
    if (_selectedBaseServiceId != null) {
      final service = _washTypes.firstWhere(
        (w) => w['id'] == _selectedBaseServiceId,
        orElse: () => {},
      );
      if (service.isNotEmpty) {
        final priceMap = service['precios'] as Map<String, dynamic>?;
        total += (priceMap?[_selectedVehicleType] ?? 0).toDouble();
      }
    }

    // Extras Prices
    for (final extraId in _selectedExtrasIds) {
      final service = _washTypes.firstWhere(
        (w) => w['id'] == extraId,
        orElse: () => {},
      );
      if (service.isNotEmpty) {
        final priceMap = service['precios'] as Map<String, dynamic>?;
        total += (priceMap?[_selectedVehicleType] ?? 0).toDouble();
      }
    }

    return total;
  }

  double get isv => subtotal * 0.15;
  double get total => subtotal + isv;

  @override
  void dispose() {
    _washTypeSubscription?.cancel();
    nameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    modelController.dispose();
    super.dispose();
  }
}
