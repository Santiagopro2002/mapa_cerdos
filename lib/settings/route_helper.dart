import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/cliente_models.dart';

class RouteHelper {
  static double distanciaMetros(LatLng a, LatLng b) {
    const radioTierra = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);

    return 2 * radioTierra * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _rad(double grados) => grados * pi / 180.0;

  static List<ClienteModels> optimizarPorCercania(
    LatLng origen,
    List<ClienteModels> clientes,
  ) {
    final pendientes = List<ClienteModels>.from(clientes);
    final ruta = <ClienteModels>[];
    var actual = origen;

    while (pendientes.isNotEmpty) {
      pendientes.sort((a, b) {
        final da = distanciaMetros(actual, LatLng(a.latitud, a.longitud));
        final db = distanciaMetros(actual, LatLng(b.latitud, b.longitud));
        return da.compareTo(db);
      });

      final siguiente = pendientes.removeAt(0);
      ruta.add(siguiente);
      actual = LatLng(siguiente.latitud, siguiente.longitud);
    }

    return ruta;
  }

  static String distanciaBonita(double metros) {
    if (metros < 1000) return '${metros.toStringAsFixed(0)} m';
    return '${(metros / 1000).toStringAsFixed(1)} km';
  }
}
