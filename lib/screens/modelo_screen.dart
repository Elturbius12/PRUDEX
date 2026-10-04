import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:asistente_pl/state/app_state.dart';
import 'package:asistente_pl/theme/app_colors.dart';
import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/widgets/common_widgets.dart';
import 'package:asistente_pl/core/solver_engine.dart';

class ModeloScreen extends StatefulWidget {
  const ModeloScreen({super.key});

  @override
  State<ModeloScreen> createState() => _ModeloScreenState();
}

class _ModeloScreenState extends State<ModeloScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Constructor de Modelos'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: isDark ? AppColors.turquesa : AppColors.turquesaOscuro,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          indicatorColor: isDark ? AppColors.turquesa : AppColors.turquesaOscuro,
          tabs: const [
            Tab(text: 'Nuevo', icon: Icon(Icons.add_circle_outline, size: 20)),
            Tab(text: 'Guardados', icon: Icon(Icons.folder_open, size: 20)),
            Tab(text: 'Importar', icon: Icon(Icons.upload_file, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _NuevoModeloTab(),
          _ModelosGuardadosTab(),
          _ImportarTab(),
        ],
      ),
    );
  }
}

// ── Tab: Nuevo Modelo ────────────────────────────────────────────────

class _NuevoModeloTab extends StatefulWidget {
  @override
  State<_NuevoModeloTab> createState() => _NuevoModeloTabState();
}

class _NuevoModeloTabState extends State<_NuevoModeloTab> {
  final _nombreCtrl = TextEditingController(text: 'Mi modelo');
  TipoObjetivo _objetivo = TipoObjetivo.maximizar;
  MetodoSolucion? _metodo;
  final _variables = <_VarTemp>[_VarTemp('x1', 0)];
  final _restricciones = <_ResTemp>[];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _agregarVariable() {
    setState(() {
      _variables.add(_VarTemp('x${_variables.length + 1}', 0));
      // Ajustar coeficientes de restricciones
      for (final r in _restricciones) {
        r.coefs.add(0);
      }
    });
  }

  void _agregarRestriccion() {
    setState(() {
      _restricciones.add(_ResTemp(
        'R${_restricciones.length + 1}',
        List.filled(_variables.length, 0.0),
        TipoRestriccion.menorIgual,
        0,
      ));
    });
  }

  void _resolver() {
    final state = context.read<AppState>();
    final vars = _variables
        .map((v) => VariableLP(nombre: v.nombre, coeficienteObjetivo: v.coef))
        .toList();
    final rest = _restricciones.map((r) => RestriccionLP(
          nombre: r.nombre,
          coeficientes: List<double>.from(r.coefs),
          tipo: r.tipo,
          rhs: r.rhs,
        )).toList();

    final modelo = ProblemaLP(
      nombre: _nombreCtrl.text,
      objetivo: _objetivo,
      variables: vars,
      restricciones: rest,
      metodoPreferido: _metodo,
    );

    state.setModelo(modelo);
    state.resolverModelo().then((_) {
      state.setTab(2); // Ir a resultados
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final engine = SolverEngine();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del modelo',
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 16),

          // Objetivo
          SectionHeader(title: 'Objetivo'),
          Row(
            children: [
              Expanded(
                child: _SelectionChip(
                  label: 'Maximizar',
                  icon: Icons.trending_up,
                  selected: _objetivo == TipoObjetivo.maximizar,
                  onTap: () => setState(() => _objetivo = TipoObjetivo.maximizar),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SelectionChip(
                  label: 'Minimizar',
                  icon: Icons.trending_down,
                  selected: _objetivo == TipoObjetivo.minimizar,
                  onTap: () => setState(() => _objetivo = TipoObjetivo.minimizar),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Método
          SectionHeader(title: 'Método de solución', subtitle: 'Opcional — se detecta automáticamente'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetodoChip(
                label: 'Automático',
                selected: _metodo == null,
                onTap: () => setState(() => _metodo = null),
              ),
              ...engine.metodosDisponibles().map((m) => _MetodoChip(
                    label: m.nombre,
                    selected: _metodo == m.metodo,
                    onTap: () => setState(() => _metodo = m.metodo),
                  )),
            ],
          ),
          const SizedBox(height: 24),

          // Variables
          SectionHeader(
            title: 'Variables de decisión',
            trailing: IconButton(
              onPressed: _agregarVariable,
              icon: const Icon(Icons.add_circle, color: AppColors.turquesa),
            ),
          ),
          ...List.generate(_variables.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (v) => _variables[i].nombre = v,
                      controller: TextEditingController(text: _variables[i].nombre),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Coef. Z',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      onChanged: (v) => _variables[i].coef = double.tryParse(v) ?? 0,
                    ),
                  ),
                  if (_variables.length > 1)
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: AppColors.coral, size: 20),
                      onPressed: () {
                        setState(() {
                          _variables.removeAt(i);
                          for (final r in _restricciones) {
                            if (i < r.coefs.length) r.coefs.removeAt(i);
                          }
                        });
                      },
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Restricciones
          SectionHeader(
            title: 'Restricciones',
            trailing: IconButton(
              onPressed: _agregarRestriccion,
              icon: const Icon(Icons.add_circle, color: AppColors.turquesa),
            ),
          ),
          if (_restricciones.isEmpty)
            InfoCallout(
              text: 'Agrega restricciones que representen los límites de tus recursos (materiales, tiempo, presupuesto).',
            ),
          ...List.generate(_restricciones.length, (i) {
            final r = _restricciones[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Nombre restricción',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            controller: TextEditingController(text: r.nombre),
                            onChanged: (v) => r.nombre = v,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.coral, size: 20),
                          onPressed: () => setState(() => _restricciones.removeAt(i)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Coeficientes
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...List.generate(_variables.length, (j) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: _variables[j].nombre,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                    onChanged: (v) {
                                      if (j < r.coefs.length) {
                                        r.coefs[j] = double.tryParse(v) ?? 0;
                                      }
                                    },
                                  ),
                                ),
                                if (j < _variables.length - 1)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Text('+'),
                                  ),
                              ],
                            );
                          }),
                          // Tipo de restricción
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButton<TipoRestriccion>(
                              value: r.tipo,
                              underline: const SizedBox(),
                              isDense: true,
                              items: const [
                                DropdownMenuItem(value: TipoRestriccion.menorIgual, child: Text('≤')),
                                DropdownMenuItem(value: TipoRestriccion.mayorIgual, child: Text('≥')),
                                DropdownMenuItem(value: TipoRestriccion.igual, child: Text('=')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => r.tipo = v);
                              },
                            ),
                          ),
                          // RHS
                          SizedBox(
                            width: 70,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Valor',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => r.rhs = double.tryParse(v) ?? 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Botón resolver
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _variables.isNotEmpty && _restricciones.isNotEmpty ? _resolver : null,
              icon: const Icon(Icons.calculate),
              label: const Text('Resolver modelo'),
            ),
          ),
          const SizedBox(height: 16),

          // Botón guardar
          if (_variables.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  final state = context.read<AppState>();
                  final vars = _variables
                      .map((v) => VariableLP(nombre: v.nombre, coeficienteObjetivo: v.coef))
                      .toList();
                  final rest = _restricciones.map((r) => RestriccionLP(
                        nombre: r.nombre,
                        coeficientes: List<double>.from(r.coefs),
                        tipo: r.tipo,
                        rhs: r.rhs,
                      )).toList();
                  state.setModelo(ProblemaLP(
                    nombre: _nombreCtrl.text,
                    objetivo: _objetivo,
                    variables: vars,
                    restricciones: rest,
                    metodoPreferido: _metodo,
                  ));
                  state.guardarModeloActual();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Modelo guardado')),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar modelo'),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab: Modelos Guardados ───────────────────────────────────────────

class _ModelosGuardadosTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final modelos = state.modelosGuardados;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (modelos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 56,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            const SizedBox(height: 12),
            Text(
              'No tienes modelos guardados',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: modelos.length,
      itemBuilder: (context, i) {
        final m = modelos[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            onTap: () {
              state.cargarModelo(m);
              state.resolverModelo().then((_) => state.setTab(2));
            },
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.turquesa.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.functions, color: AppColors.turquesa),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${m.numVariables} variables, ${m.numRestricciones} restricciones',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => state.eliminarModelo(m.nombre),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tab: Importar ────────────────────────────────────────────────────

class _ImportarTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.upload_file, size: 64,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          const SizedBox(height: 16),
          Text(
            'Importar datos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sube un archivo Excel (.xlsx) o CSV con los datos de tu modelo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _importar(context),
              icon: const Icon(Icons.file_open),
              label: const Text('Seleccionar archivo'),
            ),
          ),
          const SizedBox(height: 24),
          InfoCallout(
            text: 'Tu archivo debe tener columnas como: Variable/Producto, '
                'Ganancia/Costo, y las restricciones con sus límites.',
          ),
        ],
      ),
    );
  }

  Future<void> _importar(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    final state = context.read<AppState>();
    final path = result.files.single.path;
    if (path == null) return;

    final datos = await state.excel.importar(path);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(datos.mensaje)),
    );

    // Si se detectó un modelo, cargarlo
    final modelo = state.excel.convertirAModelo(datos);
    if (modelo != null) {
      state.setModelo(modelo);
    } else {
      // Enviar al chat para interpretación
      state.enviarMensaje(
        'Importé un archivo con ${datos.filas.length} registros. '
        'Columnas: ${datos.encabezados.join(", ")}. '
        '${datos.mensaje}',
      );
      state.setTab(0); // Ir al chat
    }
  }
}

// ── Helpers ──────────────────────────────────────────────────────────

class _VarTemp {
  String nombre;
  double coef;
  _VarTemp(this.nombre, this.coef);
}

class _ResTemp {
  String nombre;
  List<double> coefs;
  TipoRestriccion tipo;
  double rhs;
  _ResTemp(this.nombre, this.coefs, this.tipo, this.rhs);
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.turquesa.withAlpha(20) : AppColors.turquesaOscuro.withAlpha(15))
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? (isDark ? AppColors.turquesa : AppColors.turquesaOscuro)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18,
                color: selected
                    ? (isDark ? AppColors.turquesa : AppColors.turquesaOscuro)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? (isDark ? AppColors.turquesa : AppColors.turquesaOscuro)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetodoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetodoChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.turquesa.withAlpha(25) : AppColors.turquesaOscuro.withAlpha(15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? (isDark ? AppColors.turquesa : AppColors.turquesaOscuro)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? (isDark ? AppColors.turquesa : AppColors.turquesaOscuro)
                : null,
          ),
        ),
      ),
    );
  }
}
