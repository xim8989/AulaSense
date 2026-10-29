import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_reading.dart';

class SensorService {
  // ==========================================
  // CONFIGURACIÓN
  // ==========================================

  // false = consultar el backend Node.js
  // true = utilizar datos simulados
  static const bool modoDemostracion = false;

  // Backend local de AulaSense.
  // Funciona cuando Flutter se ejecuta en Edge
  // y Node.js está en la misma computadora.
  static const String baseUrl = 'http://localhost:3000';

  // ==========================================
  // OBTENER LA ÚLTIMA MEDICIÓN DE UNA ZONA
  // ==========================================

  Future<SensorReading> obtenerMedicion(String zona) async {
    final codigo = zona.toUpperCase();

    if (modoDemostracion) {
      return obtenerMedicionSimulada(codigo);
    }

    try {
      final uri = Uri.parse(
        '$baseUrl/api/mediciones/$codigo',
      );

      final respuesta = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (respuesta.statusCode != 200) {
        throw Exception(
          'No se pudo consultar la zona $codigo. '
          'Código: ${respuesta.statusCode}',
        );
      }

      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException(
          'La respuesta de la API no es válida.',
        );
      }

      // El backend responde:
      // {
      //   "zona": "C",
      //   "medicion": {
      //     "temperatura": 26.5,
      //     "humedad": 60,
      //     "iluminacion": 450,
      //     "fecha": "..."
      //   }
      // }

      final medicion = datos['medicion'];

      if (medicion is! Map<String, dynamic>) {
        throw const FormatException(
          'No se encontraron los datos de la medición.',
        );
      }

      return SensorReading(
        zona: codigo,
        temperatura:
            (medicion['temperatura'] as num).toDouble(),
        humedad:
            (medicion['humedad'] as num).toDouble(),
        iluminacion:
            (medicion['iluminacion'] as num).toDouble(),
        fecha: medicion['fecha'] != null
            ? DateTime.parse(
                medicion['fecha'].toString(),
              ).toLocal()
            : DateTime.now(),
      );
    } catch (error) {
      throw Exception(
        'Error al conectar con el backend de AulaSense: $error',
      );
    }
  }

  // ==========================================
  // OBTENER HISTORIAL DE UNA ZONA
  // ==========================================

  Future<List<SensorReading>> obtenerHistorial(
    String zona,
  ) async {
    final codigo = zona.toUpperCase();

    if (modoDemostracion) {
      return obtenerHistorialSimulado(codigo);
    }

    try {
      // Consultar el historial del backend
      final uri = Uri.parse(
        '$baseUrl/api/historial/$codigo',
      );

      final respuesta = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      // Verificar la respuesta
      if (respuesta.statusCode != 200) {
        throw Exception(
          'No se pudo consultar el historial de $codigo. '
          'Código: ${respuesta.statusCode}',
        );
      }

      // Convertir la respuesta JSON
      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        throw const FormatException(
          'La respuesta del historial no es válida.',
        );
      }

      // Obtener la lista de mediciones
      final registros = datos['mediciones'];

      if (registros is! List) {
        throw const FormatException(
          'No se encontró una lista de mediciones.',
        );
      }

      // Convertir los registros a SensorReading
      final historial = registros.map((registro) {
        if (registro is! Map<String, dynamic>) {
          throw const FormatException(
            'Se encontró una medición inválida.',
          );
        }

        return SensorReading(
          zona: codigo,
          temperatura:
              (registro['temperatura'] as num).toDouble(),
          humedad:
              (registro['humedad'] as num).toDouble(),
          iluminacion:
              (registro['iluminacion'] as num).toDouble(),
          fecha: DateTime.parse(
            registro['fecha'].toString(),
          ).toLocal(),
        );
      }).toList();

      // Ordenar de la más antigua a la más reciente
      historial.sort(
        (a, b) => a.fecha.compareTo(b.fecha),
      );

      return historial;
    } catch (error) {
      throw Exception(
        'Error al consultar el historial de AulaSense: $error',
      );
    }
  }

  // ==========================================
  // MEDICIONES SIMULADAS
  // ==========================================

  SensorReading obtenerMedicionSimulada(String zona) {
    final fechaActual = DateTime.now();

    switch (zona.toUpperCase()) {
      case 'C':
        return SensorReading(
          zona: 'C',
          temperatura: 24.1,
          humedad: 52,
          iluminacion: 320,
          fecha: fechaActual,
        );

      case 'S1':
        return SensorReading(
          zona: 'S1',
          temperatura: 23.5,
          humedad: 48,
          iluminacion: 210,
          fecha: fechaActual,
        );

      case 'S2':
        return SensorReading(
          zona: 'S2',
          temperatura: 25.0,
          humedad: 55,
          iluminacion: 430,
          fecha: fechaActual,
        );

      default:
        throw ArgumentError(
          'La zona $zona no existe.',
        );
    }
  }

  // ==========================================
  // HISTORIAL SIMULADO
  // ==========================================

  List<SensorReading> obtenerHistorialSimulado(
    String zona,
  ) {
    final lecturaBase = obtenerMedicionSimulada(zona);

    final ahora = DateTime.now();

    return List.generate(12, (indice) {
      final variacion = (indice - 6) * 0.15;

      return SensorReading(
        zona: zona,
        temperatura:
            lecturaBase.temperatura + variacion,
        humedad:
            lecturaBase.humedad + (indice - 6) * 0.5,
        iluminacion:
            lecturaBase.iluminacion + (indice - 6) * 8,
        fecha: ahora.subtract(
          Duration(minutes: (11 - indice) * 5),
        ),
      );
    });
  }
}