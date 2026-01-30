import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompanyConfigScreen extends StatelessWidget {
  const CompanyConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_rounded, size: 64, color: Colors.blueGrey[300]),
              const SizedBox(height: 24),
              Text(
                'Configuración Fiscal Movida',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Para cumplir con la normativa SAR en múltiples sucursales, la configuración de CAI y Facturación ahora se gestiona individualmente por sucursal.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.blueGrey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text(
                'Ve a: Sucursales > Editar > Configurar Facturación (SAR)',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
