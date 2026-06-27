import 'package:flutter/material.dart';

import 'repositories/cliente_repository.dart';
import 'settings/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repo = ClienteRepository();
  Map<String, dynamic> resumen = {
    'totalClientes': 0,
    'pendientes': 0,
    'entregados': 0,
    'librasPendientes': 0.0,
  };

  @override
  void initState() {
    super.initState();
    cargarResumen();
  }

  Future<void> cargarResumen() async {
    resumen = await repo.resumen();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = resumen['pendientes'] ?? 0;
    final entregados = resumen['entregados'] ?? 0;
    final libras = (resumen['librasPendientes'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Entregas de Chancho')),
      body: RefreshIndicator(
        onRefresh: cargarResumen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(45),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 46),
                    SizedBox(height: 14),
                    Text(
                      'Control de entregas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Registra clientes, pedidos y arma tu ruta de entrega desde el mapa.',
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: resumenCard(
                      title: 'Pendientes',
                      value: '$pendientes',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: resumenCard(
                      title: 'Entregados',
                      value: '$entregados',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              resumenCard(
                title: 'Libras por entregar',
                value: '${libras.toStringAsFixed(2)} lb',
                icon: Icons.scale_rounded,
                color: AppColors.info,
                full: true,
              ),
              const SizedBox(height: 20),
              boton(
                context,
                icono: Icons.people_alt_rounded,
                titulo: 'Listado de clientes',
                subtitulo: 'Ver, editar, eliminar y marcar entregas.',
                ruta: '/clientes',
                color: AppColors.primary,
              ),
              boton(
                context,
                icono: Icons.add_location_alt_rounded,
                titulo: 'Registrar cliente',
                subtitulo: 'Guarda pedido, libras y ubicación en el mapa.',
                ruta: '/clientes/form',
                color: AppColors.secondary,
              ),
              boton(
                context,
                icono: Icons.route_rounded,
                titulo: 'Mapa y ruta',
                subtitulo: 'Ordena las entregas y abre la ruta en Google Maps.',
                ruta: '/mapa',
                color: AppColors.info,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppNav.bottomMenu(0, context),
    );
  }

  Widget resumenCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool full = false,
  }) {
    return Container(
      width: full ? double.infinity : null,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withAlpha(35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget boton(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required String ruta,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          await Navigator.pushNamed(context, ruta);
          cargarResumen();
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icono, color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitulo, style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
