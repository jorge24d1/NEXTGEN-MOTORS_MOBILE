import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sesion_movil.dart';
import 'package:highcharts_flutter/highcharts.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../widgets/power_bi_view.dart';

// ─────────────────────────────────────────────
//  Paleta compartida
// ─────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const card = Color(0xFF161B22);
  static const border = Color(0xFF30363D);
  static const blue = Color(0xFF58A6FF);
  static const green = Color(0xFF3FB950);
  static const purple = Color(0xFFD2A8FF);
  static const orange = Color(0xFFF78166);
  static const textSoft = Colors.white60;
}

class AdminScreen extends StatefulWidget {
  final SesionMovil sesion;
  final VoidCallback salir;
  const AdminScreen({required this.sesion, required this.salir, super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  static const _titulos = ['Reportes', 'Modelo predictivo'];

  Future<void> _confirmarCerrarSesion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        title: const Text('Cerrar sesión',
            style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que deseas salir del panel?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir')),
        ],
      ),
    );
    if (ok == true && mounted) widget.salir();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.sesion.nombre;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _C.blue.withValues(alpha: 0.2),
              child: Text(inicial,
                  style: const TextStyle(
                      color: _C.blue, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titulos[_currentIndex],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$nombre · ${widget.sesion.role}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _C.textSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: "Cerrar sesión",
            onPressed: _confirmarCerrarSesion,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _PowerBIView(),
          _AdvancedChartsView(widget.sesion, widget.salir),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: _C.surface,
          indicatorColor: _C.blue.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? _C.blue : Colors.white54,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.dashboard_rounded, color: _C.blue),
              label: 'Power BI',
            ),
            NavigationDestination(
              icon: Icon(Icons.filter_alt_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.filter_alt_rounded, color: _C.blue),
              label: 'Predicciones',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  VISTA 1: Reportes (Power BI)
// ─────────────────────────────────────────────
const String _kPowerBiReportUrl =
    "https://app.powerbi.com/view?r=eyJrIjoiNTIyYjhkZGItYjVjOC00YjYwLWEyOWQtYTFkNGU2ZWI3MGNmIiwidCI6IjlkMTJiZjNmLWU0ZjYtNDdhYi05MTJmLTFhMmYwZmM0OGFhNCIsImMiOjR9";

class _PowerBIView extends StatelessWidget {
  const _PowerBIView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: PowerBiView(
        url: _kPowerBiReportUrl,
        alturaBarra: 56.0,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  VISTA 2: Modelo predictivo (embudo)
// ─────────────────────────────────────────────
class _AdvancedChartsView extends StatefulWidget {
  final SesionMovil sesion;
  final VoidCallback salir;
  const _AdvancedChartsView(this.sesion, this.salir);

  @override
  State<_AdvancedChartsView> createState() => _AdvancedChartsViewState();
}

class _AdvancedChartsViewState extends State<_AdvancedChartsView> {
  final ApiService _apiService = ApiService();

  bool _loading = true;
  bool _isFromCache = false;
  String _error = '';
  String? _cacheTimestamp;
  DateTime? _lastSync;
  int _total = 0;
  int _conInteres = 0;
  int _citaAprobada = 0;
  int _clientePotencial = 0;

  @override
  void initState() {
    super.initState();
    _fetchEmbudoData();
  }

  String _formatSyncTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      return DateFormat("d MMM, h:mm a").format(DateTime.parse(isoTime));
    } catch (_) {
      return '';
    }
  }

  /// Porcentaje de [parte] sobre [base], seguro ante división por cero.
  double _pct(int parte, int base) => base == 0 ? 0 : parte / base * 100;

  Future<void> _fetchEmbudoData() async {
    setState(() {
      _loading = true;
      _error = '';
      _isFromCache = false;
    });

    late final Map<String, dynamic> data;
    try {
      data = await _apiService.obtenerDatosEmbudo(widget.sesion);
    } on AccesoDenegado {
      if (mounted) widget.salir();
      return;
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Error al consultar el embudo'; });
      return;
    }

    if (!mounted) return;

    if (data['success'] == true) {
      final timestamp = await CacheService.getEmbudoCacheTimestamp(userId: widget.sesion.userId);
      if (!mounted) return;
      setState(() {
        _total = (data['total'] ?? 0) as int;
        _conInteres = (data['conInteres'] ?? 0) as int;
        _citaAprobada = (data['citaAprobada'] ?? 0) as int;
        _clientePotencial = (data['clientePotencial'] ?? 0) as int;
        _isFromCache = data['fromCache'] == true;
        _cacheTimestamp = timestamp;
        _lastSync = DateTime.now();
        _loading = false;
      });
    } else {
      setState(() {
        _error = data['message'] ?? 'Error al obtener los datos del embudo';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _EstadoCargando();
    if (_error.isNotEmpty) {
      return _EstadoError(mensaje: _error, onReintentar: _fetchEmbudoData);
    }

    return RefreshIndicator(
      color: _C.blue,
      backgroundColor: _C.surface,
      onRefresh: _fetchEmbudoData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _buildEncabezado(),
          const SizedBox(height: 14),
          _buildKpiGrid(),
          const SizedBox(height: 14),
          _buildFunnelCard(),
          const SizedBox(height: 14),
          _buildConversionCard(),
        ],
      ),
    );
  }

  // ── Encabezado con estado de sincronización ──
  Widget _buildEncabezado() {
    final offline = _isFromCache;
    final color = offline ? Colors.orange : _C.green;
    final texto = offline
        ? 'Sin conexión · ${_formatSyncTime(_cacheTimestamp)}'
        : 'En línea · ${_lastSync != null ? DateFormat('h:mm a').format(_lastSync!) : ''}';

    return Row(
      children: [
        Expanded(
          child: Text(
            'Pipeline de $_total clientes',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(offline ? Icons.wifi_off_rounded : Icons.circle,
                  size: offline ? 13 : 8, color: color),
              const SizedBox(width: 6),
              Text(texto, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          onPressed: _fetchEmbudoData,
        ),
      ],
    );
  }

  // ── KPIs 2x2 con % de conversión ──
  Widget _buildKpiGrid() {
    final kpis = [
      _Kpi('Total clientes', _total, Icons.groups_rounded, _C.blue,
          'Base del pipeline'),
      _Kpi('Con interés', _conInteres, Icons.directions_car_rounded, _C.green,
          '${_pct(_conInteres, _total).toStringAsFixed(0)}% del total'),
      _Kpi('Cita aprobada', _citaAprobada, Icons.event_available_rounded,
          _C.purple,
          '${_pct(_citaAprobada, _conInteres).toStringAsFixed(0)}% de interesados'),
      _Kpi('Potenciales', _clientePotencial, Icons.star_rounded, _C.orange,
          '${_pct(_clientePotencial, _citaAprobada).toStringAsFixed(0)}% de aprobadas'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: kpis.map((k) => _KpiCard(kpi: k)).toList(),
    );
  }

  // ── Embudo Highcharts dentro de una tarjeta ──
  Widget _buildFunnelCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text('Embudo de clientes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text('Fuente: Modelo Predictivo NEXTGEN MOTORS',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ),
          SizedBox(
            height: 320,
            child: HighchartsChart(
              HighchartsOptions(
                chart: HighchartsChartOptions(backgroundColor: '#0D1117'),
                legend: HighchartsLegendOptions(enabled: false),
                tooltip: HighchartsTooltipOptions(
                  backgroundColor: '#161B22',
                  borderColor: '#30363D',
                  style: HighchartsTooltipStyleOptions(
                    color: '#E6EDF3',
                    fontSize: '13px',
                  ),
                  pointFormat:
                      '<b>{point.name}</b><br/>Clientes: <b>{point.y}</b><br/>'
                      'Proporción: <b>{point.percentage:.1f}%</b>',
                ),
                series: [
                  HighchartsFunnelSeries(
                    name: 'Clientes',
                    data: [
                      ['Total de Clientes', _total.toDouble()],
                      ['Con Interés en Vehículo', _conInteres.toDouble()],
                      ['Última Cita Aprobada', _citaAprobada.toDouble()],
                      ['Cliente Potencial', _clientePotencial.toDouble()],
                    ],
                    options: HighchartsFunnelSeriesOptions(
                      neckWidth: '30%',
                      neckHeight: '25%',
                      width: '75%',
                      dataLabels: HighchartsFunnelSeriesDataLabelsOptions(
                        enabled: true,
                        color: '#C9D1D9',
                        format: '<b>{point.name}</b>: {point.y}',
                      ),
                    ),
                  ),
                ],
              ),
              javaScriptModules: const [
                'packages/highcharts_flutter/assets/highcharts/highcharts.js',
                'packages/highcharts_flutter/assets/highcharts/highcharts-more.js',
                'https://code.highcharts.com/modules/funnel.js',
                'packages/highcharts_flutter/assets/highcharts/modules/accessibility.js',
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Conversión entre etapas con barras de progreso ──
  Widget _buildConversionCard() {
    final pasos = [
      _Paso('Interés sobre total', _pct(_conInteres, _total), _C.green),
      _Paso('Aprobadas sobre interés', _pct(_citaAprobada, _conInteres),
          _C.purple),
      _Paso('Potenciales sobre aprobadas',
          _pct(_clientePotencial, _citaAprobada), _C.orange),
      _Paso('Conversión global', _pct(_clientePotencial, _total), _C.blue),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conversión entre etapas',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          for (final p in pasos) ...[
            Row(
              children: [
                Expanded(
                  child: Text(p.etiqueta,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ),
                Text('${p.valor.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: p.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (p.valor / 100).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(p.color),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Modelos y widgets auxiliares
// ─────────────────────────────────────────────
class _Kpi {
  final String etiqueta;
  final int valor;
  final IconData icono;
  final Color color;
  final String detalle;
  const _Kpi(this.etiqueta, this.valor, this.icono, this.color, this.detalle);
}

class _Paso {
  final String etiqueta;
  final double valor;
  final Color color;
  const _Paso(this.etiqueta, this.valor, this.color);
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});
  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kpi.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(kpi.icono, size: 16, color: kpi.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(kpi.etiqueta,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12)),
              ),
            ],
          ),
          Text('${kpi.valor}',
              style: TextStyle(
                  color: kpi.color,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          Text(kpi.detalle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EstadoCargando extends StatelessWidget {
  const _EstadoCargando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _C.blue),
          SizedBox(height: 16),
          Text('Cargando modelo predictivo...',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _EstadoError extends StatelessWidget {
  const _EstadoError({required this.mensaje, required this.onReintentar});
  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}