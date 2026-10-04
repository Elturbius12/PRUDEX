import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:asistente_pl/state/app_state.dart';
import 'package:asistente_pl/theme/app_colors.dart';
import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/widgets/common_widgets.dart';

class ResultadosScreen extends StatelessWidget {
  const ResultadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultado = state.resultadoActual;
    final modelo = state.modeloActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: [
          if (resultado != null)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () {
                final texto = resultado.explicacionSimple ?? 'Sin resultado.';
                state.voice.hablar(texto);
              },
              tooltip: 'Escuchar resultado',
            ),
          if (resultado != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Exportar CSV
                if (modelo != null) {
                  final csv = state.excel.exportarCSV(resultado, modelo);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resultado copiado')),
                  );
                }
              },
              tooltip: 'Exportar',
            ),
        ],
      ),
      body: resultado == null
          ? _EmptyState(isDark: isDark)
          : state.resolviendo
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Recomendación rápida (5 segundos) ──────
                      if (modelo != null) _RecomendacionCard(modelo: modelo, resultado: resultado),
                      const SizedBox(height: 16),

                      // ── Valores de las variables ───────────────
                      SectionHeader(title: 'Solución óptima'),
                      _BarraVariables(resultado: resultado, isDark: isDark),
                      const SizedBox(height: 20),

                      // ── Restricciones ──────────────────────────
                      if (resultado.preciosSombra != null && modelo != null) ...[
                        SectionHeader(title: 'Uso de recursos'),
                        _TablaRestricciones(
                          modelo: modelo,
                          resultado: resultado,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Sensibilidad ───────────────────────────
                      if (resultado.sensibilidad != null) ...[
                        SectionHeader(title: 'Análisis de sensibilidad'),
                        _TablaSensibilidad(
                          sensibilidad: resultado.sensibilidad!,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Explicación detallada ──────────────────
                      if (state.esEstudiante && resultado.pasos.isNotEmpty) ...[
                        SectionHeader(title: 'Traza del Simplex'),
                        _TrazaSimplex(pasos: resultado.pasos, isDark: isDark),
                        const SizedBox(height: 20),
                      ],

                      // ── Monte Carlo ────────────────────────────
                      if (modelo != null) ...[
                        SectionHeader(title: 'Simulación de robustez'),
                        _BotonMonteCarlo(modelo: modelo, state: state),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}

// ── Estado vacío ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights, size: 56,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          const SizedBox(height: 12),
          Text(
            'Aún no hay resultados',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crea o importa un modelo para ver la solución',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de recomendación (UX de 5 segundos) ─────────────────────

class _RecomendacionCard extends StatelessWidget {
  final ProblemaLP modelo;
  final ResultadoLP resultado;

  const _RecomendacionCard({required this.modelo, required this.resultado});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final rec = state.explicaciones.generarRecomendacion(modelo, resultado);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.turquesa.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_graph, color: AppColors.turquesa, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Decisión recomendada',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          // Decisión
          Text(
            rec.decision,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
          ),
          const SizedBox(height: 8),
          // Impacto
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.ambar, size: 18),
              const SizedBox(width: 6),
              Text(rec.impacto,
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.ambar, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          // Confianza
          SemaforoIndicator(confianza: rec.confianza),
          const SizedBox(height: 12),
          // Explicación
          Text(
            rec.explicacion,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gráfico de barras de variables ──────────────────────────────────

class _BarraVariables extends StatelessWidget {
  final ResultadoLP resultado;
  final bool isDark;

  const _BarraVariables({required this.resultado, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final vals = resultado.valoresVariables;
    if (vals.isEmpty) return const SizedBox.shrink();

    final entries = vals.entries.toList();
    final maxVal = vals.values.fold(0.0, (m, v) => v > m ? v : m);

    return AppCard(
      child: Column(
        children: entries.map((e) {
          final pct = maxVal > 0 ? e.value / maxVal : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(e.value.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                AppProgressBar(
                  value: pct,
                  color: e.value > 0.001 ? AppColors.turquesa : AppColors.darkTextMuted,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Tabla de restricciones ──────────────────────────────────────────

class _TablaRestricciones extends StatelessWidget {
  final ProblemaLP modelo;
  final ResultadoLP resultado;
  final bool isDark;

  const _TablaRestricciones({
    required this.modelo,
    required this.resultado,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 40,
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Recurso', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
            DataColumn(label: Text('Disponible', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
            DataColumn(label: Text('Precio sombra', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
            DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          ],
          rows: List.generate(modelo.restricciones.length, (i) {
            final r = modelo.restricciones[i];
            final ps = i < (resultado.preciosSombra?.length ?? 0)
                ? resultado.preciosSombra![i]
                : 0.0;
            final activa = ps.abs() > 0.001;

            return DataRow(cells: [
              DataCell(Text(r.nombre, style: const TextStyle(fontSize: 12))),
              DataCell(Text(r.rhs.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
              DataCell(Text(ps.toStringAsFixed(4), style: const TextStyle(fontSize: 12))),
              DataCell(StatusChip(
                label: activa ? 'Activa' : 'Holgura',
                color: activa ? AppColors.ambar : AppColors.turquesa,
                icon: activa ? Icons.warning_amber : Icons.check_circle_outline,
              )),
            ]);
          }),
        ),
      ),
    );
  }
}

// ── Tabla de sensibilidad ───────────────────────────────────────────

class _TablaSensibilidad extends StatelessWidget {
  final AnalisisSensibilidad sensibilidad;
  final bool isDark;

  const _TablaSensibilidad({required this.sensibilidad, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rangos de coeficientes objetivo',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 32,
              dataRowMinHeight: 28,
              dataRowMaxHeight: 36,
              columnSpacing: 14,
              columns: const [
                DataColumn(label: Text('Variable', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Actual', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Mínimo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Máximo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              ],
              rows: sensibilidad.rangosObjetivo.map((r) => DataRow(cells: [
                    DataCell(Text(r.variable, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(r.valorActual.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(r.limiteInferior.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(r.limiteSuperior.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                  ])).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Traza Simplex (modo estudiante) ─────────────────────────────────

class _TrazaSimplex extends StatelessWidget {
  final List<PasoSimplex> pasos;
  final bool isDark;

  const _TrazaSimplex({required this.pasos, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...pasos.take(10).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Iteración ${p.iteracion}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.explicacion,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (p.entrante != null)
                      Text(
                        'Pivote: ${p.pivote?.toStringAsFixed(4) ?? "-"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    const Divider(height: 16),
                  ],
                ),
              )),
          if (pasos.length > 10)
            Text(
              '... y ${pasos.length - 10} pasos más',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Botón Monte Carlo ───────────────────────────────────────────────

class _BotonMonteCarlo extends StatefulWidget {
  final ProblemaLP modelo;
  final AppState state;

  const _BotonMonteCarlo({required this.modelo, required this.state});

  @override
  State<_BotonMonteCarlo> createState() => _BotonMonteCarloState();
}

class _BotonMonteCarloState extends State<_BotonMonteCarlo> {
  ResultadoMonteCarlo? _mc;
  bool _simulando = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (_mc == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _simulando ? null : _simular,
              icon: _simulando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.casino),
              label: Text(_simulando ? 'Simulando...' : 'Ejecutar Monte Carlo (500 escenarios)'),
            ),
          ),
        if (_mc != null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.casino, color: AppColors.azul, size: 18),
                    const SizedBox(width: 8),
                    const Text('Simulación Monte Carlo',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                _DatoMC('Valor esperado', _mc!.mediaObjetivo.toStringAsFixed(2)),
                _DatoMC('Desviación estándar', _mc!.desviacionEstandar.toStringAsFixed(2)),
                _DatoMC('Rango 90%',
                    '${_mc!.percentil5.toStringAsFixed(2)} — ${_mc!.percentil95.toStringAsFixed(2)}'),
                _DatoMC('Prob. factible',
                    '${(_mc!.probabilidadFactible * 100).toStringAsFixed(0)}%'),
                const SizedBox(height: 12),
                SemaforoIndicator(confianza: _mc!.probabilidadFactible),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _simular() async {
    setState(() => _simulando = true);
    await Future.delayed(const Duration(milliseconds: 50));
    final mc = widget.state.solver.simularMonteCarlo(widget.modelo);
    setState(() {
      _mc = mc;
      _simulando = false;
    });
  }
}

class _DatoMC extends StatelessWidget {
  final String label;
  final String valor;
  const _DatoMC(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
