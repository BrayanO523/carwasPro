import 'package:cloud_firestore/cloud_firestore.dart';

class WashTypesSeeder {
  static Future<void> seed() async {
    final collection = FirebaseFirestore.instance.collection('tiposLavados');

    // Check if collection is empty
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return; // Already seeded
    }

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
