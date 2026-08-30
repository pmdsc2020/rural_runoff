// lib/core/database/app_database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/catchment/models/catchment_project.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rural_runoff.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE catchments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        area_km2 REAL NOT NULL,
        flow_length_m REAL NOT NULL,
        elevation_drop_m REAL NOT NULL,
        runoff_c REAL NOT NULL,
        direct_intensity REAL,
        idf_a REAL,
        idf_b REAL,
        idf_m REAL,
        idf_n REAL,
        return_period REAL,
        latitude REAL,
        longitude REAL,
        peak_q_m3s REAL NOT NULL,
        tc_min REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertProject(CatchmentProject project) async {
    final db = await instance.database;
    return await db.insert('catchments', project.toMap());
  }

  Future<List<CatchmentProject>> getAllProjects() async {
    final db = await instance.database;
    final result = await db.query('catchments', orderBy: 'id DESC');
    return result.map((json) => CatchmentProject.fromMap(json)).toList();
  }

  Future<int> updateProject(CatchmentProject project) async {
    final db = await instance.database;
    return await db.update(
      'catchments',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await instance.database;
    return await db.delete(
      'catchments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}