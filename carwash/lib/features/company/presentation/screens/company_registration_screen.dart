import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/company_registration_provider.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  State<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyRegistrationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Empresa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 0) {
              context.pop();
            } else {
              setState(() => _currentStep--);
            }
          },
        ),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () async {
          if (_currentStep == 0) {
            // Validate Company Form (Basic check)
            if (provider.companyNameController.text.isNotEmpty &&
                provider.rtnController.text.isNotEmpty) {
              setState(() => _currentStep++);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor complete los campos obligatorios'),
                ),
              );
            }
          } else {
            // Register
            final success = await provider.registerCompany();
            if (success && context.mounted) {
              // Navigate to Home or Login
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Empresa registrada con éxito!')),
              );
              context.go('/home');
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            context.pop();
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : details.onStepContinue,
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 0 ? 'Siguiente' : 'Registrar'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.isLoading
                          ? null
                          : details.onStepCancel,
                      child: const Text('Atrás'),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          // Step 1: Company Info
          Step(
            title: const Text('Datos de la Empresa'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                TextField(
                  controller: provider.companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Empresa *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: provider.rtnController,
                  decoration: const InputDecoration(
                    labelText: 'RTN (ID Legal) *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: provider.addressController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: provider.phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: provider.emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email de la Empresa',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),

          // Step 2: Admin User Info
          Step(
            title: const Text('Usuario Administrador'),
            subtitle: const Text('Este usuario tendrá acceso total'),
            isActive: _currentStep >= 1,
            state: StepState.editing,
            content: Column(
              children: [
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      provider.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                TextField(
                  controller: provider.adminNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: provider.adminEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email de Usuario *',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: provider.adminPasswordController,
                  decoration: const InputDecoration(labelText: 'Contraseña *'),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
