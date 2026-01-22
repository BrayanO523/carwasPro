import 'package:cloud_firestore/cloud_firestore.dart';

class WashTypesSeeder {
  static Future<void> seed() async {
    final collection = FirebaseFirestore.instance.collection('tiposLavados');

    // MIGRATION: Fix existing documents missing 'empresa_id'
    final existingSnapshot = await collection.get();
    if (existingSnapshot.docs.isNotEmpty) {
      final batchUpdate = FirebaseFirestore.instance.batch();
      bool anyUpdated = false;

      for (final doc in existingSnapshot.docs) {
        final data = doc.data();
        // Check if missing or null. If missing, we want to set it to null explicitly?
        // Actually, if key is missing, data['empresa_id'] is null.
        // But in Firestore, we want the field to exist as null for the query `isNull: true` to work reliably?
        // Or at least ensure consistent schema.

        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        if (!data.containsKey('empresa_id')) {
          updates['empresa_id'] = null; // Set explicitly to null
          needsUpdate = true;
        }
        if (!data.containsKey('sucursal_ids')) {
          updates['sucursal_ids'] = [];
          needsUpdate = true;
        }

        if (needsUpdate) {
          batchUpdate.update(doc.reference, updates);
          anyUpdated = true;
        }
      }

      if (anyUpdated) {
        print("Migrating existing wash types...");
        await batchUpdate.commit();
        print("Migration complete.");
      }

      // If we have data (migrated or not), we stop here. Use separate logic if we want to add missing defaults.
      return;
    }

    // SEED: If empty, create initial data
    final batch = FirebaseFirestore.instance.batch();

    final List<Map<String, dynamic>> services = [
      // SERVICIOS BASE
      {
        "nombre": "Lavado Sencillo",
        "descripcion":
            "Lavado exterior básico: jabón, enjuague y secado exterior.",
        "categoria": "base",
        "precios": {
          "moto": 100,
          "turismo": 150,
          "camioneta": 220,
          "grande": 280,
        },
        "activo": true,
        "empresa_id": null,
        "sucursal_ids": [],
      },
      {
        "nombre": "Lavado Completo",
        "descripcion":
            "Lavado exterior, aspirado profundo, limpieza de tablero, almorol y aromatizante.",
        "categoria": "base",
        "precios": {
          "moto": 180,
          "turismo": 280,
          "camioneta": 350,
          "grande": 450,
        },
        "activo": true,
        "empresa_id": null,
        "sucursal_ids": [],
      },

      // SERVICIOS EXTRA
      {
        "nombre": "Lavado de Motor",
        "descripcion": "Limpieza y desengrasado del motor.",
        "categoria": "extra",
        "precios": {
          "moto": 150,
          "turismo": 250,
          "camioneta": 250,
          "grande": 300,
        },
        "activo": true,
        "empresa_id": null,
        "sucursal_ids": [],
      },
      {
        "nombre": "Lavado de Chasis",
        "descripcion": "Lavado a presión de la parte inferior del vehículo.",
        "categoria": "extra",
        "precios": {
          "moto": 100,
          "turismo": 200,
          "camioneta": 200,
          "grande": 250,
        },
        "activo": true,
        "empresa_id": null,
        "sucursal_ids": [],
      },
      {
        "nombre": "Pasteado (Encerado)",
        "descripcion":
            "Aplicación de cera protectora para brillo y protección.",
        "categoria": "extra",
        "precios": {
          "moto": 150,
          "turismo": 300,
          "camioneta": 400,
          "grande": 500,
        },
        "activo": true,
        "empresa_id": null,
        "sucursal_ids": [],
      },
      {
        "nombre": "Pulido de Faros",
        "descripcion": "Restauración de transparencia de faros delanteros.",
        "categoria": "extra",
        "precios": {
          "moto": 150,
          "turismo": 300,
          "camioneta": 300,
          "grande": 350,
        },
        "activo": true,
        "empresa_id": null,
        "sucursal_ids": [],
      },
      {
        "nombre": "Lavado de Tapicería",
        "descripcion":
            "Limpieza profunda de asientos y alfombras (Shampuseado).",
        "categoria": "extra",
        "precios": {
          "moto": 300, // Asiento moto
          "turismo": 800,
          "camioneta": 1000,
          "grande": 1200,
        },
        "activo": true,
        "empresa_id": null,
        "sucursal_ids": [],
      },
      {
        "nombre": "Descontaminado (Clay Bar)",
        "descripcion": "Eliminación de impurezas incrustadas en la pintura.",
        "categoria": "extra",
        "precios": {
          "moto": 300,
          "turismo": 500,
          "camioneta": 600,
          "grande": 700,
        },
        "activo": true,
        "empresa_id": null,
        "sucursal_ids": [],
      },
    ];

    for (final service in services) {
      final doc = collection.doc(); // Auto-ID
      batch.set(doc, service);
    }

    await batch.commit();
    print("Seed de tiposLavados completado con éxito.");
  }
}
