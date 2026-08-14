import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/analytics_service.dart';
import '../../widgets/loading_states.dart';
import '../../config/theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AnalyticsService _analytics = AnalyticsService();
  
  Map<String, dynamic>? _metricsSummary;
  List<Map<String, dynamic>>? _dailyMetrics;
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  final DateTime _endDate = DateTime.now();
  String _selectedPeriod = '30d';

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    
    try {
      final summary = await _analytics.getUserMetricsSummary(_startDate, _endDate);
      final daily = await _analytics.getDailyMetrics(30);
      
      setState(() {
        _metricsSummary = summary;
        _dailyMetrics = daily;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar métricas: $e')),
        );
      }
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case '7d':
          _startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case '30d':
          _startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case '90d':
          _startDate = DateTime.now().subtract(const Duration(days: 90));
          break;
      }
    });
    _loadMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Administración'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          _buildPeriodSelector(),
        ],
      ),
      body: _isLoading
          ? LoadingStates.fullPage(message: 'Cargando métricas...')
          : _buildDashboard(),
    );
  }

  Widget _buildPeriodSelector() {
    return DropdownButton<String>(
      value: _selectedPeriod,
      dropdownColor: Colors.white,
      iconEnabledColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      items: const [
        DropdownMenuItem(value: '7d', child: Text('7 días')),
        DropdownMenuItem(value: '30d', child: Text('30 días')),
        DropdownMenuItem(value: '90d', child: Text('90 días')),
      ],
      onChanged: (value) {
        if (value != null) _changePeriod(value);
      },
    );
  }

  Widget _buildDashboard() {
    if (_metricsSummary == null) {
      return ErrorStates.fullPage(
        message: 'No hay datos disponibles',
        onRetry: _loadMetrics,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildRegistrationsChart(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildDetailedMetrics(),
          const SizedBox(height: 24),
          _buildRegistrationsTable(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final registrations = _metricsSummary!['registrations'] as Map<String, dynamic>?;
    final revenue = _metricsSummary!['revenue'] as Map<String, dynamic>?;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Nuevos Usuarios',
            '${registrations?['total'] ?? 0}',
            Icons.person_add,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Ingresos Totales',
            '€${(revenue?['total_revenue'] ?? 0).toStringAsFixed(2)}',
            Icons.euro,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Compras',
            '${revenue?['total_purchases'] ?? 0}',
            Icons.shopping_cart,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Renovaciones',
            '${revenue?['renewals'] ?? 0}',
            Icons.autorenew,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationsChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registros Diarios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _dailyMetrics == null
                  ? const Center(child: CircularProgressIndicator())
                  : _RegistrationsChart(data: _dailyMetrics!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final revenue = _metricsSummary!['revenue'] as Map<String, dynamic>?;
    final revenueByPlan = revenue?['revenue_by_plan'] as Map<String, dynamic>?;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresos por Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (revenueByPlan != null && revenueByPlan.isNotEmpty)
              ...revenueByPlan.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(entry.key),
                      ),
                      Text(
                        '€${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              })
            else
              const Text('No hay datos de ingresos'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    final registrations = _metricsSummary!['registrations'] as Map<String, dynamic>?;
    final registrationsByType = registrations?['by_type'] as Map<String, dynamic>?;
    final revenue = _metricsSummary!['revenue'] as Map<String, dynamic>?;
    final retention = _metricsSummary!['retention'] as Map<String, dynamic>?;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Métricas Detalladas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (registrationsByType != null) ...[
              const Text(
                'Registros por Tipo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...registrationsByType.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text('${entry.value}'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            if (revenue != null) ...[
              const Text(
                'Métricas de Ingresos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildMetricRow('Nuevas Suscripciones', '${revenue['new_subscriptions'] ?? 0}'),
              _buildMetricRow('Renovaciones', '${revenue['renewals'] ?? 0}'),
              _buildMetricRow('Promedio por Compra', '€${(revenue['average_revenue_per_purchase'] ?? 0).toStringAsFixed(2)}'),
              const SizedBox(height: 16),
            ],
            if (retention != null) ...[
              const Text(
                'Retención de Usuarios',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildMetricRow('Usuarios Activos Diarios (DAU)', '${retention['dau'] ?? 0}'),
              _buildMetricRow('Usuarios Activos Semanales (WAU)', '${retention['wau'] ?? 0}'),
              _buildMetricRow('Usuarios Activos Mensuales (MAU)', '${retention['mau'] ?? 0}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationsTable() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Últimos Registros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _exportToCSV,
                  child: const Text('Exportar CSV'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _analytics.getRegistrationsByDateRange(_startDate, _endDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final registrations = snapshot.data ?? [];
                
                if (registrations.isEmpty) {
                  return const Text('No hay registros en este período');
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Usuario ID')),
                      DataColumn(label: Text('Método')),
                      DataColumn(label: Text('Tipo')),
                    ],
                    rows: registrations.take(20).map((reg) {
                      final timestamp = reg['timestamp'] as Timestamp?;
                      final date = timestamp?.toDate() ?? DateTime.now();
                      return DataRow(
                        cells: [
                          DataCell(Text('${date.day}/${date.month}/${date.year}')),
                          DataCell(
                            Text(
                              reg['userId']?.toString().substring(0, 8) ?? 'N/A',
                            ),
                          ),
                          DataCell(Text(reg['method']?.toString() ?? 'N/A')),
                          DataCell(Text(reg['userType']?.toString() ?? 'N/A')),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV() async {
    try {
      final registrations = await _analytics.getRegistrationsByDateRange(_startDate, _endDate);
      _convertToCSV(registrations);
      
      // In a real app, you would save this to a file or share it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exportado (simulado)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  String _convertToCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    
    final headers = data.first.keys.join(',');
    final rows = data.map((row) {
      return row.values.map((v) => '"$v"').join(',');
    }).join('\n');
    
    return '$headers\n$rows';
  }
}

class _RegistrationsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _RegistrationsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }

    final maxRegistrations = data
        .map((d) => (d['registrations'] as num?)?.toInt() ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _RegistrationsChartPainter(
        data: data,
        maxRegistrations: maxRegistrations,
      ),
    );
  }
}

class _RegistrationsChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int maxRegistrations;

  _RegistrationsChartPainter({
    required this.data,
    required this.maxRegistrations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    const padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final points = <Offset>[];
    final stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final registrations = (data[i]['registrations'] as num?)?.toInt() ?? 0;
      final x = padding + (i * stepX);
      final y = padding + chartHeight - ((registrations / maxRegistrations) * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw fill
    final path = Path()
      ..moveTo(padding, size.height - padding)
      ..addPolygon(points, false)
      ..lineTo(size.width - padding, size.height - padding)
      ..close();
    canvas.drawPath(path, fillPaint);

    // Draw line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 3;

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    canvas.drawLine(
      const Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RegistrationsChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxRegistrations != maxRegistrations;
  }
}
