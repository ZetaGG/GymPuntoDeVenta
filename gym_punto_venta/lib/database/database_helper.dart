import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Explicit FFI import
import 'package:flutter/material.dart'; // Added for DateTimeRange
import '../models/clients.dart'; // Added import for Client model
import '../models/product.dart'; // Added import for Product model

class DatabaseHelper {
  static const String TABLE_PRODUCTS = 'products'; // Nombre de la tabla de productos
  static const String DB_NAME = 'gym_database.db'; // Restored original DB name

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
    String path = join(await getDatabasesPath(), DB_NAME); // Use original DB name
    print("DatabaseHelper: _initDb: Database path: $path (Using explicit FFI factory)");

    return await databaseFactoryFfi.openDatabase( // Explicitly use databaseFactoryFfi
      path,
      options: OpenDatabaseOptions( // Use OpenDatabaseOptions for FFI
        version: 5, // Incremented version to trigger _onUpgrade for sales table
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      )
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("DatabaseHelper: _onUpgrade called, oldVersion: $oldVersion, newVersion: $newVersion");

    // Ensure Products table exists if upgrading from a version < 4
    if (oldVersion < 4) {
      print("DatabaseHelper: _onUpgrade: (oldVersion $oldVersion < 4) Ensuring $TABLE_PRODUCTS table exists.");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $TABLE_PRODUCTS (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT,
          price REAL NOT NULL,
          stock INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_product_name ON $TABLE_PRODUCTS(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_product_category ON $TABLE_PRODUCTS(category)');
      print("DatabaseHelper: _onUpgrade: Ensured $TABLE_PRODUCTS table and indexes are created for oldVersion < 4.");
    }

    // Ensure sales table exists if upgrading from a version < 5
    if (oldVersion < 5) {
      print("DatabaseHelper: _onUpgrade: (oldVersion $oldVersion < 5) Ensuring sales table exists.");
      await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        product_id TEXT,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price_per_unit REAL NOT NULL,
        total_amount REAL NOT NULL,
        sale_date TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_sale_date ON sales(sale_date)');
    print("DatabaseHelper: _onUpgrade: Ensured sales table and index are created.");
  }
}

  Future<void> _onCreate(Database db, int version) async {
    print("DatabaseHelper: _onCreate called, version: $version");

    // All CREATE TABLE statements now use IF NOT EXISTS for idempotency
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Clients (
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
        current_membership_price REAL, 
        FOREIGN KEY (membership_type_id) REFERENCES Memberships(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Memberships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        price REAL NOT NULL,
        duration_days INTEGER NOT NULL
      )
    ''');

    await db.execute("INSERT OR IGNORE INTO Memberships (name, price, duration_days) VALUES ('Weekly', 10.0, 7)");
    await db.execute("INSERT OR IGNORE INTO Memberships (name, price, duration_days) VALUES ('Monthly', 30.0, 30)");
    await db.execute("INSERT OR IGNORE INTO Memberships (name, price, duration_days) VALUES ('Visit', 5.0, 1)");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS AppSettings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute("INSERT OR IGNORE INTO AppSettings (key, value) VALUES ('gym_name', 'My Gym')");
    await db.execute("INSERT OR IGNORE INTO AppSettings (key, value) VALUES ('dark_mode', 'false')");
    await db.execute("INSERT OR IGNORE INTO AppSettings (key, value) VALUES ('inactive_days_threshold', '30')");
    await db.execute("INSERT OR IGNORE INTO AppSettings (key, value) VALUES ('license_status', 'Uninitialized')");
    await db.execute("INSERT OR IGNORE INTO AppSettings (key, value) VALUES ('installation_date', '')");
    await db.execute("INSERT OR IGNORE INTO AppSettings (key, value) VALUES ('license_key', '')");
    await db.execute("INSERT OR IGNORE INTO AppSettings (key, value) VALUES ('activated_device_id', '')");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        related_client_id TEXT,
        FOREIGN KEY (related_client_id) REFERENCES Clients(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS PriceHistory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      membership_id INTEGER NOT NULL,
      old_price REAL NOT NULL,
      new_price REAL NOT NULL,
      change_date TEXT NOT NULL,
      FOREIGN KEY (membership_id) REFERENCES Memberships(id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $TABLE_PRODUCTS (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL
      )
    ''');

    // Sales table (new)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        product_id TEXT,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price_per_unit REAL NOT NULL,
        total_amount REAL NOT NULL,
        sale_date TEXT NOT NULL
      )
    ''');

    // Add Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_client_membership_type_id ON Clients(membership_type_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_client_name ON Clients(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_income_date ON Income(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expense_date ON Expenses(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pricehistory_membership_id ON PriceHistory(membership_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_product_name ON $TABLE_PRODUCTS(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_product_category ON $TABLE_PRODUCTS(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_sale_date ON sales(sale_date)');


    print("Database created/updated with all tables (Clients, Memberships, AppSettings, Income, Expenses, PriceHistory, $TABLE_PRODUCTS, sales) and Indexes!");
  }

  // Client CRUD Methods

  Future<int> insertClient(Client client) async {
  final db = await database;
  final membership = await getMembershipByName(client.membershipType);

  Map<String, dynamic> clientMap = client.toDbJson(); // <--- Usa toDbJson, NO toJson
  if (membership != null) {
    clientMap['membership_type_id'] = membership['id'];
    clientMap['current_membership_price'] = membership['price'];
  } else {
    clientMap['membership_type_id'] = null;
    clientMap['current_membership_price'] = null;
  }
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

  Map<String, dynamic> clientMap = client.toDbJson();
  if (membership != null) {
    clientMap['membership_type_id'] = membership['id'];
    clientMap['current_membership_price'] = membership['price'];
  } else {
    clientMap['membership_type_id'] = client.membershipTypeId;
    clientMap['current_membership_price'] = client.currentMembershipPrice;
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

  // Product CRUD Methods
  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(TABLE_PRODUCTS, product.toJson(), // Changed to toJson
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(TABLE_PRODUCTS, orderBy: 'name ASC');
    return List.generate(maps.length, (i) {
      return Product.fromJson(maps[i]); // Changed to fromJson
    });
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_PRODUCTS,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first); // Changed to fromJson
    }
    return null;
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      TABLE_PRODUCTS,
      product.toJson(), // Changed to toJson
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete(
      TABLE_PRODUCTS,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateProductStock(String id, int newStock) async {
    final db = await database;
    await db.update(
      TABLE_PRODUCTS,
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sales Table CRUD
  Future<void> insertSale(Map<String, dynamic> saleData) async {
    final db = await database;
    await db.insert('sales', saleData, conflictAlgorithm: ConflictAlgorithm.replace);
    print("DatabaseHelper: Recorded sale: $saleData");
  }

  // Analytics Queries
  Future<double> sumProductSalesForMonth(String yearMonth) async { // yearMonth format: "YYYY-MM"
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT SUM(total_amount) as total FROM sales WHERE strftime('%Y-%m', sale_date) = ?",
      [yearMonth],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<double> sumMembershipRevenueForMonth(String yearMonth) async { // yearMonth format: "YYYY-MM"
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM Income WHERE type = 'Membership' AND strftime('%Y-%m', date) = ?",
      [yearMonth],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // --- Methods for Chart Data ---

  // Helper to get date format string and grouping strftime format based on period
  Map<String, String> _getDateTimeGroupFormat(TimePeriod period, String dateColumn) {
    switch (period) {
      case TimePeriod.lastMonth: // Group by day for the last month
        return {'format': '%Y-%m-%d', 'labelFormat': 'dd MMM'};
      case TimePeriod.last6Months: // Group by month
      case TimePeriod.lastYear: // Group by month
        return {'format': '%Y-%m', 'labelFormat': 'MMM yyyy'};
      default: // Default to month
        return {'format': '%Y-%m', 'labelFormat': 'MMM yyyy'};
    }
  }

  Future<List<Map<String, dynamic>>> getAggregatedSalesOverTime(DateTimeRange dateRange, TimePeriod period) async {
    final db = await database;
    final grouping = _getDateTimeGroupFormat(period, 'date');
    final String dateGroupFormat = grouping['format']!;

    // Combine Membership Income and Product Sales
    // For simplicity, this example focuses on membership income. Product sales would need a similar query on 'sales' table.
    final query = '''
      SELECT
        strftime('$dateGroupFormat', date) as time_group,
        SUM(amount) as total_sales
      FROM Income
      WHERE date BETWEEN ? AND ? AND type = 'Membership'
      GROUP BY time_group
      ORDER BY time_group ASC
    '''; // TODO: Add product sales from 'sales' table

    final List<Map<String, dynamic>> result = await db.rawQuery(query, [
      dateRange.start.toIso8601String(),
      dateRange.end.toIso8601String(),
    ]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getAggregatedProductSalesOverTime(DateTimeRange dateRange, TimePeriod period) async {
    final db = await database;
    final grouping = _getDateTimeGroupFormat(period, 'sale_date');
    final String dateGroupFormat = grouping['format']!;

    final query = '''
      SELECT
        strftime('$dateGroupFormat', sale_date) as time_group,
        SUM(total_amount) as total_product_sales
      FROM sales
      WHERE sale_date BETWEEN ? AND ?
      GROUP BY time_group
      ORDER BY time_group ASC
    ''';

    final List<Map<String, dynamic>> result = await db.rawQuery(query, [
      dateRange.start.toIso8601String(),
      dateRange.end.toIso8601String(),
    ]);
    return result;
  }


  Future<List<Map<String, dynamic>>> getCustomerCountsByMembershipType(DateTimeRange dateRange) async {
    final db = await database;
    // This query counts clients whose membership was active at any point during the dateRange.
    // A client is active if their start_date is before the range_end AND their end_date is after the range_start.
    final query = '''
      SELECT
        M.name as membership_name,
        COUNT(C.id) as client_count
      FROM Clients C
      JOIN Memberships M ON C.membership_type_id = M.id
      WHERE C.start_date <= ? AND C.end_date >= ? -- Active during the period
      GROUP BY M.name
      ORDER BY client_count DESC
    ''';
    final List<Map<String, dynamic>> result = await db.rawQuery(query, [
      dateRange.end.toIso8601String(),
      dateRange.start.toIso8601String(),
    ]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getClientActivityOverTime(DateTimeRange dateRange, TimePeriod period) async {
    final db = await database;
    final grouping = _getDateTimeGroupFormat(period, 'date');
    final String dateGroupFormat = grouping['format']!;

    // Counts income entries of type 'Membership' or 'Visit Fee' as proxies for client activity.
    // This could be refined if there's a more direct way to log visits.
    final query = '''
      SELECT
        strftime('$dateGroupFormat', date) as time_group,
        COUNT(DISTINCT related_client_id) as active_clients
      FROM Income
      WHERE date BETWEEN ? AND ? AND (type = 'Membership' OR type = 'Visit Fee') AND related_client_id IS NOT NULL
      GROUP BY time_group
      ORDER BY time_group ASC
    ''';
    final List<Map<String, dynamic>> result = await db.rawQuery(query, [
      dateRange.start.toIso8601String(),
      dateRange.end.toIso8601String(),
    ]);
    return result;
  }

  Future<Map<String, double>> getFinancialSummaryForDateRange(DateTimeRange dateRange) async {
    final db = await database;
    final String startDateStr = dateRange.start.toIso8601String();
    final String endDateStr = dateRange.end.toIso8601String();

    final productSalesResult = await db.rawQuery(
      "SELECT SUM(total_amount) as total FROM sales WHERE sale_date BETWEEN ? AND ?",
      [startDateStr, endDateStr],
    );
    double productSales = 0.0;
    if (productSalesResult.isNotEmpty && productSalesResult.first['total'] != null) {
      productSales = (productSalesResult.first['total'] as num).toDouble();
    }

    final membershipRevenueResult = await db.rawQuery(
      "SELECT SUM(amount) as total FROM Income WHERE type = 'Membership' AND date BETWEEN ? AND ?",
      [startDateStr, endDateStr],
    );
    double membershipRevenue = 0.0;
    if (membershipRevenueResult.isNotEmpty && membershipRevenueResult.first['total'] != null) {
      membershipRevenue = (membershipRevenueResult.first['total'] as num).toDouble();
    }

    return {
      'productSales': productSales,
      'membershipRevenue': membershipRevenue,
      'totalRevenue': productSales + membershipRevenue,
    };
  }
}

// Make sure TimePeriod enum is accessible here or duplicate it.
// For now, assuming it's defined in a way that's accessible or will be passed.
// If balance_dashboard_widget.dart is the only place it's defined,
// you might need to pass it as a parameter or define it in a shared file.
enum TimePeriod { lastMonth, last6Months, lastYear } // Temporary duplication for context
