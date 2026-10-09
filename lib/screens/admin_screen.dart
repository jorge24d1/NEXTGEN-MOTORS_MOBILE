import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:highcharts_flutter/highcharts.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _nombre = "Admin";
  String _rol = "ADMINISTRADOR";
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? "Admin";
      _rol = prefs.getString('role') ?? "ADMINISTRADOR";
    });
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Panel de Administración",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "$_nombre · $_rol",
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: "Cerrar sesión",
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _PowerBIView(),
          _AdvancedChartsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white54,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: "PowerBI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: "Avanzados",
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  VISTA 1: Gráficos de PowerBI
// ─────────────────────────────────────────────
class _PowerBIView extends StatelessWidget {
  const _PowerBIView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_outline,
                size: 70,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Reportes PowerBI",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Aquí se integrarán los tableros y dashboards interactivos de Microsoft PowerBI para análisis empresarial.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Actualizando conexión con PowerBI..."),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Actualizar Tableros"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  VISTA 2: Gráficos Avanzados (Highcharts Funnel)
// ─────────────────────────────────────────────
class _AdvancedChartsView extends StatefulWidget {
  const _AdvancedChartsView();

  @override
  State<_AdvancedChartsView> createState() => _AdvancedChartsViewState();
}

class _AdvancedChartsViewState extends State<_AdvancedChartsView> {
  bool _loading = true;
  String _error = '';
  int _total = 0;
  int _conInteres = 0;
  int _citaAprobada = 0;
  int _clientePotencial = 0;

  static const String _baseUrl =
      'https://sage-unrefusable-tearingly.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _fetchEmbudoData();
  }

  Future<void> _fetchEmbudoData() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/prediccion/embudo'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final rawBody = response.body.trim();
        if (rawBody.startsWith('<')) {
          setState(() {
            _error = 'El servidor devolvió HTML en vez de datos JSON. Reinicia el servidor Spring Boot para aplicar los permisos de seguridad.';
            _loading = false;
          });
          return;
        }
        final data = json.decode(rawBody);
        setState(() {
          _total = (data['total'] ?? 0) as int;
          _conInteres = (data['conInteres'] ?? 0) as int;
          _citaAprobada = (data['citaAprobada'] ?? 0) as int;
          _clientePotencial = (data['clientePotencial'] ?? 0) as int;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error del servidor: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text('Cargando modelo predictivo...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchEmbudoData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Pipeline de $_total clientes — Modelo Predictivo (HTTP GET)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Gráfico de Embudo con Highcharts
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 380,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            clipBehavior: Clip.antiAlias,
            child: HighchartsChart(
              HighchartsOptions(
                title: HighchartsTitleOptions(
                  text: 'Pipeline de Clientes',
                  style: HighchartsTitleStyleOptions(
                    color: '#E6EDF3',
                    fontWeight: 'bold',
                  ),
                ),
                subtitle: HighchartsSubtitleOptions(
                  text: 'Fuente: Modelo Predictivo NEXTGEN MOTORS · $_total registros',
                  style: HighchartsSubtitleStyleOptions(
                    color: '#8B949E',
                    fontSize: '11px',
                  ),
                ),
                chart: HighchartsChartOptions(
                  backgroundColor: '#0D1117',
                ),
                legend: HighchartsLegendOptions(
                  enabled: true,
                  itemStyle: {
                    'color': '#C9D1D9',
                    'fontSize': '12px',
                    'fontWeight': 'normal',
                  },
                ),
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
          const SizedBox(height: 12),
          // Tarjetas métricas horizontales
          _buildSummaryCards(),
          const SizedBox(height: 12),
          // Botón actualizar datos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _fetchEmbudoData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualizar datos del modelo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final tarjetas = [
      _Metrica('Total', _total, '👥', const Color(0xFF58A6FF)),
      _Metrica('Interés', _conInteres, '🚗', const Color(0xFF3FB950)),
      _Metrica('Aprobadas', _citaAprobada, '✅', const Color(0xFFD2A8FF)),
      _Metrica('Potenciales', _clientePotencial, '⭐', const Color(0xFFF78166)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: tarjetas.map((m) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _TarjetaMetrica(metrica: m),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Modelos internos para métricas
// ─────────────────────────────────────────────
class _Metrica {
  final String etiqueta;
  final int valor;
  final String emoji;
  final Color color;

  const _Metrica(this.etiqueta, this.valor, this.emoji, this.color);
}

// ─────────────────────────────────────────────
//  Widget reutilizable: Tarjeta de métrica compacta
// ─────────────────────────────────────────────
class _TarjetaMetrica extends StatelessWidget {
  const _TarjetaMetrica({required this.metrica});
  final _Metrica metrica;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(metrica.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            '${metrica.valor}',
            style: TextStyle(
              color: metrica.color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metrica.etiqueta,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

