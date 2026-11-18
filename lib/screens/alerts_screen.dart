
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const Color fondo = Color(0xFF0D0B2B);
  static const Color tarjeta = Color(0xFF1D1B45);
  static const Color morado = Color(0xFF9333EA);
  static const Color moradoClaro = Color(0xFFB366FF);

  static const String baseUrl = 'http://localhost:3000';

  final List<String> zonas = ['C', 'S1', 'S2'];

  final Map<String, Map<String, dynamic>> resultados = {};

  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarAlertas();
  }

  // CONSULTAR ALERTAS DEL BACKEND
  Future<void> cargarAlertas() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final Map<String, Map<String, dynamic>> nuevosResultados = {};

      for (final zona in zonas) {
        final uri = Uri.parse(
          '$baseUrl/api/ia/recomendaciones/$zona',
        );

        final respuesta = await http.get(uri).timeout(
          const Duration(seconds: 10),
        );

        if (respuesta.statusCode != 200) {
          throw Exception(
            'No se pudieron obtener las alertas de la zona $zona',
          );
        }

        final datos = jsonDecode(respuesta.body);

        if (datos is! Map<String, dynamic>) {
          throw Exception(
            'Respuesta incorrecta del backend para la zona $zona',
          );
        }

        nuevosResultados[zona] = datos;
      }

      if (!mounted) return;

      setState(() {
        resultados
          ..clear()
          ..addAll(nuevosResultados);

        cargando = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = 'No se pudieron cargar las alertas ambientales.';
      });

      debugPrint('Error al cargar alertas: $e');
    }
  }

  // OBTENER ALERTAS POR ZONA
  List<String> obtenerAlertas(String zona) {
    final datos = resultados[zona];

    if (datos == null) return [];

    final alertas = datos['alertas'];

    if (alertas is! List) return [];

    return alertas
        .map((alerta) {
          if (alerta is String) {
            return alerta;
          }

          if (alerta is Map) {
            return (alerta['mensaje'] ??
                    alerta['descripcion'] ??
                    alerta['texto'] ??
                    alerta.toString())
                .toString();
          }

          return alerta.toString();
        })
        .where((texto) => texto.trim().isNotEmpty)
        .toList();
  }

  int contarZonasConAlertas() {
    int total = 0;

    for (final zona in zonas) {
      if (obtenerAlertas(zona).isNotEmpty) {
        total++;
      }
    }

    return total;
  }

  String nombreZona(String zona) {
    switch (zona) {
      case 'C':
        return 'Zona Central (C)';
      case 'S1':
        return 'Zona S1';
      case 'S2':
        return 'Zona S2';
      default:
        return 'Zona $zona';
    }
  }

  // PANTALLA PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,

      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Centro de alertas',
          style: TextStyle(
            color: moradoClaro,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar alertas',
            onPressed: cargando ? null : cargarAlertas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: morado,
        onRefresh: cargarAlertas,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alertas ambientales',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Consulta las condiciones ambientales '
                    'que requieren atención en las tres zonas.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 25),

                  if (cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: moradoClaro,
                        ),
                      ),
                    )
                  else if (error != null)
                    _tarjetaError()
                  else ...[
                    _resumenAlertas(),

                    const SizedBox(height: 25),

                    const Text(
                      'Estado por zona',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    for (final zona in zonas) ...[
                      _tarjetaZona(zona),
                      const SizedBox(height: 15),
                    ],

                    const SizedBox(height: 10),

                    _avisoInformativo(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // RESUMEN GENERAL
  Widget _resumenAlertas() {
    final total = contarZonasConAlertas();
    final hayAlertas = total > 0;

    final Color colorEstado = hayAlertas
        ? Colors.orangeAccent
        : Colors.greenAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorEstado.withAlpha(120),
        ),
      ),

      child: Row(
        children: [
          Icon(
            hayAlertas
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: colorEstado,
            size: 36,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hayAlertas
                      ? '$total de 3 zonas con alertas'
                      : 'Sin alertas ambientales',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  hayAlertas
                      ? 'Revisa las recomendaciones '
                        'de las zonas que requieren atención.'
                      : 'Las tres zonas se encuentran '
                        'sin alertas registradas.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA DE CADA ZONA
  Widget _tarjetaZona(String zona) {
    final datos = resultados[zona] ?? {};
    final alertas = obtenerAlertas(zona);

    final bool hayAlertas = alertas.isNotEmpty;

    final Color colorEstado = hayAlertas
        ? Colors.orangeAccent
        : Colors.greenAccent;

    final estado = datos['estado']?.toString() ?? '';
    final puntuacion = datos['puntuacion'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorEstado.withAlpha(130),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hayAlertas
                    ? Icons.notifications_active_outlined
                    : Icons.check_circle_outline,
                color: colorEstado,
                size: 28,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  nombreZona(zona),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: colorEstado.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  hayAlertas ? 'Con alertas' : 'Normal',
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (estado.isNotEmpty || puntuacion != null) ...[
            const SizedBox(height: 15),

            Wrap(
              spacing: 15,
              runSpacing: 8,
              children: [
                if (estado.isNotEmpty)
                  Text(
                    'Estado: $estado',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),

                if (puntuacion != null)
                  Text(
                    'Puntuación: $puntuacion/100',
                    style: const TextStyle(
                      color: moradoClaro,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          if (!hayAlertas)
            const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.greenAccent,
                  size: 20,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'No se detectaron alertas ambientales.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            )
          else
            ...alertas.map(
              (alerta) => Padding(
                padding: const EdgeInsets.only(bottom: 12),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        alerta,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ERROR DE CONEXIÓN
  Widget _tarjetaError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.redAccent.withAlpha(120),
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 42,
          ),

          const SizedBox(height: 15),

          Text(
            error ?? 'Ocurrió un error.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: cargarAlertas,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: morado,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // AVISO INFORMATIVO
  Widget _avisoInformativo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: morado.withAlpha(90),
        ),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: moradoClaro,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Las alertas se generan mediante el análisis '
              'de temperatura, humedad e iluminación. '
              'Actualmente se utilizan mediciones de prueba '
              'del backend Node.js. Cuando se conecte '
              'el Particle Photon, se podrán analizar '
              'las mediciones reales.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
