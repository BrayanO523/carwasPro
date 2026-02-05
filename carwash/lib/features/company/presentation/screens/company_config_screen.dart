import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CompanyConfigScreen extends StatefulWidget {
  const CompanyConfigScreen({super.key});

  @override
  State<CompanyConfigScreen> createState() => _CompanyConfigScreenState();
}

class _CompanyConfigScreenState extends State<CompanyConfigScreen> {
  bool _isLoading = true;
  Company? _company;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null && user.companyId.isNotEmpty) {
        final company = await context.read<CompanyRepository>().getCompany(
          user.companyId,
        );
        if (mounted) {
          setState(() {
            _company = company;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Empresa',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _company == null
          ? _buildNoCompanyView()
          : _buildCompanyInfoView(),
    );
  }

  Widget _buildNoCompanyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No se encontró información de empresa',
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoView() {
    final company = _company!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header Card
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      company.name.isNotEmpty
                          ? company.name[0].toUpperCase()
                          : 'E',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RTN: ${company.rtn}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Company Details Section
          Text(
            'INFORMACIÓN DE LA EMPRESA',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          // Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'RTN (Registro Tributario)',
                    value: company.rtn,
                    isProtected: true,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Dirección',
                    value: company.address.isNotEmpty
                        ? company.address
                        : 'No especificada',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: company.phone.isNotEmpty
                        ? company.phone
                        : 'No especificado',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Correo Electrónico',
                    value: company.email.isNotEmpty
                        ? company.email
                        : 'No especificado',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha de Registro',
                    value: DateFormat('dd/MM/yyyy').format(company.createdAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Note about protected fields
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Los datos marcados con 🔒 son protegidos y no pueden editarse desde la aplicación.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isProtected = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blueGrey.shade400),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (isProtected) ...[
                    const SizedBox(width: 6),
                    const Text('🔒', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
