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

    // Income Table
    await db.execute('''
      CREATE TABLE Income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        related_client_id TEXT,
        FOREIGN KEY (related_client_id) REFERENCES Clients(id) ON DELETE SET NULL
      )
    ''');

    // Expenses Table
    await db.execute('''
      CREATE TABLE Expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await db.execute('''
    CREATE TABLE PriceHistory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      membership_id INTEGER NOT NULL,
      old_price REAL NOT NULL,
      new_price REAL NOT NULL,
      change_date TEXT NOT NULL,
      FOREIGN KEY (membership_id) REFERENCES Memberships(id) ON DELETE CASCADE
    )
    ''');

    // Add Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_client_membership_type_id ON Clients(membership_type_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_client_name ON Clients(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_income_date ON Income(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expense_date ON Expenses(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pricehistory_membership_id ON PriceHistory(membership_id)');

    print("Database created with tables Clients, Memberships, AppSettings, Income, Expenses, PriceHistory, and Indexes!");
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

  Future<List<Client>> findClientsBySimilarity(String name, String? phone, String? email) async {
    final db = await database;
    String query = '''
      SELECT c.*, m.name as membership_name, m.price as membership_price, m.duration_days as membership_duration_days
      FROM Clients c
      LEFT JOIN Memberships m ON c.membership_type_id = m.id
      WHERE
    ''';
    List<String> conditions = [];
    List<dynamic> args = [];

    String normalizedName = name.trim().toLowerCase();

    if (phone != null && phone.isNotEmpty) {
      conditions.add("(LOWER(c.name) LIKE ? AND c.phone = ?)");
      args.add('%$normalizedName%');
      args.add(phone);
    }
    if (email != null && email.isNotEmpty) {
      conditions.add("(LOWER(c.name) LIKE ? AND LOWER(c.email) = ?)");
      args.add('%$normalizedName%');
      args.add(email.toLowerCase());
    }

    if (conditions.isEmpty) {
      query += "LOWER(c.name) LIKE ?";
      args.add('%$normalizedName%');
    } else {
      query += conditions.join(" OR ");
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) => Client.fromJson(maps[i]));
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
    // Use ID for updating memberships, as name can also be changed.
    return await db.update(
      'Memberships',
      membership,
      where: 'id = ?',
      whereArgs: [membership['id']],
    );
  }

  Future<int> deleteMembership(int membershipId) async { // Changed to accept int membershipId
    final db = await database;
    return await db.delete(
      'Memberships',
      where: 'id = ?', // Use ID for deleting
      whereArgs: [membershipId],
    );
  }

  // PriceHistory CRUD Methods
  Future<int> insertPriceChange(Map<String, dynamic> historyData) async {
    final db = await database;
    return await db.insert('PriceHistory', historyData);
  }

  Future<List<Map<String, dynamic>>> getPriceHistoryForMembership(int membershipId) async {
    final db = await database;
    return await db.query(
      'PriceHistory',
      where: 'membership_id = ?',
      whereArgs: [membershipId],
      orderBy: 'change_date DESC',
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

  // Income CRUD Methods
  Future<int> insertIncome(Map<String, dynamic> incomeData) async {
    final db = await database;
    return await db.insert('Income', incomeData);
  }

  Future<List<Map<String, dynamic>>> getAllIncome({String? orderBy = 'date DESC'}) async {
    final db = await database;
    return await db.query('Income', orderBy: orderBy);
  }

  // Expense CRUD Methods
  Future<int> insertExpense(Map<String, dynamic> expenseData) async {
    final db = await database;
    return await db.insert('Expenses', expenseData);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses({String? orderBy = 'date DESC'}) async {
    final db = await database;
    return await db.query('Expenses', orderBy: orderBy);
  }
}
