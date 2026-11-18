
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  static const Color fondo = Color(0xFF0D0B2B);
  static const Color tarjeta = Color(0xFF1D1B45);
  static const Color morado = Color(0xFFB366FF);
  static const Color moradoFuerte = Color(0xFF9333EA);

  static const String baseUrl = 'http://localhost:3000';

  // Actividades disponibles para el estudiante
  static const Map<String, String> actividades = {
    'general': 'Actividades generales',
    'lectura': 'Lectura y escritura',
    'computadora': 'Trabajo en computadora',
    'concentracion': 'Estudio y concentración',
  };

  String _actividadSeleccionada = 'general';

  bool _cargando = true;
  String? _error;

  List<Map<String, dynamic>> _analisis = [];

  // Evita mostrar resultados de una actividad anterior
  int _numeroSolicitud = 0;

  @override
  void initState() {
    super.initState();
    _cargarAnalisis();
  }

  // ==========================================
  // CONSULTAR RECOMENDACIONES DEL BACKEND
  // ==========================================

  Future<void> _cargarAnalisis() async {
    final solicitudActual = ++_numeroSolicitud;
    final actividad = _actividadSeleccionada;

    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final zonas = ['C', 'S1', 'S2'];

      final respuestas = await Future.wait(
        zonas.map((zona) {
          final uri = Uri.parse(
            '$baseUrl/api/ia/recomendaciones/$zona',
          ).replace(
            queryParameters: {
              'actividad': actividad,
            },
          );

          return http.get(uri).timeout(
            const Duration(seconds: 10),
          );
        }),
      );

      final resultados = <Map<String, dynamic>>[];

      for (final respuesta in respuestas) {
        if (respuesta.statusCode != 200) {
          throw Exception(
            'Error del servidor: ${respuesta.statusCode}',
          );
        }

        final datos = jsonDecode(respuesta.body);

        if (datos is! Map<String, dynamic>) {
          throw const FormatException(
            'El servidor devolvió un formato no válido.',
          );
        }

        resultados.add(datos);
      }

      if (!mounted || solicitudActual != _numeroSolicitud) {
        return;
      }

      setState(() {
        _analisis = resultados;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || solicitudActual != _numeroSolicitud) {
        return;
      }

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  // ==========================================
  // CAMBIAR ACTIVIDAD
  // ==========================================

  void _cambiarActividad(String? actividad) {
    if (actividad == null ||
        actividad == _actividadSeleccionada) {
      return;
    }

    setState(() {
      _actividadSeleccionada = actividad;
    });

    _cargarAnalisis();
  }

  // ==========================================
  // SELECTOR DE ACTIVIDADES
  // ==========================================

  Widget _selectorActividades() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: morado.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: morado,
                size: 27,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Personaliza tu análisis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Selecciona la actividad que realizarás '
            'para recibir recomendaciones ambientales '
            'adaptadas a tus necesidades.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Actividad de estudio',
            style: TextStyle(
              color: morado,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: _actividadSeleccionada,
            isExpanded: true,
            dropdownColor: tarjeta,
            iconEnabledColor: morado,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: fondo,
              prefixIcon: const Icon(
                Icons.menu_book_outlined,
                color: morado,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: morado.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: morado,
                  width: 1.5,
                ),
              ),
            ),
            items: actividades.entries.map((entrada) {
              return DropdownMenuItem<String>(
                value: entrada.key,
                child: Text(
                  entrada.value,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _cambiarActividad,
          ),

          const SizedBox(height: 14),

          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white54,
                size: 17,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'La actividad seleccionada se aplicará '
                  'a las tres zonas del aula.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FUNCIONES AUXILIARES
  // ==========================================

  double _numero(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    return double.tryParse(valor.toString()) ?? 0;
  }

  String _nombreZona(String zona) {
    if (zona == 'C') {
      return 'Salón C - Zona Central';
    }

    return 'Salón $zona';
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Adecuado':
        return Colors.greenAccent;

      case 'Mejorable':
        return Colors.orangeAccent;

      case 'Requiere atención':
        return Colors.redAccent;

      default:
        return Colors.grey;
    }
  }

  Widget _dato(
    IconData icono,
    String titulo,
    String valor,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icono,
            color: color,
            size: 25,
          ),

          const SizedBox(height: 8),

          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TARJETA DE ANÁLISIS
  // ==========================================

  Widget _tarjetaAnalisis(Map<String, dynamic> datos) {
    final zona = datos['zona']?.toString() ?? '';

    final estado =
        datos['estado']?.toString() ?? 'Sin información';

    final puntuacion = _numero(datos['puntuacion'])
        .clamp(0.0, 100.0)
        .toDouble();

    final colorEstado = _colorEstado(estado);

    final medicion =
        datos['medicion'] is Map<String, dynamic>
            ? datos['medicion'] as Map<String, dynamic>
            : <String, dynamic>{};

    final temperatura = _numero(
      medicion['temperatura'],
    );

    final humedad = _numero(
      medicion['humedad'],
    );

    final iluminacion = _numero(
      medicion['iluminacion'],
    );

    final alertas = (datos['alertas'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    final recomendaciones =
        (datos['recomendaciones'] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toList();

    final mensaje =
        datos['mensaje']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: morado.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NOMBRE DEL SALÓN
          Row(
            children: [
              const Icon(
                Icons.meeting_room_outlined,
                color: morado,
                size: 30,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  _nombreZona(zona),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // MEDICIONES
          Row(
            children: [
              Expanded(
                child: _dato(
                  Icons.thermostat,
                  'Temperatura',
                  '${temperatura.toStringAsFixed(1)} °C',
                  Colors.redAccent,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _dato(
                  Icons.water_drop,
                  'Humedad',
                  '${humedad.toStringAsFixed(0)} %',
                  Colors.lightBlueAccent,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _dato(
                  Icons.wb_sunny_outlined,
                  'Iluminación',
                  '${iluminacion.toStringAsFixed(0)} lux',
                  Colors.amberAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ESTADO AMBIENTAL
          Row(
            children: [
              Icon(
                estado == 'Adecuado'
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: colorEstado,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  estado,
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                '${puntuacion.toStringAsFixed(0)}/100',
                style: TextStyle(
                  color: colorEstado,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // BARRA DE PUNTUACIÓN
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: puntuacion / 100,
              minHeight: 10,
              backgroundColor: fondo,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorEstado,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            mensaje,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          // ALERTAS
          if (alertas.isNotEmpty) ...[
            const SizedBox(height: 22),

            const Text(
              'Alertas detectadas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...alertas.map(
              (alerta) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orangeAccent,
                      size: 19,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        alerta,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 22),

          // RECOMENDACIONES
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: morado,
              ),

              SizedBox(width: 10),

              Text(
                'Recomendaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...recomendaciones.map(
            (recomendacion) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: morado,
                    size: 20,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      recomendacion,
                      style: const TextStyle(
                        color: Colors.white70,
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

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text('Análisis inteligente'),
        centerTitle: true,
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _cargarAnalisis,
            tooltip: 'Actualizar análisis',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarAnalisis,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.psychology_outlined,
              color: morado,
              size: 55,
            ),

            const SizedBox(height: 12),

            const Text(
              'AulaSense - Análisis inteligente',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Recomendaciones ambientales para '
              'mejorar las condiciones de estudio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Análisis basado en reglas de referencia',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: morado,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 28),

            // SELECTOR DE ACTIVIDADES
            _selectorActividades(),

            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(
                    color: morado,
                  ),
                ),
              )
            else if (_error != null)
              Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 42,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'No se pudieron consultar las recomendaciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton.icon(
                    onPressed: _cargarAnalisis,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: moradoFuerte,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            else
              ..._analisis.map(_tarjetaAnalisis),

            const SizedBox(height: 20),

            const Text(
              'Las recomendaciones se generan '
              'automáticamente mediante reglas '
              'configuradas en el servidor Node.js. '
              'La puntuación es orientativa y no '
              'constituye una evaluación científica '
              'validada. Las mediciones pueden ser '
              'de demostración hasta integrar '
              'el Particle Photon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
