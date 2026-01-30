import 'dart:developer';

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart'; // Restored
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/vehicle_entry_repository.dart';
import '../../../wash_types/domain/repositories/wash_type_repository.dart';
import '../../../wash_types/domain/entities/wash_type.dart';
import '../../domain/entities/vehicle.dart';
import '../../data/models/client_model.dart';
import '../../data/models/vehicle_model.dart';

class VehicleEntryProvider extends ChangeNotifier {
  final VehicleEntryRepository _repository;
  final WashTypeRepository _washTypeRepository;

  // Form Controllers
  final nameController = TextEditingController(); // Stores "Full Name"
  final phoneController = TextEditingController();
  // final modelController = TextEditingController(); // Removed
  final customTypeController =
      TextEditingController(); // For "Otro" manual input

  // State
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WashType> _washTypes = [];
  String _selectedVehicleType = 'turismo'; // Default
  String? _selectedBaseServiceId;
  final Set<String> _selectedExtrasIds = {};

  final List<String> vehicleTypes = Vehicle.types; // Use centralized list

  VehicleEntryProvider({
    required VehicleEntryRepository repository,
    required WashTypeRepository washTypeRepository,
  }) : _repository = repository,
       _washTypeRepository = washTypeRepository;

  List<File> get selectedImages => _selectedImages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<WashType> get washTypes => _washTypes; // Exposed as Entity List
  String get selectedVehicleType => _selectedVehicleType;
  String? get selectedBaseServiceId => _selectedBaseServiceId;
  Set<String> get selectedExtrasIds => _selectedExtrasIds;

  StreamSubscription? _washTypeSubscription;

  // Subscribe to wash types for Real-time updates
  void subscribeToWashTypes(String companyId, String branchId) {
    _washTypeSubscription?.cancel();

    _washTypeSubscription = _washTypeRepository
        .getWashTypesStream(companyId: companyId)
        .listen(
          (allTypes) {
            // Filter by Active and Branch Availability
            final filtered = allTypes.where((type) {
              if (!type.isActive) return false;
              if (type.branchIds.isEmpty) return true;
              return type.branchIds.contains(branchId);
            }).toList();

            _washTypes = filtered;

            // Select first base service by default if available and nothing selected
            final baseServices = _washTypes
                .where((w) => w.category == 'base')
                .toList();

            // Ensure current selection is still valid, else reset
            if (_selectedBaseServiceId == null ||
                !baseServices.any((x) => x.id == _selectedBaseServiceId)) {
              if (baseServices.isNotEmpty) {
                _selectedBaseServiceId = baseServices.first.id;
              } else {
                _selectedBaseServiceId = null;
              }
            }

            notifyListeners();
          },
          onError: (e) {
            log('Error loading wash types stream: $e');
            _errorMessage = 'Error de conexión con servicios: $e';
            notifyListeners();
          },
        );
  }

  // ... setters remain same ...

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

  Future<void> pickImage({ImageSource source = ImageSource.camera}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
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
        _selectedImages.isEmpty ||
        _selectedBaseServiceId == null) {
      _errorMessage =
          'Por favor complete todos los campos, seleccione un lavado y añada al menos una foto';
      notifyListeners();
      return false;
    }

    if (_selectedVehicleType == 'otro' && customTypeController.text.isEmpty) {
      _errorMessage = 'Por favor especifique el tipo de vehículo';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String clientId;
      ClientModel client;
      String fullName = nameController.text.trim();
      final effectiveBranchId = branchId ?? 'main';

      final existingClient = await _repository.getClientByPhone(
        phoneController.text.trim(),
        companyId,
      );

      if (existingClient != null) {
        clientId = existingClient.id;
        client = ClientModel(
          id: clientId,
          fullName: fullName,
          phone: phoneController.text.trim(),
          companyId: companyId,
          branchId: effectiveBranchId,
        );
      } else {
        clientId = const Uuid().v4();
        client = ClientModel(
          id: clientId,
          fullName: fullName,
          phone: phoneController.text.trim(),
          companyId: companyId,
          branchId: effectiveBranchId,
        );
      }

      await _repository.saveClient(client);

      final vehicleId = const Uuid().v4();
      final uploadTasks = _selectedImages.map((image) {
        return _repository.uploadVehicleImage(
          imageFile: image,
          companyId: companyId,
          branchId: effectiveBranchId,
          clientId: clientId,
          vehicleId: vehicleId,
          clientName: fullName,
          vehicleType: _selectedVehicleType,
        );
      });

      final photoUrls = await Future.wait(uploadTasks);

      List<String> selectedServices = [];
      if (_selectedBaseServiceId != null) {
        selectedServices.add(_selectedBaseServiceId!);
      }
      selectedServices.addAll(_selectedExtrasIds);

      final finalVehicleType = _selectedVehicleType == 'otro'
          ? customTypeController.text.trim()
          : _selectedVehicleType;

      final vehicle = VehicleModel(
        id: vehicleId,
        clientId: clientId,
        companyId: companyId,
        entryDate: DateTime.now(),
        photoUrls: photoUrls,
        status: Vehicle.statusWashing,
        branchId: effectiveBranchId,
        clientName: fullName,
        vehicleType: finalVehicleType,
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
    phoneController.clear();
    customTypeController.clear();
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
    final lookupType = _selectedVehicleType;

    // Base Service Price
    if (_selectedBaseServiceId != null) {
      final service = _getWashTypeById(_selectedBaseServiceId!);
      if (service != null) {
        total += service.getPriceFor(lookupType);
      }
    }

    // Extras Prices
    for (final extraId in _selectedExtrasIds) {
      final service = _getWashTypeById(extraId);
      if (service != null) {
        total += service.getPriceFor(lookupType);
      }
    }

    return total;
  }

  WashType? _getWashTypeById(String id) {
    try {
      return _washTypes.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  // Helper for UI: Get Price Logic
  double getPrice(String serviceId) {
    final service = _getWashTypeById(serviceId);
    if (service == null) return 0.0;
    return service.getPriceFor(_selectedVehicleType);
  }

  // Helper for UI: Summary Logic
  String getServiceSummary({required bool isEmployee}) {
    if (_selectedBaseServiceId == null) return '';

    final base = _getWashTypeById(_selectedBaseServiceId!);
    if (base == null) return '';

    String text = base.name;
    if (!isEmployee) {
      text += ' (L. ${getPrice(base.id).toStringAsFixed(2)})';
    }

    for (final extraId in _selectedExtrasIds) {
      final extra = _getWashTypeById(extraId);
      if (extra != null) {
        text += '\n+ ${extra.name}';
        if (!isEmployee) {
          text += ' (L. ${getPrice(extra.id).toStringAsFixed(2)})';
        }
      }
    }
    return text;
  }

  double get isv => subtotal * 0.15;
  double get total => subtotal + isv;

  @override
  void dispose() {
    _washTypeSubscription?.cancel();
    nameController.dispose();

    phoneController.dispose();
    // modelController.dispose(); // Removed
    customTypeController.dispose();
    super.dispose();
  }
}
