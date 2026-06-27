import '../models/cliente_models.dart';
import '../settings/database_connection.dart';
import 'package:sqflite/sqflite.dart';

class ClienteRepository {
  final tableName = 'cliente_entrega';
  final database = DatabaseConnection();

  Future<int> create(ClienteModels data) async {
    final db = await database.db;
    final map = data.toMap();
    map.remove('id');
    return await db.insert(tableName, map);
  }

  Future<int> edit(ClienteModels data) async {
    final db = await database.db;
    return await db.update(
      tableName,
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database.db;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ClienteModels>> getAll() async {
    final db = await database.db;
    final response = await db.query(
      tableName,
      orderBy: "CASE WHEN estado = 'Pendiente' THEN 0 ELSE 1 END, id DESC",
    );
    return response.map((e) => ClienteModels.fromMap(e)).toList();
  }

  Future<List<ClienteModels>> getPendientes() async {
    final db = await database.db;
    final response = await db.query(
      tableName,
      where: 'estado = ?',
      whereArgs: ['Pendiente'],
      orderBy: 'id DESC',
    );
    return response.map((e) => ClienteModels.fromMap(e)).toList();
  }

  Future<int> marcarEntregado(int id) async {
    final db = await database.db;
    return await db.update(
      tableName,
      {'estado': 'Entregado'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> marcarPendiente(int id) async {
    final db = await database.db;
    return await db.update(
      tableName,
      {'estado': 'Pendiente'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> resumen() async {
    final db = await database.db;

    final totalClientes =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
        ) ??
        0;

    final pendientes =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM $tableName WHERE estado = 'Pendiente'",
          ),
        ) ??
        0;

    final entregados =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM $tableName WHERE estado = 'Entregado'",
          ),
        ) ??
        0;

    final librasPendientes = await db.rawQuery(
      "SELECT SUM(libras) AS total FROM $tableName WHERE estado = 'Pendiente'",
    );

    final totalLibras =
        (librasPendientes.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'totalClientes': totalClientes,
      'pendientes': pendientes,
      'entregados': entregados,
      'librasPendientes': totalLibras,
    };
  }
}
