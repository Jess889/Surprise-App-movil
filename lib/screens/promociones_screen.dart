import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kBaseUrl = 'https://surprise-backend.vercel.app';

enum PromoTab { promociones, cupones }
enum FilterTab { activos, crear, historial }

class PromocionesScreen extends StatefulWidget {
  const PromocionesScreen({super.key});

  @override
  State<PromocionesScreen> createState() => _PromocionesScreenState();
}

class _PromocionesScreenState extends State<PromocionesScreen> {
  PromoTab _activeTab = PromoTab.promociones;
  FilterTab _filter = FilterTab.activos;

  bool _loading = true;
  bool _posting = false;

  List<dynamic> _promos = [];
  List<dynamic> _cupones = [];

  final _promoTitleCtrl = TextEditingController();
  final _promoDescCtrl = TextEditingController();
  final _promoCategoriaCtrl = TextEditingController();
  final _promoValorCtrl = TextEditingController();
  String _promoTipo = 'PORCENTAJE';
  DateTime? _promoInicio;
  DateTime? _promoFin;

  final _cuponCodigoCtrl = TextEditingController();
  final _cuponValorCtrl = TextEditingController();
  final _cuponMaxUsosCtrl = TextEditingController(text: '100');
  String _cuponTipo = 'PORCENTAJE';
  DateTime? _cuponInicio;
  DateTime? _cuponFin;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _promoTitleCtrl.dispose();
    _promoDescCtrl.dispose();
    _promoCategoriaCtrl.dispose();
    _promoValorCtrl.dispose();
    _cuponCodigoCtrl.dispose();
    _cuponValorCtrl.dispose();
    _cuponMaxUsosCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final promosRes = await http.get(
        Uri.parse('$kBaseUrl/api/promociones/promociones'),
      );
      final cuponesRes = await http.get(
        Uri.parse('$kBaseUrl/api/promociones/cupones'),
      );

      if (promosRes.statusCode == 200 && cuponesRes.statusCode == 200) {
        final promosJson = jsonDecode(promosRes.body);
        final cuponesJson = jsonDecode(cuponesRes.body);
        setState(() {
          _promos = (promosJson is List) ? promosJson : (promosJson['data'] ?? []);
          _cupones = (cuponesJson is List) ? cuponesJson : (cuponesJson['data'] ?? []);
          _loading = false;
        });
      } else {
        throw Exception('Error al cargar datos (${promosRes.statusCode}/${cuponesRes.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _fmtDate(dynamic d) {
    if (d == null) return '';
    try {
      final date = (d is DateTime) ? d : DateTime.parse(d.toString());
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return d.toString();
    }
  }

  Color _chipColorByEstadoPromo(String estado) {
    switch (estado) {
      case 'ACTIVA':
        return const Color(0xFF34D399); 
      case 'EXPIRADA':
        return const Color(0xFF8B5CF6); 
      case 'PROGRAMADA':
        return const Color(0xFF60A5FA); 
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _estadoCupon(dynamic c) {
    return (c['estado'] ?? '').toString();
  }

  Color _chipColorByEstadoCupon(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return const Color(0xFF34D399);
      case 'EXPIRADO':
        return const Color(0xFF8B5CF6);
      case 'INACTIVO':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Future<void> _submitPromocion() async {
    if (_promoTitleCtrl.text.trim().isEmpty ||
        _promoValorCtrl.text.trim().isEmpty ||
        _promoInicio == null ||
        _promoFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa título, valor y fechas.')),
      );
      return;
    }
    final body = {
      "titulo": _promoTitleCtrl.text.trim(),
      "descripcion": _promoDescCtrl.text.trim(),
      "tipo": _promoTipo, 
      "valor_descuento": double.tryParse(_promoValorCtrl.text.trim()) ?? 0,
      "categoria": _promoCategoriaCtrl.text.trim().isEmpty ? null : _promoCategoriaCtrl.text.trim(),
      "fecha_inicio": _fmtDate(_promoInicio),
      "fecha_fin": _fmtDate(_promoFin),
    };

    setState(() => _posting = true);
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/promociones/promociones'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      setState(() => _posting = false);
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promoción creada')),
        );
        _promoTitleCtrl.clear();
        _promoDescCtrl.clear();
        _promoCategoriaCtrl.clear();
        _promoValorCtrl.clear();
        _promoTipo = 'PORCENTAJE';
        _promoInicio = null;
        _promoFin = null;
        _filter = FilterTab.activos;
        await _fetchAll();
      } else {
        throw Exception('Error ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear promoción: $e')),
      );
    }
  }

  Future<void> _submitCupon() async {
    if (_cuponCodigoCtrl.text.trim().isEmpty ||
        _cuponValorCtrl.text.trim().isEmpty ||
        _cuponInicio == null ||
        _cuponFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa código, valor y fechas.')),
      );
      return;
    }
    final body = {
      "codigo": _cuponCodigoCtrl.text.trim(),
      "tipo": _cuponTipo, 
      "valor": double.tryParse(_cuponValorCtrl.text.trim()) ?? 0,
      "max_usos": int.tryParse(_cuponMaxUsosCtrl.text.trim()) ?? 100,
      "fecha_inicio": _fmtDate(_cuponInicio),
      "fecha_fin": _fmtDate(_cuponFin),
    };

    setState(() => _posting = true);
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/promociones/cupones'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      setState(() => _posting = false);
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cupón creado')),
        );
        _cuponCodigoCtrl.clear();
        _cuponValorCtrl.clear();
        _cuponMaxUsosCtrl.text = '100';
        _cuponTipo = 'PORCENTAJE';
        _cuponInicio = null;
        _cuponFin = null;
        _filter = FilterTab.activos;
        await _fetchAll();
      } else {
        throw Exception('Error ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear cupón: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPromo = _activeTab == PromoTab.promociones;

    final promosActivas = _promos.where((p) => (p['estado'] ?? '') == 'ACTIVA').toList();
    final promosExpiradas = _promos.where((p) => (p['estado'] ?? '') == 'EXPIRADA').toList();

    final cuponesActivos = _cupones.where((c) => (c['estado'] ?? '') == 'ACTIVO').toList();
    final cuponesExp = _cupones.where((c) => (c['estado'] ?? '') == 'EXPIRADO').toList();

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
          child: Column(
            children: [
              _header(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF8B5CF6),
                        onRefresh: _fetchAll,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Column(
                            children: [
                              _tabsTop(isPromo),
                              const SizedBox(height: 8),
                              _filterTabs(isPromo),
                              const SizedBox(height: 12),

                              if (_filter == FilterTab.activos && isPromo) _statsPromos(promosActivas, _promos),
                              if (_filter == FilterTab.activos && !isPromo) _statsCupones(cuponesActivos, _cupones),

                              if (_filter == FilterTab.crear)
                                (isPromo ? _formPromocion() : _formCupon())
                              else if (_filter == FilterTab.activos)
                                Column(
                                  children: (isPromo ? _promos : _cupones)
                                      .map((e) => isPromo ? _promoCard(e) : _cuponCard(e))
                                      .toList(),
                                )
                              else
                                Column(
                                  children: (isPromo ? promosExpiradas : cuponesExp)
                                      .map((e) => isPromo ? _promoCard(e) : _cuponHistCard(e))
                                      .toList(),
                                ),

                              const SizedBox(height: 24),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: const [
          Text(
            'Promociones y Cupones',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Gestiona ofertas y descuentos',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabsTop(bool isPromo) {
    return Row(children: [
      Expanded(
        child: _segBtn(
          active: isPromo,
          label: 'Promociones',
          icon: Icons.card_giftcard,
          onTap: () => setState(() {
            _activeTab = PromoTab.promociones;
            _filter = FilterTab.activos;
          }),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: _segBtn(
          active: !isPromo,
          label: 'Cupones',
          icon: Icons.confirmation_number_outlined,
          colorActive: const Color(0xFF3B82F6),
          bgActive: const Color(0xFFDCEAFE),
          onTap: () => setState(() {
            _activeTab = PromoTab.cupones;
            _filter = FilterTab.activos;
          }),
        ),
      ),
    ]);
  }
  
  Widget _segBtn({
    required bool active,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color colorActive = const Color(0xFF8B5CF6),
    Color bgActive = const Color(0xFFEDE9FE),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? bgActive : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? colorActive : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: active ? colorActive : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTabs(bool isPromo) {
    Color color = isPromo ? const Color(0xFFFCE7F3) : const Color(0xFFE0F2FE);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Expanded(child: _filterBtn('Activos', FilterTab.activos, isPromo)),
          const SizedBox(width: 6),
          Expanded(child: _filterBtn('Crear', FilterTab.crear, isPromo)),
          const SizedBox(width: 6),
          Expanded(child: _filterBtn('Historial', FilterTab.historial, isPromo)),
        ],
      ),
    );
  }

  Widget _filterBtn(String label, FilterTab value, bool isPromo) {
    final active = _filter == value;
    final color = isPromo ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6);
    final bg = isPromo ? const Color(0xFFFCE7F3) : const Color(0xFFDCEAFE);
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: active ? color : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsPromos(List<dynamic> activas, List<dynamic> total) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Activas',
            value: activas.length.toString(),
            icon: Icons.local_offer_outlined,
            bg: const Color(0xFFFCE7F3),
            iconColor: const Color(0xFFEC4899),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            title: 'Total',
            value: total.length.toString(),
            icon: Icons.calendar_today_outlined,
            bg: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _statsCupones(List<dynamic> activos, List<dynamic> total) {
    final usosTotales = total.fold<int>(0, (acc, c) => acc + ((c['usados'] ?? 0) as num).toInt());
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Activos',
            value: activos.length.toString(),
            icon: Icons.confirmation_number_outlined,
            bg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            title: 'Usos Totales',
            value: usosTotales.toString(),
            icon: Icons.timelapse_outlined,
            bg: const Color(0xFFF1F0FF),
            iconColor: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bg),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    )),
              ],
            ),
          )
        ],
      ),
    );
  }


  Widget _promoCard(dynamic p) {
    final estado = (p['estado'] ?? 'ACTIVA').toString();
    final tipo = (p['tipo'] ?? 'PORCENTAJE').toString();
    final valor = (p['valor_descuento'] ?? 0).toString();
    final colorChip = _chipColorByEstadoPromo(estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE7F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFBCFE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p['titulo'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Text(
                  tipo == 'PORCENTAJE' ? '${valor.replaceAll('.0', '')}%' : '\$$valor',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
          if ((p['descripcion'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              p['descripcion'],
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF475569),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if ((p['categoria'] ?? '').toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p['categoria'],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '${_fmtDate(p['fecha_inicio'])} - ${_fmtDate(p['fecha_fin'])}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorChip.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado == 'ACTIVA'
                    ? 'Activa'
                    : estado == 'EXPIRADA'
                        ? 'Expirada'
                        : 'Programada',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: colorChip,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuponCard(dynamic c) {
    final estado = _estadoCupon(c);
    final colorChip = _chipColorByEstadoCupon(estado);
    final maxUsos = (c['max_usos'] ?? 0) as int;
    final usados = (c['usados'] ?? 0) as int;
    final progress = (maxUsos > 0) ? usados / maxUsos : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (c['codigo'] ?? '').toString(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                c['tipo'] == 'PORCENTAJE'
                    ? '${(c['valor'] ?? 0).toString().replaceAll('.0', '')}%'
                    : '\$${c['valor'] ?? 0}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Vigencia: ${_fmtDate(c['fecha_inicio'])} - ${_fmtDate(c['fecha_fin'])}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usos: $usados/$maxUsos',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorChip.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado == 'ACTIVO'
                      ? 'Activo'
                      : estado == 'EXPIRADO'
                          ? 'Expirado'
                          : 'Inactivo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: colorChip,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFDBEAFE),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuponHistCard(dynamic c) {
    final usos = (c['usados'] ?? 0) as int;
    final maxUsos = (c['max_usos'] ?? 0) as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (c['codigo'] ?? '').toString(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                c['tipo'] == 'PORCENTAJE'
                    ? '${(c['valor'] ?? 0).toString().replaceAll('.0', '')}%'
                    : '\$${c['valor'] ?? 0}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Vigencia: ${_fmtDate(c['fecha_inicio'])} - ${_fmtDate(c['fecha_fin'])}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Usos finales: $usos/$maxUsos',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Completado',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }


  Widget _formPromocion() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FormTitle(text: '+ Nueva Promoción'),
          const SizedBox(height: 10),
          _inputText(label: 'Título de la Promoción', controller: _promoTitleCtrl, hint: 'Ej: Promo Peluches'),
          const SizedBox(height: 10),
          _inputMultiline(label: 'Descripción', controller: _promoDescCtrl, hint: 'Ej: 30% en todos los peluches'),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _inputNumber(label: 'Descuento', controller: _promoValorCtrl, hint: '30'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  label: 'Tipo',
                  value: _promoTipo,
                  items: const ['PORCENTAJE', 'MONTO'],
                  onChanged: (v) => setState(() => _promoTipo = v ?? 'PORCENTAJE'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _inputText(label: 'Categoría (opcional)', controller: _promoCategoriaCtrl, hint: 'Peluches'),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _datePicker(
                  label: 'Fecha Inicio',
                  value: _promoInicio,
                  onPick: (d) => setState(() => _promoInicio = d),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _datePicker(
                  label: 'Fecha Fin',
                  value: _promoFin,
                  onPick: (d) => setState(() => _promoFin = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _submitButton(
            text: _posting ? 'Creando...' : 'Crear Promoción',
            onTap: _posting ? null : _submitPromocion,
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _formCupon() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FormTitle(text: '+ Crear Nuevo Cupón'),
          const SizedBox(height: 10),
          _inputText(label: 'Código del Cupón', controller: _cuponCodigoCtrl, hint: 'DESCUENTO20'),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _inputNumber(label: 'Descuento', controller: _cuponValorCtrl, hint: '20'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  label: 'Tipo',
                  value: _cuponTipo,
                  items: const ['PORCENTAJE', 'MONTO'],
                  onChanged: (v) => setState(() => _cuponTipo = v ?? 'PORCENTAJE'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _datePicker(
                  label: 'Fecha Inicio',
                  value: _cuponInicio,
                  onPick: (d) => setState(() => _cuponInicio = d),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _datePicker(
                  label: 'Fecha Fin',
                  value: _cuponFin,
                  onPick: (d) => setState(() => _cuponFin = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _inputNumber(label: 'Máximo de Usos', controller: _cuponMaxUsosCtrl, hint: '100'),
          const SizedBox(height: 14),
          _submitButton(
            text: _posting ? 'Creando...' : 'Crear Cupón',
            onTap: _posting ? null : _submitCupon,
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }


  Widget _inputText({required String label, required TextEditingController controller, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: controller,
          decoration: _inputDecoration(hint ?? ''),
        ),
      ],
    );
  }

  Widget _inputMultiline({required String label, required TextEditingController controller, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 4,
          decoration: _inputDecoration(hint ?? ''),
        ),
      ],
    );
  }

  Widget _inputNumber({required String label, required TextEditingController controller, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(hint ?? ''),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e == 'PORCENTAJE' ? 'Porcentaje (%)' : 'Monto',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(now.year - 3),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  value == null ? 'dd/mm/aaaa' : _fmtDate(value),
                  style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF475569)),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF93C5FD)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _submitButton({required String text, required VoidCallback? onTap, required Color color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 2,
        ),
        child: Text(
          text,
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            icon: Icons.home_outlined,
            label: 'Inicio',
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          _BottomItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventario',
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/inventario'),
          ),
          _BottomItem(
            icon: Icons.percent,
            label: 'Promociones',
            active: true,
            onTap: () {},
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

class _FormTitle extends StatelessWidget {
  final String text;
  const _FormTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
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
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
