
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/sensor_reading.dart';
import '../services/sensor_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final SensorService _servicio = SensorService();

  String _zona = 'C';
  String _variable = 'Temperatura';

  bool _cargando = true;
  String? _error;

  List<SensorReading> _historial = [];

  static const Color fondo = Color(0xFF0D0B2B);
  static const Color tarjeta = Color(0xFF1D1B45);
  static const Color morado = Color(0xFFB366FF);

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final zonaConsultada = _zona;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final datos = await _servicio.obtenerHistorial(
        zonaConsultada,
      );

      if (!mounted || zonaConsultada != _zona) return;

      setState(() {
        _historial = datos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || zonaConsultada != _zona) return;

      setState(() {
        _historial = [];
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  double _obtenerValor(SensorReading lectura) {
    switch (_variable) {
      case 'Humedad':
        return lectura.humedad;
      case 'Iluminación':
        return lectura.iluminacion;
      default:
        return lectura.temperatura;
    }
  }

  String get _unidad {
    switch (_variable) {
      case 'Humedad':
        return '%';
      case 'Iluminación':
        return '';
      default:
        return '°C';
    }
  }

  Color get _colorGrafica {
    switch (_variable) {
      case 'Humedad':
        return Colors.lightBlueAccent;
      case 'Iluminación':
        return Colors.amberAccent;
      default:
        return morado;
    }
  }

  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  Widget _selectorZona() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ['C', 'S1', 'S2'].map((zona) {
        final seleccionado = _zona == zona;

        return ChoiceChip(
          label: Text(
            zona == 'C' ? 'Zona Central' : 'Zona $zona',
          ),
          selected: seleccionado,
          onSelected: (_) {
            if (_zona == zona) return;

            setState(() {
              _zona = zona;
              _historial = [];
            });

            _cargarHistorial();
          },
          selectedColor: morado,
          backgroundColor: tarjeta,
          labelStyle: TextStyle(
            color: seleccionado ? Colors.black : Colors.white,
          ),
        );
      }).toList(),
    );
  }

  Widget _selectorVariable() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        'Temperatura',
        'Humedad',
        'Iluminación',
      ].map((variable) {
        final seleccionado = _variable == variable;

        return ChoiceChip(
          label: Text(variable),
          selected: seleccionado,
          onSelected: (_) {
            setState(() {
              _variable = variable;
            });
          },
          selectedColor: morado,
          backgroundColor: tarjeta,
          labelStyle: TextStyle(
            color: seleccionado ? Colors.black : Colors.white,
          ),
        );
      }).toList(),
    );
  }

  Widget _grafica() {
    if (_cargando) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar el historial',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: _cargarHistorial,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_historial.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Todavía no hay mediciones guardadas '
            'para esta zona.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final valores = _historial.map(_obtenerValor).toList();

    final minimo = valores.reduce(
      (a, b) => a < b ? a : b,
    );
    final maximo = valores.reduce(
      (a, b) => a > b ? a : b,
    );

    final margen = (maximo - minimo).abs() < 1
        ? 2.0
        : (maximo - minimo) * 0.15;

    final puntos = List.generate(
      _historial.length,
      (indice) => FlSpot(
        indice.toDouble(),
        valores[indice],
      ),
    );

    final saltoEtiquetas = _historial.length <= 5
        ? 1
        : (_historial.length / 5).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registros disponibles: ${_historial.length}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 280,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: _historial.length == 1
                  ? 1
                  : (_historial.length - 1).toDouble(),
              minY: minimo - margen,
              maxY: maximo + margen,
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white12,
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: Colors.white12,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (valor, meta) {
                      return Text(
                        valor.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (valor, meta) {
                      final indice = valor.toInt();

                      if (indice < 0 ||
                          indice >= _historial.length ||
                          indice % saltoEtiquetas != 0) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatearHora(
                            _historial[indice].fecha,
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: puntos,
                  isCurved: false,
                  color: _colorGrafica,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: _historial.length <= 30,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _colorGrafica.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Último valor: '
          '${valores.last.toStringAsFixed(1)} $_unidad',
          style: TextStyle(
            color: _colorGrafica,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        title: const Text('Gráficas ambientales'),
        actions: [
          IconButton(
            tooltip: 'Actualizar historial',
            onPressed: _cargarHistorial,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarHistorial,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Historial de mediciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consulta los cambios ambientales '
              'registrados en cada zona del aula.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 28),
            const Text(
              'Selecciona una zona',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _selectorZona(),
            const SizedBox(height: 28),
            const Text(
              'Selecciona una medición',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _selectorVariable(),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: tarjeta,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: morado.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_variable - Zona $_zona',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _grafica(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Las gráficas muestran las mediciones '
              'almacenadas por el backend de AulaSense. '
              'Los datos de demostración no representan '
              'lecturas reales del Photon.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

