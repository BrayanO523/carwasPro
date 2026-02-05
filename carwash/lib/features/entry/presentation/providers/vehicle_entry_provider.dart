import 'dart:developer';

import 'dart:async';
// import 'dart:io'; // Removed for web compatibility
import 'dart:typed_data'; // Added
import 'package:flutter/material.dart'; // Restored
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/vehicle_entry_repository.dart';
import '../../../wash_types/domain/repositories/wash_type_repository.dart';
import '../../../wash_types/domain/entities/wash_type.dart';
import '../../domain/entities/vehicle.dart';
import '../../data/models/client_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../domain/entities/client.dart';

import '../../../branch/domain/repositories/branch_repository.dart';
import '../../../branch/domain/entities/branch.dart';

class VehicleEntryProvider extends ChangeNotifier {
  final VehicleEntryRepository _repository;
  final WashTypeRepository _washTypeRepository;
  final BranchRepository _branchRepository;

  // Form Controllers
  final nameController = TextEditingController(); // Stores "Full Name"
  final phoneController = TextEditingController();
  final customTypeController =
      TextEditingController(); // For "Otro" manual input

  // State
  final List<Uint8List> _selectedImages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WashType> _washTypes = [];
  String _selectedVehicleType = 'turismo'; // Default
  String? _selectedBaseServiceId;
  final Set<String> _selectedExtrasIds = {};

  final List<String> vehicleTypes = Vehicle.types; // Use centralized list

  // Branch Selection (For Admins)
  List<Branch> _branches = [];
  String? _selectedEntryBranchId;

  VehicleEntryProvider({
    required VehicleEntryRepository repository,
    required WashTypeRepository washTypeRepository,
    required BranchRepository branchRepository,
  }) : _repository = repository,
       _washTypeRepository = washTypeRepository,
       _branchRepository = branchRepository;

  List<Uint8List> get selectedImages => _selectedImages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<WashType> get washTypes => _washTypes; // Exposed as Entity List
  String get selectedVehicleType => _selectedVehicleType;
  String? get selectedBaseServiceId => _selectedBaseServiceId;
  Set<String> get selectedExtrasIds => _selectedExtrasIds;

  List<Branch> get branches => _branches;
  String? get selectedEntryBranchId => _selectedEntryBranchId;

  StreamSubscription? _washTypeSubscription;

  void setSelectedEntryBranchId(String? id, String companyId) {
    if (_selectedEntryBranchId != id) {
      _selectedEntryBranchId = id;
      subscribeToWashTypes(companyId, id ?? '');
      subscribeToClients(companyId, id);
      notifyListeners();
    }
  }

  Future<void> loadBranches(String companyId) async {
    try {
      _branches = await _branchRepository.getBranches(companyId);
      // Removed manual defaulting per user request.
      // Logic relies on currentUser.branchId passed from UI.
      notifyListeners();
    } catch (e) {
      log('Error loading branches: $e');
    }
  }

  // Subscribe to wash types for Real-time updates
  void subscribeToWashTypes(String companyId, String branchId) {
    _washTypeSubscription?.cancel();

    // If admin selected a specific branch, use that for filtering wash types too!
    final effectiveBranchId = _selectedEntryBranchId ?? branchId;

    _washTypeSubscription = _washTypeRepository
        .getWashTypesStream(companyId: companyId, branchId: effectiveBranchId)
        .listen(
          (filtered) {
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
      final bytes = await pickedFile.readAsBytes();
      _selectedImages.add(bytes);
      notifyListeners();
    }
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }

  Future<bool> submitEntry(
    String companyId, {
    String?
    branchId, // This is current user's branchId (might be 'main' for admin)
    String? userId,
    String? userEmail,
  }) async {
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

    // Determine Effective Branch ID
    // If admin selected a branch manually, use it. Otherwise use user's branch.
    // Ensure we don't save 'main' if possible, unless selected explicitly as valid.
    final effectiveBranchId = _selectedEntryBranchId ?? branchId ?? 'main';

    // Safety check: admins should select a branch
    if (effectiveBranchId == 'main' && _branches.isNotEmpty) {
      // Ideally should block or default to first real branch, but let's assume UI handles selection.
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String clientId;
      ClientModel client;
      String fullName = nameController.text.trim();

      Client? targetClient = _selectedClient;

      // If not selected via autocomplete, try finding by phone
      targetClient ??= await _repository.getClientByPhone(
        phoneController.text.trim(),
        companyId,
        branchId: effectiveBranchId,
      );

      if (targetClient != null) {
        clientId = targetClient.id;
        // Preserve existing credit/info while updating basics
        client = ClientModel(
          id: clientId,
          fullName: fullName,
          phone: phoneController.text.trim(),
          companyId: companyId,
          branchId: effectiveBranchId,
          rtn: targetClient.rtn,
          address: targetClient.address,
          email: targetClient.email,
          creditProfile: targetClient.creditProfile,
          updatedBy: userId,
          updatedAt: DateTime.now(),
        );
      } else {
        clientId = const Uuid().v4();
        client = ClientModel(
          id: clientId,
          fullName: fullName,
          phone: phoneController.text.trim(),
          companyId: companyId,
          branchId: effectiveBranchId,
          createdBy: userId,
          createdAt: DateTime.now(),
        );
      }

      await _repository.saveClient(client);

      final vehicleId = const Uuid().v4();
      final uploadTasks = _selectedImages.map((image) {
        return _repository.uploadVehicleImage(
          imageBytes: image,
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
        createdBy: userId,
        createdAt: DateTime.now(),
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

  // Autocomplete helpers
  Client? _selectedClient;
  List<Client> _allClients = [];
  StreamSubscription? _clientsSubscription;

  void subscribeToClients(String companyId, String? branchId) {
    _clientsSubscription?.cancel();
    _clientsSubscription = _repository
        .getClientsStream(companyId, branchId: branchId)
        .listen(
          (clients) {
            _allClients = clients;
            notifyListeners();
          },
          onError: (e) {
            log('Error loading clients: $e');
          },
        );
  }

  List<Client> searchClientsLocal(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _allClients
        .where((c) => c.fullName.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  Future<List<Client>> searchClients(
    String query,
    String companyId, {
    String? branchId,
  }) {
    return _repository.searchClients(query, companyId, branchId: branchId);
  }

  void fillClientData(Client client) {
    nameController.text = client.fullName;
    phoneController.text = client.phone;
    _selectedClient = client;
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
    _clientsSubscription?.cancel();
    nameController.dispose();

    phoneController.dispose();
    // modelController.dispose(); // Removed
    customTypeController.dispose();
    super.dispose();
  }
}
