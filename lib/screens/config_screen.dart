import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistente_pl/state/app_state.dart';
import 'package:asistente_pl/state/theme_state.dart';
import 'package:asistente_pl/theme/app_colors.dart';
import 'package:asistente_pl/widgets/common_widgets.dart';
import 'package:asistente_pl/config.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _nombreCtrl = TextEditingController();
  final _rubroCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  bool _perfilCargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_perfilCargado) {
      final perfil = context.read<AppState>().perfilEmpresa;
      if (perfil != null) {
        _nombreCtrl.text = perfil['nombre'] ?? '';
        _rubroCtrl.text = perfil['rubro'] ?? '';
        _ciudadCtrl.text = perfil['ciudad'] ?? '';
      }
      _perfilCargado = true;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rubroCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  void _guardarPerfil() {
    final state = context.read<AppState>();
    state.guardarPerfil({
      'nombre': _nombreCtrl.text.trim(),
      'rubro': _rubroCtrl.text.trim(),
      'ciudad': _ciudadCtrl.text.trim(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil guardado correctamente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _limpiarDatos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar todos los datos'),
        content: const Text(
          '¿Estás seguro? Se eliminarán todos los modelos guardados, '
          'el historial de conversación y tu perfil. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().db.limpiarTodo();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos eliminados'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeState>();
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Apariencia ────────────────────────────────────────
          const SectionHeader(
            title: 'Apariencia',
            subtitle: 'Personaliza el aspecto de la aplicación',
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _OpcionTema(
                  titulo: 'Tema oscuro',
                  icono: Icons.dark_mode,
                  seleccionado: themeState.mode == ThemeMode.dark,
                  onTap: () => themeState.setMode(ThemeMode.dark),
                ),
                const Divider(height: 1),
                _OpcionTema(
                  titulo: 'Tema claro',
                  icono: Icons.light_mode,
                  seleccionado: themeState.mode == ThemeMode.light,
                  onTap: () => themeState.setMode(ThemeMode.light),
                ),
                const Divider(height: 1),
                _OpcionTema(
                  titulo: 'Automático (sistema)',
                  icono: Icons.brightness_auto,
                  seleccionado: themeState.mode == ThemeMode.system,
                  onTap: () => themeState.setMode(ThemeMode.system),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Modo de uso ───────────────────────────────────────
          const SectionHeader(
            title: 'Modo de uso',
            subtitle: 'Ajusta la experiencia según tus necesidades',
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.store,
                    color: isDark ? AppColors.turquesa : AppColors.turquesaOscuro,
                  ),
                  title: const Text('Mi negocio'),
                  subtitle: const Text(
                    'Recomendaciones claras y directas para tu empresa',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Radio<String>(
                    value: 'negocio',
                    groupValue: appState.esEstudiante ? 'estudiante' : 'negocio',
                    onChanged: (v) => appState.setModo(v!),
                    activeColor: AppColors.turquesa,
                  ),
                  onTap: () => appState.setModo('negocio'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.school,
                    color: isDark ? AppColors.turquesa : AppColors.turquesaOscuro,
                  ),
                  title: const Text('Estudiante'),
                  subtitle: const Text(
                    'Muestra el paso a paso del método Simplex y detalles técnicos',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Radio<String>(
                    value: 'estudiante',
                    groupValue: appState.esEstudiante ? 'estudiante' : 'negocio',
                    onChanged: (v) => appState.setModo(v!),
                    activeColor: AppColors.turquesa,
                  ),
                  onTap: () => appState.setModo('estudiante'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Perfil de empresa ─────────────────────────────────
          const SectionHeader(
            title: 'Perfil de empresa',
            subtitle: 'Ayuda al asistente a entender mejor tu contexto',
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  TextField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de tu negocio',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rubroCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Rubro o industria',
                      prefixIcon: Icon(Icons.category),
                      hintText: 'Ej: Textiles, Alimentos, Transporte...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ciudadCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      prefixIcon: Icon(Icons.location_city),
                      hintText: 'Ej: Juliaca, Puno...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarPerfil,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar perfil'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Estado de conexiones ──────────────────────────────
          const SectionHeader(
            title: 'Servicios conectados',
            subtitle: 'Estado de las integraciones',
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _EstadoServicio(
                  nombre: 'Supabase',
                  descripcion: 'Autenticación y datos en la nube',
                  conectado: AppConfig.supabaseUrl != 'TU_SUPABASE_URL',
                  icono: Icons.cloud,
                ),
                const Divider(height: 1),
                _EstadoServicio(
                  nombre: 'Gemini AI',
                  descripcion: 'Inteligencia artificial conversacional',
                  conectado: AppConfig.geminiApiKey != 'TU_GEMINI_API_KEY',
                  icono: Icons.auto_awesome,
                ),
                const Divider(height: 1),
                _EstadoServicio(
                  nombre: 'Reconocimiento de voz',
                  descripcion: 'Entrada por voz offline (Vosk)',
                  conectado: false,
                  icono: Icons.mic,
                ),
                const Divider(height: 1),
                _EstadoServicio(
                  nombre: 'Síntesis de voz',
                  descripcion: 'Lectura de resultados en voz alta',
                  conectado: AppConfig.supabaseUrl != 'TU_SUPABASE_URL',
                  icono: Icons.record_voice_over,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Datos ─────────────────────────────────────────────
          const SectionHeader(
            title: 'Datos',
            subtitle: 'Gestiona la información almacenada',
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.save_alt,
                      color: isDark ? AppColors.azul : Colors.blue[700]),
                  title: const Text('Modelos guardados'),
                  subtitle: Text(
                    '${appState.modelosGuardados.length} modelo(s)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => appState.setTab(1),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.coral),
                  title: const Text('Limpiar todos los datos'),
                  subtitle: const Text(
                    'Elimina modelos, historial y perfil',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: _limpiarDatos,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Acerca de ─────────────────────────────────────────
          const SectionHeader(
            title: 'Acerca de',
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.turquesa,
                          AppColors.turquesaOscuro,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_graph,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Asistente de Decisiones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versión 1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Optimiza las decisiones de tu negocio con '
                    'programación lineal e inteligencia artificial. '
                    'Diseñado para emprendedores y estudiantes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InfoPill(
                        icono: Icons.calculate,
                        texto: 'Simplex',
                      ),
                      const SizedBox(width: 8),
                      _InfoPill(
                        icono: Icons.auto_awesome,
                        texto: 'Gemini AI',
                      ),
                      const SizedBox(width: 8),
                      _InfoPill(
                        icono: Icons.mic,
                        texto: 'Voz',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Universidad Peruana Unión\nIngeniería de Sistemas\n2024',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary.withAlpha(150)
                          : AppColors.lightTextSecondary.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────

class _OpcionTema extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionTema({
    required this.titulo,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icono,
        color: seleccionado
            ? (isDark ? AppColors.turquesa : AppColors.turquesaOscuro)
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      ),
      title: Text(titulo),
      trailing: seleccionado
          ? Icon(Icons.check_circle,
              color: isDark ? AppColors.turquesa : AppColors.turquesaOscuro)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}

class _EstadoServicio extends StatelessWidget {
  final String nombre;
  final String descripcion;
  final bool conectado;
  final IconData icono;

  const _EstadoServicio({
    required this.nombre,
    required this.descripcion,
    required this.conectado,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icono,
        color: isDark ? AppColors.turquesa : AppColors.turquesaOscuro,
      ),
      title: Text(nombre),
      subtitle: Text(
        descripcion,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: StatusChip(
        label: conectado ? 'Conectado' : 'Pendiente',
        color: conectado ? AppColors.semaforoVerde : AppColors.ambar,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _InfoPill({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.turquesa.withAlpha(20)
            : AppColors.turquesaOscuro.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.turquesa.withAlpha(50)
              : AppColors.turquesaOscuro.withAlpha(30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 14,
            color: isDark ? AppColors.turquesa : AppColors.turquesaOscuro,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.turquesa : AppColors.turquesaOscuro,
            ),
          ),
        ],
      ),
    );
  }
}