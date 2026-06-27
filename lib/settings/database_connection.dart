import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseConnection {
  static final DatabaseConnection instance = DatabaseConnection.internal();
  factory DatabaseConnection() => instance;
  DatabaseConnection.internal();

  static Database? database;

  Future<Database> get db async {
    if (database != null) return database!;
    database = await inicializarDb();
    return database!;
  }

  Future<Database> inicializarDb() async {
    final rutaDb = await getDatabasesPath();
    final rutaFinal = join(rutaDb, 'entregas_cerdos.db');

    return await openDatabase(
      rutaFinal,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE cliente_entrega (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          telefono TEXT NOT NULL,
          pedido TEXT NOT NULL,
          libras REAL NOT NULL,
          direccionTexto TEXT NOT NULL,
          referencia TEXT NOT NULL,
          latitud REAL NOT NULL,
          longitud REAL NOT NULL,
          estado TEXT NOT NULL,
          fechaRegistro TEXT NOT NULL
        )
        ''');
      },
    );
  }
}
