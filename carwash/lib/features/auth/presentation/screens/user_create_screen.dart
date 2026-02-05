import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_management_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserCreateScreen extends StatefulWidget {
  const UserCreateScreen({super.key});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Clear previous state in provider if needed, or rely on provider clean up
    // Ideally provider should have a reset or clear method for form fields
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementProvider>().clearForm();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserManagementProvider>();
    final companyId = context.read<AuthProvider>().currentUser?.companyId;
    final operatorId = context.read<AuthProvider>().currentUser?.id;

    if (companyId == null) return;

    final success = await provider.createUser(
      companyId: companyId,
      operatorId: operatorId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario creado exitosamente')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserManagementProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent with BranchCreateScreen
      appBar: AppBar(
        title: Text(
          'Nuevo Usuario',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información de Usuario',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: provider.nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: provider.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: provider.passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.length < 6
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Role
                    DropdownButtonFormField<String>(
                      initialValue: provider.selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('Empleado'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administrador'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) provider.setSelectedRole(val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Branch
                    DropdownButtonFormField<String>(
                      initialValue: provider.selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Sucursal Asignada',
                        prefixIcon: Icon(Icons.store_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: provider.branches.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        provider.setSelectedBranch(val);
                      },
                      validator: (v) =>
                          v == null ? 'Seleccione una sucursal' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color(0xFF1E88E5),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Crear Usuario',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
