class ClienteModels {
  int? id;
  String nombre;
  String telefono;
  String pedido;
  double libras;
  String direccionTexto;
  String referencia;
  double latitud;
  double longitud;
  String estado;
  String fechaRegistro;

  ClienteModels({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.pedido,
    required this.libras,
    required this.direccionTexto,
    required this.referencia,
    required this.latitud,
    required this.longitud,
    required this.estado,
    required this.fechaRegistro,
  });

  factory ClienteModels.fromMap(Map<String, dynamic> data) {
    return ClienteModels(
      id: data['id'],
      nombre: (data['nombre'] ?? '').toString(),
      telefono: (data['telefono'] ?? '').toString(),
      pedido: (data['pedido'] ?? '').toString(),
      libras: (data['libras'] is num)
          ? (data['libras'] as num).toDouble()
          : double.tryParse('${data['libras']}') ?? 0,
      direccionTexto: (data['direccionTexto'] ?? '').toString(),
      referencia: (data['referencia'] ?? '').toString(),
      latitud: (data['latitud'] is num)
          ? (data['latitud'] as num).toDouble()
          : double.tryParse('${data['latitud']}') ?? 0,
      longitud: (data['longitud'] is num)
          ? (data['longitud'] as num).toDouble()
          : double.tryParse('${data['longitud']}') ?? 0,
      estado: (data['estado'] ?? 'Pendiente').toString(),
      fechaRegistro: (data['fechaRegistro'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'pedido': pedido,
      'libras': libras,
      'direccionTexto': direccionTexto,
      'referencia': referencia,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado,
      'fechaRegistro': fechaRegistro,
    };
  }

  bool get entregado => estado.toLowerCase() == 'entregado';
}
