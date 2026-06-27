import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/cliente_models.dart';
import '../../repositories/cliente_repository.dart';
import '../../settings/app_theme.dart';

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final pedidoController = TextEditingController();
  final librasController = TextEditingController();
  final direccionController = TextEditingController();
  final referenciaController = TextEditingController();

  ClienteModels? cliente;
  bool _argsCargados = false;
  bool _guardando = false;

  String estadoSeleccionado = 'Pendiente';

  GoogleMapController? mapController;
  Position? currentPosition;
  LatLng? puntoCliente;
  Set<Marker> markers = {};

  static const LatLng centroEcuador = LatLng(-1.8312, -78.1834);

  @override
  void initState() {
    super.initState();
    _initUbicacion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsCargados) return;
    _argsCargados = true;

    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null) {
      cliente = args as ClienteModels;
      nombreController.text = cliente!.nombre;
      telefonoController.text = cliente!.telefono;
      pedidoController.text = cliente!.pedido;
      librasController.text = cliente!.libras.toStringAsFixed(2);
      direccionController.text = cliente!.direccionTexto;
      referenciaController.text = cliente!.referencia;
      estadoSeleccionado = cliente!.estado;

      final p = LatLng(cliente!.latitud, cliente!.longitud);
      seleccionarPunto(p, moverCamara: false);
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    pedidoController.dispose();
    librasController.dispose();
    direccionController.dispose();
    referenciaController.dispose();
    super.dispose();
  }

  Future<void> _initUbicacion() async {
    try {
      final ok = await _permisosUbicacion();
      if (!ok) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => currentPosition = pos);

      if (puntoCliente == null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
        );
      }
    } catch (_) {
      _snack('No se pudo obtener tu ubicación. Puedes elegir el punto manualmente.');
    }
  }

  Future<bool> _permisosUbicacion() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _snack('Activa el GPS del teléfono para usar tu ubicación actual.');
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
      _snack('Permiso denegado permanentemente. Actívalo desde Ajustes.');
      return false;
    }

    return true;
  }

  void seleccionarPunto(LatLng latLng, {bool moverCamara = true}) {
    setState(() {
      puntoCliente = latLng;
      markers = {
        Marker(
          markerId: const MarkerId('cliente'),
          position: latLng,
          infoWindow: const InfoWindow(title: 'Ubicación del cliente'),
        ),
      };
    });

    if (moverCamara) {
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    }
  }

  void usarUbicacionActual() {
    final pos = currentPosition;
    if (pos == null) {
      _snack('Primero permite la ubicación o activa el GPS.');
      _initUbicacion();
      return;
    }
    seleccionarPunto(LatLng(pos.latitude, pos.longitude));
  }

  double parseLibras(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }

  void dlgOk(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: 'Listo',
      btnOkColor: AppColors.primary,
      btnOkOnPress: () {
        Navigator.pop(context, true);
      },
    ).show();
  }

  void dlgError(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: 'Entendido',
      btnOkColor: AppColors.primary,
      btnOkOnPress: () {},
    ).show();
  }

  void dlgConfirm({required String title, required String desc, required VoidCallback onOk}) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnCancelText: 'Cancelar',
      btnOkText: 'Sí, guardar',
      btnCancelOnPress: () {},
      btnOkColor: AppColors.primary,
      btnOkOnPress: onOk,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final esEditar = cliente != null;
    final target = puntoCliente ??
        (currentPosition == null
            ? centroEcuador
            : LatLng(currentPosition!.latitude, currentPosition!.longitude));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(esEditar ? 'Editar cliente' : 'Nuevo cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              encabezado(esEditar),
              const SizedBox(height: 18),
              campoTexto(
                controller: nombreController,
                label: 'Nombre del cliente',
                icon: Icons.person_rounded,
                hint: 'Ej. Juan el mecánico',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el nombre del cliente';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  if (v.trim().length > 60) return 'Máximo 60 caracteres';
                  return null;
                },
              ),
              campoTexto(
                controller: telefonoController,
                label: 'Teléfono',
                icon: Icons.phone_rounded,
                hint: 'Opcional',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final txt = v?.trim() ?? '';
                  if (txt.isEmpty) return null;
                  final limpio = txt.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                  if (limpio.length < 7 || limpio.length > 15) return 'Teléfono inválido';
                  return null;
                },
              ),
              campoTexto(
                controller: pedidoController,
                label: 'Pedido',
                icon: Icons.shopping_bag_rounded,
                hint: 'Ej. Pierna, carne pura, cabeza',
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa qué pidió';
                  if (v.trim().length < 3) return 'Describe mejor el pedido';
                  if (v.trim().length > 80) return 'Máximo 80 caracteres';
                  return null;
                },
              ),
              campoTexto(
                controller: librasController,
                label: 'Cantidad en libras',
                icon: Icons.scale_rounded,
                hint: 'Ej. 15.5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa las libras';
                  final lb = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (lb == null) return 'Ingresa un número válido';
                  if (lb <= 0) return 'Las libras deben ser mayor a 0';
                  if (lb > 5000) return 'Cantidad demasiado alta';
                  return null;
                },
              ),
              campoTexto(
                controller: direccionController,
                label: 'Dirección escrita',
                icon: Icons.home_rounded,
                hint: 'Ej. Barrio San Felipe, junto a la cancha',
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa la dirección';
                  if (v.trim().length < 5) return 'Dirección muy corta';
                  if (v.trim().length > 120) return 'Máximo 120 caracteres';
                  return null;
                },
              ),
              campoTexto(
                controller: referenciaController,
                label: 'Referencia',
                icon: Icons.info_outline_rounded,
                hint: 'Ej. Casa azul, portón negro',
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa una referencia';
                  if (v.trim().length < 4) return 'Referencia muy corta';
                  if (v.trim().length > 120) return 'Máximo 120 caracteres';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: estadoSeleccionado,
                decoration: inputDecoration('Estado', Icons.flag_rounded),
                items: const [
                  DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'Entregado', child: Text('Entregado')),
                ],
                onChanged: (v) => setState(() => estadoSeleccionado = v!),
              ),
              const SizedBox(height: 18),
              mapaSelector(target),
              const SizedBox(height: 22),
              botones(esEditar),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppNav.bottomMenu(2, context),
    );
  }

  Widget encabezado(bool esEditar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary, size: 31),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              esEditar
                  ? 'Actualiza los datos y ubicación del cliente'
                  : 'Registra el pedido y marca su ubicación en el mapa',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        decoration: inputDecoration(label, icon, hint: hint),
      ),
    );
  }

  Widget mapaSelector(LatLng target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación del cliente',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: target, zoom: puntoCliente == null ? 7 : 16),
            myLocationEnabled: currentPosition != null,
            myLocationButtonEnabled: false,
            markers: markers,
            onMapCreated: (controller) {
              mapController = controller;
              if (puntoCliente != null) {
                controller.animateCamera(CameraUpdate.newLatLngZoom(puntoCliente!, 16));
              } else if (currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(currentPosition!.latitude, currentPosition!.longitude),
                    15,
                  ),
                );
              }
            },
            onTap: (latLng) => seleccionarPunto(latLng),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                puntoCliente == null
                    ? 'Toca el mapa para marcar dónde vive el cliente.'
                    : 'Punto seleccionado: ${puntoCliente!.latitude.toStringAsFixed(5)}, ${puntoCliente!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: AppColors.textMuted, height: 1.3),
              ),
            ),
            TextButton.icon(
              onPressed: usarUbicacionActual,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Mi ubicación'),
            ),
          ],
        ),
      ],
    );
  }

  Widget botones(bool esEditar) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: _guardando ? null : () => guardar(esEditar),
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_guardando ? 'Guardando...' : 'Guardar'),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancelar'),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  void guardar(bool esEditar) {
    if (!formKey.currentState!.validate()) return;

    if (puntoCliente == null) {
      _snack('Selecciona la ubicación del cliente en el mapa.');
      return;
    }

    dlgConfirm(
      title: 'Confirmar',
      desc: '¿Deseas guardar este pedido?',
      onOk: () async {
        setState(() => _guardando = true);
        try {
          final repo = ClienteRepository();
          final data = ClienteModels(
            nombre: nombreController.text.trim(),
            telefono: telefonoController.text.trim(),
            pedido: pedidoController.text.trim(),
            libras: parseLibras(librasController.text),
            direccionTexto: direccionController.text.trim(),
            referencia: referenciaController.text.trim(),
            latitud: puntoCliente!.latitude,
            longitud: puntoCliente!.longitude,
            estado: estadoSeleccionado,
            fechaRegistro: cliente?.fechaRegistro ?? DateTime.now().toIso8601String(),
          );

          if (esEditar) {
            data.id = cliente!.id;
            await repo.edit(data);
          } else {
            await repo.create(data);
          }

          if (!mounted) return;
          setState(() => _guardando = false);
          dlgOk('Listo', 'Pedido guardado correctamente.');
        } catch (e) {
          if (!mounted) return;
          setState(() => _guardando = false);
          dlgError('Error', e.toString());
        }
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
