import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  bool _searching = false;
  String _query = '';

  int total = 0;
  int bajo = 0;
  int critico = 0;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _searchController.addListener(() {
      final q = _searchController.text.trim();
      if (q != _query) {
        _query = q;
        _onSearchChanged(q);
      }
    });
  }

  Future<void> _onSearchChanged(String q) async {
    if (q.isEmpty) {
      await _fetchInventory();
      return;
    }
    setState(() => _searching = true);
    await Future.delayed(const Duration(milliseconds: 350));
    await _fetchInventory(query: q);
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _fetchInventory({String query = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final uri = Uri.parse(
          'http://10.0.2.2:4000/api/mobile/inventory${query.isNotEmpty ? '?q=${Uri.encodeQueryComponent(query)}' : ''}');
      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final fetchedItems = json['items'] ?? [];

        if (query.isNotEmpty) {
          setState(() {
            items = fetchedItems;
            total = items.length;
            bajo = items.where((p) => p['estado'] == 'bajo').length;
            critico = items.where((p) => p['estado'] == 'critico').length;
            _loading = false;
          });
        } else {
          setState(() {
            items = fetchedItems;
            total = json['stats']?['total'] ?? 0;
            bajo = json['stats']?['bajo'] ?? 0;
            critico = json['stats']?['critico'] ?? 0;
            _loading = false;
          });
        }
      } else if (res.statusCode == 401) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión expirada. Inicia sesión nuevamente.')),
        );
        Navigator.pushReplacementNamed(context, '/auth');
      } else {
        throw Exception('Error ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error inventario: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener inventario')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F3FF), Color(0xFFE0F2FE), Color(0xFFFCE7F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                )
              : Column(
                  children: [
                    _header(),
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF8B5CF6),
                        onRefresh: () => _fetchInventory(query: _query),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _statsRow(),
                              const SizedBox(height: 14),
                              _searchField(),
                              if (_searching)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: LinearProgressIndicator(minHeight: 2),
                                ),
                              const SizedBox(height: 10),
                              if (items.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 50),
                                    child: Text(
                                      'No se encontraron productos.',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ),
                              ...items.map((p) => _productCard(p)).toList(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _bottomNav(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text(
            'Inventario',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Color(0xFF1E1B4B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Gestiona tu stock de productos',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: 'Total',
            value: '$total',
            bg: const Color(0xFFDBEAFE),
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            label: 'Bajo',
            value: '$bajo',
            bg: const Color(0xFFFDE68A),
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            label: 'Crítico',
            value: '$critico',
            bg: const Color(0xFFFBCFE8),
            icon: Icons.error_outline,
            iconColor: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color bg,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: iconColor,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Buscar productos...",
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF8B5CF6)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: Color(0xFF8B5CF6), width: 1.3),
        ),
      ),
    );
  }

  Widget _productCard(dynamic p) {
    final String estado = (p['estado'] ?? 'normal') as String;
    final badge = _estadoBadge(estado);
    final Color bg = _bgColorEstado(estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    p['nombre'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    p['categoria'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: badge['bg'],
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      badge['text'],
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: badge['dot'],
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Stock: ${p['stock']} unidades",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                ),
              ),
              Text(
                "\$${(p['precio'] ?? 0).toString()}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Map<String, dynamic> _estadoBadge(String estado) {
    switch (estado) {
      case 'critico':
        return {
          'bg': const Color(0xFFEF4444),
          'dot': const Color(0xFFDC2626),
          'text': 'Crítico'
        };
      case 'bajo':
        return {
          'bg': const Color(0xFF60A5FA),
          'dot': const Color(0xFFFACC15),
          'text': 'Bajo'
        };
      default:
        return {
          'bg': const Color(0xFF8B5CF6),
          'dot': const Color(0xFF34D399),
          'text': 'Normal'
        };
    }
  }

  Color _bgColorEstado(String estado) {
    switch (estado) {
      case 'critico':
        return const Color(0xFFFFF1F2);
      case 'bajo':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFECFDF5);
    }
  }

  Widget _bottomNav() {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            icon: Icons.home,
            label: 'Inicio',
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          _BottomItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventario',
            active: true,
            onTap: () => Navigator.pushReplacementNamed(context, '/inventario'),
          ),
          _BottomItem(
            icon: Icons.percent,
            label: 'Promociones',
            active: false,
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/promociones'),
          ),
          _BottomItem(
            icon: Icons.bar_chart_outlined,
            label: 'Reportes',
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/reportes'),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF8B5CF6) : Colors.grey;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
