import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

import '../../models/cliente_models.dart';
import '../../repositories/cliente_repository.dart';
import '../../settings/app_theme.dart';

class ClienteScreen extends StatefulWidget {
  const ClienteScreen({super.key});

  @override
  State<ClienteScreen> createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  final repo = ClienteRepository();
  final buscarController = TextEditingController();

  List<ClienteModels> lista = [];
  List<ClienteModels> filtrada = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargar();
    buscarController.addListener(filtrar);
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  Future<void> cargar() async {
    setState(() => cargando = true);
    lista = await repo.getAll();
    filtrar();
    if (mounted) setState(() => cargando = false);
  }

  void filtrar() {
    final q = buscarController.text.trim().toLowerCase();
    if (q.isEmpty) {
      filtrada = List.from(lista);
    } else {
      filtrada = lista.where((c) {
        return c.nombre.toLowerCase().contains(q) ||
            c.pedido.toLowerCase().contains(q) ||
            c.direccionTexto.toLowerCase().contains(q) ||
            c.estado.toLowerCase().contains(q);
      }).toList();
    }
    if (mounted) setState(() {});
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
      btnOkOnPress: () {},
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

  void dlgConfirm({
    required String title,
    required String desc,
    required String okText,
    required VoidCallback onOk,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnCancelText: 'Cancelar',
      btnOkText: okText,
      btnCancelOnPress: () {},
      btnOkColor: AppColors.primary,
      btnOkOnPress: onOk,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = lista.where((e) => e.estado == 'Pendiente').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes y pedidos')),
      body: RefreshIndicator(
        onRefresh: cargar,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$pendientes pedido(s) pendiente(s) de entregar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: buscarController,
                    decoration: inputDecoration(
                      'Buscar cliente',
                      Icons.search_rounded,
                      hint: 'Nombre, pedido, dirección o estado',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : filtrada.isEmpty
                      ? emptyState(
                          icon: Icons.people_alt_outlined,
                          title: 'No hay clientes registrados',
                          subtitle: 'Presiona + para registrar tu primer pedido de entrega.',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 90),
                          itemCount: filtrada.length,
                          itemBuilder: (_, i) => clienteCard(filtrada[i]),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/clientes/form');
          if (result == true) cargar();
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: AppNav.bottomMenu(1, context),
    );
  }

  Widget clienteCard(ClienteModels item) {
    final esEntregado = item.estado == 'Entregado';
    final colorEstado = esEntregado ? AppColors.success : AppColors.warning;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorEstado.withAlpha(35),
                  child: Icon(
                    esEntregado ? Icons.check_rounded : Icons.pending_actions_rounded,
                    color: colorEstado,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.nombre,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorEstado.withAlpha(35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.estado,
                    style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            infoLine(Icons.scale_rounded, '${item.libras.toStringAsFixed(2)} lb • ${item.pedido}'),
            infoLine(Icons.place_rounded, item.direccionTexto),
            if (item.referencia.trim().isNotEmpty)
              infoLine(Icons.info_outline_rounded, item.referencia),
            if (item.telefono.trim().isNotEmpty) infoLine(Icons.phone_rounded, item.telefono),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/clientes/form',
                        arguments: item,
                      );
                      if (result == true) cargar();
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.info),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => confirmarEstado(item),
                    icon: Icon(esEntregado ? Icons.undo_rounded : Icons.check_circle_rounded),
                    label: Text(esEntregado ? 'Pendiente' : 'Entregar'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.success),
                  ),
                ),
                IconButton(
                  onPressed: () => confirmarEliminar(item),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textDark, height: 1.25)),
          ),
        ],
      ),
    );
  }

  void confirmarEstado(ClienteModels item) {
    final entregar = item.estado == 'Pendiente';
    dlgConfirm(
      title: entregar ? 'Confirmar entrega' : 'Volver a pendiente',
      desc: entregar
          ? '¿Deseas marcar este pedido como entregado?'
          : '¿Deseas marcar este pedido como pendiente otra vez?',
      okText: entregar ? 'Sí, entregar' : 'Sí, cambiar',
      onOk: () async {
        try {
          if (entregar) {
            await repo.marcarEntregado(item.id!);
          } else {
            await repo.marcarPendiente(item.id!);
          }
          await cargar();
          if (!mounted) return;
          dlgOk('Listo', entregar ? 'Pedido entregado.' : 'Pedido marcado como pendiente.');
        } catch (e) {
          if (!mounted) return;
          dlgError('Error', e.toString());
        }
      },
    );
  }

  void confirmarEliminar(ClienteModels item) {
    dlgConfirm(
      title: 'Eliminar cliente',
      desc: '¿Deseas eliminar el pedido de ${item.nombre}?',
      okText: 'Sí, eliminar',
      onOk: () async {
        try {
          await repo.delete(item.id!);
          await cargar();
          if (!mounted) return;
          dlgOk('Listo', 'Cliente eliminado correctamente.');
        } catch (e) {
          if (!mounted) return;
          dlgError('Error', e.toString());
        }
      },
    );
  }
}
