import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/clients.dart'; // Added import for Client model

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'gym_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Clients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        photo TEXT,
        membership_type_id INTEGER,
        payment_status TEXT,
        start_date TEXT,
        end_date TEXT,
        is_active INTEGER DEFAULT 1,
        last_visit_date TEXT,
        current_membership_price REAL, // Added current_membership_price
        FOREIGN KEY (membership_type_id) REFERENCES Memberships(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE Memberships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        price REAL NOT NULL,
        duration_days INTEGER NOT NULL
      )
    ''');

    await db.execute("INSERT INTO Memberships (name, price, duration_days) VALUES ('Weekly', 10.0, 7)");
    await db.execute("INSERT INTO Memberships (name, price, duration_days) VALUES ('Monthly', 30.0, 30)");
    await db.execute("INSERT INTO Memberships (name, price, duration_days) VALUES ('Visit', 5.0, 1)");

    await db.execute('''
      CREATE TABLE AppSettings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute("INSERT INTO AppSettings (key, value) VALUES ('gym_name', 'My Gym')");
    await db.execute("INSERT INTO AppSettings (key, value) VALUES ('dark_mode', 'false')");
    await db.execute("INSERT INTO AppSettings (key, value) VALUES ('inactive_days_threshold', '30')");
    // Add new settings for trial/license
    await db.execute("INSERT INTO AppSettings (key, value) VALUES ('license_status', 'Uninitialized')");
    await db.execute("INSERT INTO AppSettings (key, value) VALUES ('installation_date', '')");
    await db.execute("INSERT INTO AppSettings (key, value) VALUES ('license_key', '')");
    await db.execute("INSERT INTO AppSettings (key, value) VALUES ('activated_device_id', '')");


    print("Database created with tables Clients, Memberships, and AppSettings!");
  }

  // Client CRUD Methods

  Future<int> insertClient(Client client) async {
    final db = await database;
    final membership = await getMembershipByName(client.membershipType);

    Map<String, dynamic> clientMap = client.toJson();
    if (membership != null) {
      clientMap['membership_type_id'] = membership['id'];
      clientMap['current_membership_price'] = membership['price']; // Store current price
    } else {
      // Handle case where membership type doesn't exist, perhaps throw an error or use a default
      clientMap['membership_type_id'] = null;
      clientMap['current_membership_price'] = null;
    }
    // Ensure dates are strings, and boolean is int, as per toJson() in Client model
    return await db.insert('Clients', clientMap);
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.*, m.name as membership_name, m.price as membership_price, m.duration_days as membership_duration_days
      FROM Clients c
      LEFT JOIN Memberships m ON c.membership_type_id = m.id
    ''');
    return List.generate(maps.length, (i) {
      return Client.fromJson(maps[i]);
    });
  }

  Future<Client?> getClientById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.*, m.name as membership_name, m.price as membership_price, m.duration_days as membership_duration_days
      FROM Clients c
      LEFT JOIN Memberships m ON c.membership_type_id = m.id
      WHERE c.id = ?
    ''', [id]);
    if (maps.isNotEmpty) {
      return Client.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    final membership = await getMembershipByName(client.membershipType);

    Map<String, dynamic> clientMap = client.toJson();
    if (membership != null) {
      clientMap['membership_type_id'] = membership['id'];
      clientMap['current_membership_price'] = membership['price']; // Update current price if membership changes
    } else {
      // Handle case where membership type might be invalid during an update
      // Or perhaps this scenario should be prevented by UI
      clientMap['membership_type_id'] = client.membershipTypeId; // Retain existing if not found
      clientMap['current_membership_price'] = client.currentMembershipPrice; // Retain existing
    }

    return await db.update(
      'Clients',
      clientMap,
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(String id) async {
    final db = await database;
    return await db.delete(
      'Clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateClientLastVisit(String id, DateTime visitDate) async {
    final db = await database;
    await db.update(
      'Clients',
      {'last_visit_date': visitDate.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Membership CRUD Methods
  Future<List<Map<String, dynamic>>> getMembershipTypes() async {
    final db = await database;
    return await db.query('Memberships');
  }

  Future<Map<String, dynamic>?> getMembershipByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Memberships',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> insertMembership(Map<String, dynamic> membership) async {
    final db = await database;
    return await db.insert('Memberships', membership);
  }

  Future<int> updateMembership(Map<String, dynamic> membership) async {
    final db = await database;
    return await db.update(
      'Memberships',
      membership,
      where: 'name = ?', // Assuming name is the key for updates, or use id if preferred
      whereArgs: [membership['name']],
    );
  }

  Future<int> deleteMembership(String name) async {
    final db = await database;
    return await db.delete(
      'Memberships',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  // AppSettings CRUD Methods
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'AppSettings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<int> updateSetting(String key, String value) async {
    final db = await database;
    return await db.insert(
      'AppSettings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
