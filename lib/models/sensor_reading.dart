class SensorReading {
  final String zona;
  final double temperatura;
  final double humedad;
  final double iluminacion;
  final DateTime fecha;

  SensorReading({
    required this.zona,
    required this.temperatura,
    required this.humedad,
    required this.iluminacion,
    required this.fecha,
  });

  // Convertir los datos recibidos de la API a un objeto Dart
  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      zona: json['zona'].toString(),
      temperatura: (json['temperatura'] as num).toDouble(),
      humedad: (json['humedad'] as num).toDouble(),
      iluminacion: (json['iluminacion'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'].toString()),
    );
  }

  // Convertir un objeto Dart a formato JSON
  Map<String, dynamic> toJson() {
    return {
      'zona': zona,
      'temperatura': temperatura,
      'humedad': humedad,
      'iluminacion': iluminacion,
      'fecha': fecha.toIso8601String(),
    };
  }
}