import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/cliente_models.dart';
import '../../repositories/cliente_repository.dart';
import '../../settings/app_theme.dart';
import '../../settings/route_helper.dart';

class MapaEntregasScreen extends StatefulWidget {
  const MapaEntregasScreen({super.key});

  @override
  State<MapaEntregasScreen> createState() => _MapaEntregasScreenState();
}

class _MapaEntregasScreenState extends State<MapaEntregasScreen> {
  final repo = ClienteRepository();

  GoogleMapController? mapController;
  Position? currentPosition;

  List<ClienteModels> clientes = [];
  List<ClienteModels> rutaOptimizada = [];

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  bool cargando = true;
  bool rutaIniciada = false;

  static const LatLng centroEcuador = LatLng(-1.8312, -78.1834);

  @override
  void initState() {
    super.initState();
    cargarTodo();
  }

  Future<void> cargarTodo() async {
    setState(() => cargando = true);

    clientes = await repo.getPendientes();
    await _initUbicacion();
    armarMarcadores(clientes, numerados: false);

    if (mounted) setState(() => cargando = false);
  }

  Future<void> _initUbicacion() async {
    try {
      final ok = await _permisosUbicacion();
      if (!ok) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      currentPosition = pos;
    } catch (_) {
      _snack('No se pudo obtener ubicación. La ruta necesita tu GPS.');
    }
  }

  Future<bool> _permisosUbicacion() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _snack('Activa el GPS del teléfono.');
      return false;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      _snack('Permiso de ubicación denegado.');
      return false;
    }
    if (perm == LocationPermission.deniedForever) {
      _snack('Permiso denegado permanentemente. Habilítalo desde Ajustes.');
      return false;
    }
    return true;
  }

  void armarMarcadores(List<ClienteModels> data, {required bool numerados}) {
    final nuevos = <Marker>{};

    if (currentPosition != null) {
      nuevos.add(
        Marker(
          markerId: const MarkerId('mi_ubicacion'),
          position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Estoy aquí'),
        ),
      );
    }

    for (int i = 0; i < data.length; i++) {
      final c = data[i];
      nuevos.add(
        Marker(
          markerId: MarkerId('cliente_${c.id ?? i}'),
          position: LatLng(c.latitud, c.longitud),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            numerados ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: numerados ? '${i + 1}. ${c.nombre}' : c.nombre,
            snippet: '${c.libras.toStringAsFixed(2)} lb • ${c.pedido}',
          ),
        ),
      );
    }

    markers = nuevos;
  }

  void iniciarRuta() async {
    if (clientes.isEmpty) {
      dlgInfo('Sin pedidos', 'No tienes pedidos pendientes para entregar.');
      return;
    }

    if (currentPosition == null) {
      await _initUbicacion();
      if (currentPosition == null) {
        dlgInfo(
          'Ubicación necesaria',
          'Para ordenar la ruta debes permitir ubicación y activar el GPS.',
        );
        return;
      }
    }

    final origen = LatLng(currentPosition!.latitude, currentPosition!.longitude);
    final orden = RouteHelper.optimizarPorCercania(origen, clientes);

    final puntos = <LatLng>[origen];
    for (final c in orden) {
      puntos.add(LatLng(c.latitud, c.longitud));
    }

    setState(() {
      rutaOptimizada = orden;
      rutaIniciada = true;
      armarMarcadores(orden, numerados: true);
      polylines = {
        Polyline(
          polylineId: const PolylineId('ruta_entrega'),
          points: puntos,
          width: 5,
          color: AppColors.primary,
        ),
      };
    });

    if (orden.isNotEmpty) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(orden.first.latitud, orden.first.longitud), 14),
      );
    }
  }

  Future<void> abrirGoogleMaps() async {
    if (rutaOptimizada.isEmpty) {
      iniciarRuta();
      await Future.delayed(const Duration(milliseconds: 250));
      if (rutaOptimizada.isEmpty) return;
    }

    if (currentPosition == null) {
      _snack('No tengo tu ubicación actual.');
      return;
    }

    final origen = '${currentPosition!.latitude},${currentPosition!.longitude}';

    final limite = rutaOptimizada.length > 9 ? rutaOptimizada.take(9).toList() : rutaOptimizada;
    if (rutaOptimizada.length > 9) {
      _snack('Google Maps abrirá las primeras 9 paradas para evitar errores.');
    }

    final destino = '${limite.last.latitud},${limite.last.longitud}';
    final intermedios = limite.length <= 1
        ? ''
        : limite.take(limite.length - 1).map((c) => '${c.latitud},${c.longitud}').join('|');

    final urlString = intermedios.isEmpty
        ? 'https://www.google.com/maps/dir/?api=1&origin=$origen&destination=$destino&travelmode=driving'
        : 'https://www.google.com/maps/dir/?api=1&origin=$origen&destination=$destino&waypoints=${Uri.encodeComponent(intermedios)}&travelmode=driving';

    final url = Uri.parse(urlString);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _snack('No se pudo abrir Google Maps.');
    }
  }

  Future<void> marcarPrimeroEntregado() async {
    if (rutaOptimizada.isEmpty) {
      _snack('Primero inicia la ruta.');
      return;
    }

    final primero = rutaOptimizada.first;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Confirmar entrega',
      desc: '¿Deseas marcar como entregado el pedido de ${primero.nombre}?',
      btnCancelText: 'Cancelar',
      btnOkText: 'Sí, entregado',
      btnOkColor: AppColors.primary,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await repo.marcarEntregado(primero.id!);
        await cargarTodo();
        setState(() {
          rutaOptimizada.clear();
          rutaIniciada = false;
          polylines.clear();
        });
      },
    ).show();
  }

  void dlgInfo(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: 'Ok',
      btnOkColor: AppColors.primary,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final target = currentPosition == null
        ? (clientes.isNotEmpty ? LatLng(clientes.first.latitud, clientes.first.longitud) : centroEcuador)
        : LatLng(currentPosition!.latitude, currentPosition!.longitude);

    final listaPanel = rutaOptimizada.isEmpty ? clientes : rutaOptimizada;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de entregas'),
        actions: [
          IconButton(onPressed: cargarTodo, icon: const Icon(Icons.refresh_rounded))
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: target, zoom: currentPosition == null ? 7 : 14),
                  myLocationEnabled: currentPosition != null,
                  myLocationButtonEnabled: true,
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) {
                    mapController = controller;
                    if (currentPosition != null) {
                      controller.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
                    }
                  },
                ),
                Positioned(top: 14, left: 14, right: 14, child: estadoCard()),
                DraggableScrollableSheet(
                  initialChildSize: 0.34,
                  minChildSize: 0.18,
                  maxChildSize: 0.62,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 5,
                            margin: const EdgeInsets.only(top: 10, bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: accionesRuta(),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: listaPanel.isEmpty
                                ? emptyState(
                                    icon: Icons.done_all_rounded,
                                    title: 'No hay entregas pendientes',
                                    subtitle: 'Cuando registres pedidos pendientes aparecerán aquí.',
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                    itemCount: listaPanel.length,
                                    itemBuilder: (_, i) {
                                      final item = listaPanel[i];
                                      final distancia = currentPosition == null
                                          ? null
                                          : RouteHelper.distanciaMetros(
                                              LatLng(currentPosition!.latitude, currentPosition!.longitude),
                                              LatLng(item.latitud, item.longitud),
                                            );
                                      return rutaItem(item, i, distancia);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
      bottomNavigationBar: AppNav.bottomMenu(3, context),
    );
  }

  Widget estadoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(245),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(rutaIniciada ? Icons.route_rounded : Icons.place_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rutaIniciada
                  ? 'Ruta organizada con ${rutaOptimizada.length} parada(s)'
                  : '${clientes.length} cliente(s) pendiente(s) en el mapa',
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget accionesRuta() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: iniciarRuta,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar ruta'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton.icon(
                onPressed: abrirGoogleMaps,
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Google Maps'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
        if (rutaOptimizada.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: marcarPrimeroEntregado,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Marcar primera parada como entregada'),
              style: TextButton.styleFrom(foregroundColor: AppColors.success),
            ),
          ),
        ]
      ],
    );
  }

  Widget rutaItem(ClienteModels item, int index, double? distancia) {
    final orden = rutaOptimizada.isEmpty ? null : index + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              orden == null ? '•' : '$orden',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text('${item.libras.toStringAsFixed(2)} lb • ${item.pedido}', style: const TextStyle(color: AppColors.textDark)),
                const SizedBox(height: 3),
                Text(
                  item.direccionTexto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (distancia != null)
            Text(
              RouteHelper.distanciaBonita(distancia),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
