import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, required this.userName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final uri = Uri.parse('https://surprise-backend.vercel.app/api/mobile/dashboard');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        debugPrint('Error al obtener datos del dashboard');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
      );
    }

    final ventasHoy = (data?['ventasHoy'] ?? 0).toDouble();
    final ventasAyer = (data?['ventasAyer'] ?? ventasHoy).toDouble();
    final pedidosHoy = (data?['pedidosHoy'] ?? 0).toDouble();
    final pedidosAyer = (data?['pedidosAyer'] ?? pedidosHoy).toDouble();
    final ingresosMes = (data?['ingresosMes'] ?? 0).toDouble();
    final ingresosMesAnterior = (data?['ingresosMesAnterior'] ?? ingresosMes).toDouble();
    final topProductos = data?['topProductos'] ?? [];

    double calcPercent(double actual, double anterior) {
      if (anterior == 0) return 0;
      return ((actual - anterior) / anterior) * 100;
    }

    final ventasPercent = calcPercent(ventasHoy, ventasAyer);
    final pedidosPercent = calcPercent(pedidosHoy, pedidosAyer);
    final ingresosPercent = calcPercent(ingresosMes, ingresosMesAnterior);

    final baseFont = isSmallScreen ? 12.0 : 14.0;
    final titleFont = isSmallScreen ? 16.0 : 18.0;
    final bigFont = isSmallScreen ? 22.0 : 26.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE9FE), Color(0xFFE0F2FE), Color(0xFFFCE7F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(widget.userName, titleFont, baseFont),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Resumen de Hoy",
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _smallCard(
                              title: "Ventas",
                              value: "\$${ventasHoy.toStringAsFixed(0)}",
                              percent: ventasPercent,
                              icon: Icons.attach_money,
                              bgColor: const Color(0xFFF3E8FF),
                              baseFont: baseFont,
                              bigFont: bigFont,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _smallCard(
                              title: "Pedidos",
                              value: pedidosHoy.toStringAsFixed(0),
                              percent: pedidosPercent,
                              icon: Icons.shopping_bag_outlined,
                              bgColor: const Color(0xFFDBEAFE),
                              baseFont: baseFont,
                              bigFont: bigFont,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _bigCard(
                        title: "Ingresos del Mes",
                        value: "\$${ingresosMes.toStringAsFixed(0)}",
                        percent: ingresosPercent,
                        icon: Icons.trending_up,
                        baseFont: baseFont,
                        bigFont: bigFont,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Productos Más Vendidos",
                            style: TextStyle(
                              fontSize: titleFont,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Icon(Icons.inventory_2_outlined, color: Color(0xFF8B5CF6)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: topProductos.length,
                        itemBuilder: (context, index) {
                          final p = topProductos[index];
                          final colors = [
                            const Color(0xFF8B5CF6),
                            const Color(0xFF60A5FA),
                            const Color(0xFFF472B6),
                            const Color(0xFF6366F1),
                          ];
                          return _productItem(
                            index + 1,
                            p['nombre'],
                            "${p['cantidad']} ventas",
                            colors[index % colors.length],
                            baseFont,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(baseFont),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, double titleFont, double baseFont) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFE0F2FE), Color(0xFFFCE7F3)],
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "Surprise",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFont,
                fontFamily: 'Poppins',
                color: const Color(0xFF1E1B4B),
              ),
            ),
            Text(
              "¡Hola $name! 🌟",
              style: TextStyle(
                fontSize: baseFont,
                fontFamily: 'Poppins',
                color: const Color(0xFF9333EA),
              ),
            ),
          ]),
          Row(children: [
            _iconButton(Icons.notifications_none),
            const SizedBox(width: 10),
            _iconButton(Icons.logout, onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/auth');
            }),
          ]),
        ],
      ),
    );
  }

  Widget _smallCard({
    required String title,
    required String value,
    required double percent,
    required IconData icon,
    required Color bgColor,
    required double baseFont,
    required double bigFont,
  }) {
    final color = percent >= 0 ? Colors.teal : Colors.red;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title,
                style: TextStyle(
                    fontSize: baseFont,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
            Icon(icon, color: const Color(0xFF8B5CF6), size: 20)
          ]),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: bigFont,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            "${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: baseFont - 1,
              color: color,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  Widget _bigCard({
    required String title,
    required String value,
    required double percent,
    required IconData icon,
    required double baseFont,
    required double bigFont,
  }) {
    final color = percent >= 0 ? Colors.teal : Colors.red;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE7F3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: baseFont,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: bigFont + 2,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins')),
            Text(
              "${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: baseFont - 1,
                color: color,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            )
          ]),
          Icon(icon, color: const Color(0xFF8B5CF6), size: bigFont)
        ],
      ),
    );
  }

  Widget _productItem(int rank, String name, String sales, Color color, double baseFont) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 17,
            child: Text(
              "$rank",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: baseFont,
                  fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: baseFont + 1,
                    fontFamily: 'Poppins')),
            Text(sales,
                style: TextStyle(
                    fontSize: baseFont - 1,
                    color: Colors.grey,
                    fontFamily: 'Poppins')),
          ]),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
      ),
    );
  }

  Widget _buildBottomNav(double baseFont) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFE0F2FE), Color(0xFFFCE7F3)],
        ),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavIcon(
            icon: Icons.home,
            label: "Inicio",
            active: true,
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          _BottomNavIcon(
            icon: Icons.inventory_2_outlined,
            label: "Inventario",
            onTap: () => Navigator.pushReplacementNamed(context, '/inventario'),
          ),
          _BottomNavIcon(
            icon: Icons.percent,
            label: "Promociones",
            onTap: () => Navigator.pushReplacementNamed(context, '/promociones'),
          ),
          _BottomNavIcon(
            icon: Icons.bar_chart_outlined,
            label: "Reportes",
            onTap: () => Navigator.pushReplacementNamed(context, '/reportes'),
          ),
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

  const _BottomNavIcon({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF8B5CF6) : Colors.grey;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
