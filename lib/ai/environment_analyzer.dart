
import '../models/sensor_reading.dart';

class EnvironmentAnalysis {
  final String estado;
  final String resumen;
  final List<String> recomendaciones;
  final int alertas;

  const EnvironmentAnalysis({
    required this.estado,
    required this.resumen,
    required this.recomendaciones,
    required this.alertas,
  });
}

class EnvironmentAnalyzer {
  static EnvironmentAnalysis analizar(SensorReading lectura) {
    final recomendaciones = <String>[];
    int alertas = 0;

    // Analizar temperatura
    if (lectura.temperatura > 28) {
      alertas++;
      recomendaciones.add(
        'La temperatura es elevada. Se recomienda '
        'mejorar la ventilación del aula.',
      );
    } else if (lectura.temperatura < 18) {
      alertas++;
      recomendaciones.add(
        'La temperatura es baja. Se recomienda '
        'revisar las condiciones térmicas.',
      );
    }

    // Analizar humedad
    if (lectura.humedad > 60) {
      alertas++;
      recomendaciones.add(
        'La humedad es elevada. Se recomienda '
        'revisar la ventilación.',
      );
    } else if (lectura.humedad < 30) {
      alertas++;
      recomendaciones.add(
        'La humedad es baja. Se recomienda '
        'revisar las condiciones ambientales.',
      );
    }

    // Analizar iluminación
    if (lectura.iluminacion < 300) {
      alertas++;
      recomendaciones.add(
        'La iluminación es baja. Se recomienda '
        'revisar las lámparas del aula.',
      );
    }

    if (recomendaciones.isEmpty) {
      recomendaciones.add(
        'Las condiciones ambientales están dentro '
        'de los rangos configurados.',
      );
    }

    return EnvironmentAnalysis(
      estado: alertas == 0
          ? 'Condiciones dentro de rango'
          : 'Requiere revisión',
      resumen: alertas == 0
          ? 'No se detectaron valores fuera de rango.'
          : 'Se detectaron $alertas indicadores '
              'fuera de los rangos configurados.',
      recomendaciones: recomendaciones,
      alertas: alertas,
    );
  }
}
