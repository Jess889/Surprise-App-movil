import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  bool _loading = true;
  Map<String, dynamic> resumen = {};
  List<dynamic> ultimasExportaciones = [];

  @override
  void initState() {
    super.initState();
    _loadReportes();
  }

  Future<void> _loadReportes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final resumenRes = await http.get(
        Uri.parse('http://10.0.2.2:4000/api/mobile/reportes/resumen-rapido'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final exportRes = await http.get(
        Uri.parse('http://10.0.2.2:4000/api/mobile/reportes/exports/latest'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resumenRes.statusCode == 200) {
        resumen = jsonDecode(resumenRes.body)['data'];
      }
      if (exportRes.statusCode == 200) {
        ultimasExportaciones = jsonDecode(exportRes.body);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _descargar(String endpoint, String nombre) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.get(
        Uri.parse('http://10.0.2.2:4000/api/mobile/reportes/$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nombre descargado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar $nombre')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseFont = 12.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildResumen(),
                    const SizedBox(height: 20),
                    _buildExportacionRapida(),
                    const SizedBox(height: 20),
                    _buildReportesDetallados(),
                    const SizedBox(height: 20),
                    _buildUltimasExportaciones(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(baseFont),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: const [
        Text(
          "Reportes",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1B4B),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Analiza y exporta datos de tu negocio",
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF2563EB),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildResumen() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.bar_chart, color: Color(0xFF8B5CF6)),
            SizedBox(width: 6),
            Text(
              "Resumen Rápido",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
                fontFamily: 'Poppins',
              ),
            ),
          ]),
          const SizedBox(height: 14),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.3,
            children: [
              _metricCard("Ventas Hoy", "\$${resumen['ventasHoy'] ?? 0}"),
              _metricCard("Pedidos Hoy", "${resumen['pedidosHoy'] ?? 0}"),
              _metricCard(
                  "Productos Vendidos", "${resumen['productosVendidos'] ?? 0}"),
              _metricCard(
                  "Clientes Nuevos", "${resumen['clientesNuevos'] ?? 0}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value) {
    return AspectRatio(
      aspectRatio: 2.3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportacionRapida() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.download_rounded, color: Color(0xFF15803D)),
          SizedBox(width: 6),
          Text(
            "Exportación Rápida",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF166534),
              fontFamily: 'Poppins',
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _exportButton("Exportar Ventas de Hoy (CSV)",
            () => _descargar("export/ventas-hoy.csv", "Ventas CSV")),
        const SizedBox(height: 8),
        _exportButton("Exportar Inventario Actual (Excel)",
            () => _descargar("export/inventario.xlsx", "Inventario Excel")),
        const SizedBox(height: 8),
        _exportButton("Resumen Semanal (PDF)",
            () => _descargar("export/resumen-semanal.pdf", "Resumen PDF")),
      ]),
    );
  }

  Widget _exportButton(String text, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.download_rounded, color: Color(0xFF22C55E)),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Color(0xFFD1FAE5)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildReportesDetallados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Reportes Detallados",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1B4B),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        _reportCard(
          "Ventas por Período",
          "Reporte detallado de ventas por día, semana o mes",
          ["PDF", "Excel", "CSV"],
          const Color(0xFF8B5CF6),
          "ventas?format=",
        ),
        _reportCard(
          "Inventario Actual",
          "Estado actual del inventario con niveles de stock",
          ["PDF", "Excel"],
          const Color(0xFF3B82F6),
          "inventario?format=",
        ),
        _reportCard(
          "Productos Más Vendidos",
          "Top 10 productos con mayor rotación",
          ["PDF", "CSV"],
          const Color(0xFFF97316),
          "top-productos?limit=10&format=",
        ),
        _reportCard(
          "Reporte Financiero",
          "Ingresos, gastos y utilidades del período",
          ["PDF", "Excel"],
          const Color(0xFF22C55E),
          "financiero?format=",
        ),
      ],
    );
  }

  Widget _reportCard(String title, String subtitle, List<String> formatos,
      Color color, String endpoint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(Icons.insert_chart, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Poppins')),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: formatos
                      .map(
                        (f) => OutlinedButton.icon(
                          onPressed: () =>
                              _descargar("$endpoint${f.toLowerCase()}", title),
                          icon: const Icon(Icons.download, size: 16),
                          label: Text(f, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltimasExportaciones() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            CircleAvatar(
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(Icons.calendar_today, color: Color(0xFF1D4ED8)),
            ),
            SizedBox(width: 8),
            Text(
              "Últimas Exportaciones",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  fontFamily: 'Poppins'),
            ),
          ]),
          const SizedBox(height: 10),
          ...ultimasExportaciones.map((e) => _archivoItem(e)).toList(),
        ],
      ),
    );
  }

  Widget _archivoItem(dynamic e) {
    final nombre = e['nombre_reporte'] ?? 'Archivo desconocido';
    final fecha = e['fecha_generacion']?.toString().split('T').first ?? '';
    final peso = ((e['tamano_kb'] ?? 0) / 1024).toStringAsFixed(2);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Poppins')),
                  Text("$fecha • ${peso}MB",
                      style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                          fontFamily: 'Poppins')),
                ]),
          ),
          IconButton(
            onPressed: () => _descargar("exports/download/${e['id']}", nombre),
            icon: const Icon(Icons.download, color: Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(double baseFont) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavIcon(
              icon: Icons.home,
              label: "Inicio",
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard')),
          _BottomNavIcon(
              icon: Icons.inventory_2_outlined,
              label: "Inventario",
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/inventario')),
          _BottomNavIcon(
              icon: Icons.percent,
              label: "Promociones",
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/promociones')),
          _BottomNavIcon(icon: Icons.bar_chart, label: "Reportes", active: true),
        ],
      ),
    );
  }
}

class _BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _BottomNavIcon(
      {required this.icon, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF8B5CF6) : Colors.grey;
    final bg = active ? const Color(0xFFF3E8FF) : Colors.transparent;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }
}
