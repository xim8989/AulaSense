import 'package:flutter/material.dart';

import '../services/profile_settings.dart';
import '../widgets/aula_components.dart';
import 'ai_analysis_screen.dart';
import 'charts_screen.dart';
import 'login_screen.dart';
import 'zones_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, String title, Widget child) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _ProfileSection(title: title, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ProfileSettings.instance;
    return Scaffold(
      backgroundColor: AulaStyle.background,
      appBar: AppBar(
        backgroundColor: AulaStyle.background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(
              Icons.person,
              color: AulaStyle.lightPurple,
              semanticLabel: 'Perfil activo',
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AulaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AulaStyle.purple.withAlpha(38),
                              child: const Icon(
                                Icons.person_outline,
                                size: 30,
                                color: AulaStyle.lightPurple,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settings.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    settings.email.isEmpty
                                        ? 'Sin correo de sesión'
                                        : settings.email,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: AulaStyle.button,
                            onPressed: () => _open(
                              context,
                              'Editar perfil',
                              const _EditProfile(),
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text(
                              'Editar perfil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Tu cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AulaCard(
                    child: Column(
                      children: [
                        _option(
                          context,
                          Icons.star_outline,
                          'Aulas favoritas',
                          'Guarda tus zonas y elige cuál ver primero.',
                          const _Favorites(),
                        ),
                        const Divider(color: Colors.white24, height: 30),
                        _option(
                          context,
                          Icons.notifications_outlined,
                          'Notificaciones',
                          'Configura avisos y rangos de tus favoritas.',
                          const _Notifications(),
                        ),
                        const Divider(color: Colors.white24, height: 30),
                        _option(
                          context,
                          Icons.tune_outlined,
                          'Preferencias de medición',
                          'Consulta las unidades de cada medición.',
                          const _MeasurementPreferences(),
                        ),
                        const Divider(color: Colors.white24, height: 30),
                        _option(
                          context,
                          Icons.help_outline,
                          'Ayuda y soporte',
                          'Entiende las mediciones y reporta problemas.',
                          const _Help(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AulaStyle.lightPurple,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        settings.signOut();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(),
                          ),
                          (_) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AulaNavigation(
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
            return;
          }
          final Widget screen = switch (index) {
            1 => const ZonesScreen(),
            2 => const ChartsScreen(),
            _ => const AIAnalysisScreen(),
          };
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => screen),
          );
        },
      ),
    );
  }

  Widget _option(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Widget section,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _open(context, title, section),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AulaStyle.lightPurple, size: 26),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    ),
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AulaStyle.background,
    appBar: AppBar(
      backgroundColor: AulaStyle.background,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: child,
        ),
      ),
    ),
  );
}

class _EditProfile extends StatefulWidget {
  const _EditProfile();
  @override
  State<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<_EditProfile> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: ProfileSettings.instance.name);
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nombre completo',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
            filled: true,
            fillColor: AulaStyle.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Ingresa tu nombre'
              : null,
        ),
        const SizedBox(height: 18),
        Text(
          ProfileSettings.instance.email,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        const Text(
          'El correo identifica tu sesión de demostración.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 25),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: AulaStyle.button,
            onPressed: _saving
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    setState(() => _saving = true);
                    ProfileSettings.instance.name = _name.text.trim();
                    await ProfileSettings.instance.save();
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text(
              'Guardar cambios',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Favorites extends StatelessWidget {
  const _Favorites();
  @override
  Widget build(BuildContext context) {
    final settings = ProfileSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona tus zonas favoritas del aula.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          AulaCard(
            child: Column(
              children: ProfileSettings.zones.entries
                  .map(
                    (zone) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AulaStyle.purple,
                      title: Text(zone.value),
                      value: settings.favorites.contains(zone.key),
                      onChanged: (value) {
                        if (value == true) {
                          settings.favorites.add(zone.key);
                        } else {
                          settings.favorites.remove(zone.key);
                          if (settings.firstZone == zone.key) {
                            settings.firstZone = null;
                          }
                        }
                        settings.save();
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 25),
          DropdownButtonFormField<String>(
            key: ValueKey('${settings.firstZone}:${settings.favorites.join()}'),
            initialValue: settings.firstZone ?? '',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Mostrar primero al abrir la app',
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Orden predeterminado'),
              ),
              ...settings.favorites.map(
                (code) => DropdownMenuItem(
                  value: code,
                  child: Text(ProfileSettings.zones[code]!),
                ),
              ),
            ],
            onChanged: (value) {
              settings.firstZone = value == '' ? null : value;
              settings.save();
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'La zona elegida aparecerá primero en Inicio.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Notifications extends StatelessWidget {
  const _Notifications();
  @override
  Widget build(BuildContext context) {
    final s = ProfileSettings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avisos en Inicio mientras la app está abierta. Se revisan las zonas favoritas cada 30 segundos.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (s.favorites.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Agrega una zona en Aulas favoritas para recibir avisos.',
              style: TextStyle(color: AulaStyle.lightPurple, fontSize: 14),
            ),
          ],
          const SizedBox(height: 20),
          AulaCard(
            child: Column(
              children: [
                _range(
                  'Temperatura',
                  Icons.thermostat,
                  s.temperatureAlerts,
                  (v) => s.temperatureAlerts = v,
                  s.minTemperature,
                  s.maxTemperature,
                  0,
                  50,
                  '°C',
                  (v) {
                    s.minTemperature = v.start;
                    s.maxTemperature = v.end;
                  },
                ),
                const Divider(color: Colors.white24, height: 30),
                _range(
                  'Humedad relativa',
                  Icons.water_drop_outlined,
                  s.humidityAlerts,
                  (v) => s.humidityAlerts = v,
                  s.minHumidity,
                  s.maxHumidity,
                  0,
                  100,
                  '%',
                  (v) {
                    s.minHumidity = v.start;
                    s.maxHumidity = v.end;
                  },
                ),
                const Divider(color: Colors.white24, height: 30),
                _range(
                  'Iluminación',
                  Icons.wb_sunny_outlined,
                  s.lightAlerts,
                  (v) => s.lightAlerts = v,
                  s.minLight,
                  s.maxLight,
                  0,
                  2000,
                  'lx',
                  (v) {
                    s.minLight = v.start;
                    s.maxLight = v.end;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _range(
    String title,
    IconData icon,
    bool enabled,
    ValueChanged<bool> toggle,
    double low,
    double high,
    double min,
    double max,
    String unit,
    ValueChanged<RangeValues> change,
  ) {
    final s = ProfileSettings.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icon, color: AulaStyle.lightPurple),
          title: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          value: enabled,
          activeThumbColor: AulaStyle.lightPurple,
          onChanged: (value) {
            toggle(value);
            s.save();
          },
        ),
        Text(
          'Rango: ${low.round()}–${high.round()} $unit',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        RangeSlider(
          values: RangeValues(low, high),
          min: min,
          max: max,
          divisions: 100,
          activeColor: AulaStyle.lightPurple,
          labels: RangeLabels('${low.round()} $unit', '${high.round()} $unit'),
          onChanged: enabled
              ? (value) {
                  change(value);
                  s.notifyRangeChanged();
                }
              : null,
          onChangeEnd: enabled ? (_) => s.save() : null,
        ),
      ],
    );
  }
}

class _MeasurementPreferences extends StatelessWidget {
  const _MeasurementPreferences();
  @override
  Widget build(BuildContext context) => const AulaCard(
    child: Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.thermostat, color: AulaStyle.lightPurple),
          title: Text('Temperatura'),
          subtitle: Text('Grados Celsius (°C) · unidad disponible'),
        ),
        Divider(color: Colors.white24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.water_drop_outlined,
            color: AulaStyle.lightPurple,
          ),
          title: Text('Humedad relativa'),
          subtitle: Text('Porcentaje (%)'),
        ),
        Divider(color: Colors.white24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.wb_sunny_outlined, color: AulaStyle.lightPurple),
          title: Text('Iluminación'),
          subtitle: Text('Lux (lx)'),
        ),
      ],
    ),
  );
}

class _Help extends StatelessWidget {
  const _Help();
  @override
  Widget build(BuildContext context) => const AulaCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HelpEntry(
          'Temperatura',
          'Indica qué tan cálido o frío está el ambiente. Se muestra en °C.',
        ),
        Divider(color: Colors.white24, height: 30),
        _HelpEntry(
          'Humedad relativa',
          'Es el porcentaje de vapor de agua en el aire respecto al máximo que puede contener a esa temperatura.',
        ),
        Divider(color: Colors.white24, height: 30),
        _HelpEntry(
          'Iluminación',
          'Mide la luz que llega al sensor en lux (lx). Un valor mayor indica más luz.',
        ),
        Divider(color: Colors.white24, height: 30),
        _HelpEntry(
          'Reportar un problema',
          'Anota la zona, la fecha y la hora. Incluye una captura y describe qué ocurrió. Entrega estos datos al responsable de AulaSense de tu institución.',
        ),
        Divider(color: Colors.white24, height: 30),
        _HelpEntry(
          '¿No se actualizan los datos?',
          'Comprueba tu conexión y pulsa Actualizar en Inicio. Las lecturas, gráficas y el historial se consultan en las pantallas de monitoreo.',
        ),
      ],
    ),
  );
}

class _HelpEntry extends StatelessWidget {
  const _HelpEntry(this.title, this.description);
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        description,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    ],
  );
}
