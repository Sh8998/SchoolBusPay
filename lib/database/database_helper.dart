import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/user.dart';
import '../models/payment.dart';
import '../models/driver.dart';
import '../models/parent.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform is not supported for local database operations. '
        'Please use this application on desktop or mobile devices.',
      );
    }

    try {
      String path = join(await getDatabasesPath(), 'school_bus_payment.db');
      
      // For Android and iOS, use the default SQLite
      if (Platform.isAndroid || Platform.isIOS) {
        return await openDatabase(
          path,
          version: 5,
          onCreate: _createDb,
          onUpgrade: _onUpgrade,
        );
      }
      
      // For desktop platforms, ensure we're using FFI
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        if (databaseFactory.toString().contains('ffi')) {
          return await openDatabase(
            path,
            version: 5,
            onCreate: _createDb,
            onUpgrade: _onUpgrade,
          );
        } else {
          throw UnsupportedError(
            'Desktop platforms require SQLite FFI initialization. '
            'Please ensure databaseFactory is properly set.',
          );
        }
      }

      throw UnsupportedError('Unsupported platform for database operations.');
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add mobileNumber column to parents table
      await db.execute('''
        ALTER TABLE parents ADD COLUMN mobileNumber TEXT NOT NULL DEFAULT ''
      ''');
    }
    if (oldVersion < 3) {
      // Add paidDate column to payments table
      await db.execute('''
        ALTER TABLE payments ADD COLUMN paidDate TEXT
      ''');
    }
    if (oldVersion < 4) {
      // Remove mobileNumber from payments table by recreating the table
      await db.execute('CREATE TABLE payments_new (id INTEGER PRIMARY KEY AUTOINCREMENT, parentId INTEGER NOT NULL, month INTEGER NOT NULL, year INTEGER NOT NULL, amount REAL NOT NULL, isPaid INTEGER NOT NULL, dueDate TEXT NOT NULL, paidDate TEXT, FOREIGN KEY (parentId) REFERENCES parents (id))');
      await db.execute('INSERT INTO payments_new (id, parentId, month, year, amount, isPaid, dueDate, paidDate) SELECT id, parentId, month, year, amount, isPaid, dueDate, paidDate FROM payments');
      await db.execute('DROP TABLE payments');
      await db.execute('ALTER TABLE payments_new RENAME TO payments');
    }
    if (oldVersion < 5) {
      // Add unique constraint to mobileNumber in users table
      await db.execute('CREATE TABLE users_new (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, mobileNumber TEXT NOT NULL UNIQUE, role TEXT NOT NULL)');
      await db.execute('INSERT OR IGNORE INTO users_new SELECT * FROM users');
      await db.execute('DROP TABLE users');
      await db.execute('ALTER TABLE users_new RENAME TO users');

      // Add existing drivers and parents to users table if not already present
      final drivers = await db.query('drivers');
      final parents = await db.query('parents');

      for (final driver in drivers) {
        await db.insert(
          'users',
          {
            'name': driver['name'],
            'mobileNumber': driver['mobileNumber'],
            'role': 'driver'
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      for (final parent in parents) {
        await db.insert(
          'users',
          {
            'name': parent['name'],
            'mobileNumber': parent['mobileNumber'],
            'role': 'parent'
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> _createDb(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          mobileNumber TEXT NOT NULL UNIQUE,
          role TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parentId INTEGER NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          amount REAL NOT NULL,
          isPaid INTEGER NOT NULL,
          dueDate TEXT NOT NULL,
          paidDate TEXT,
          FOREIGN KEY (parentId) REFERENCES parents (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE drivers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          busNo TEXT NOT NULL,
          mobileNumber TEXT NOT NULL,
          parentIds TEXT NOT NULL DEFAULT ''
        )
      ''');

      await db.execute('''
        CREATE TABLE parents(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          mobileNumber TEXT NOT NULL,
          driverId INTEGER NOT NULL,
          paymentIds TEXT NOT NULL DEFAULT '',
          FOREIGN KEY (driverId) REFERENCES drivers (id)
        )
      ''');
    } catch (e) {
      throw Exception('Failed to create database tables: $e');
    }
  }

  // CRUD operations for User
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<int> updateUser(User user) async {
    Database db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Payment
  Future<int> insertPayment(Payment payment) async {
    Database db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPayments() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('payments');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<List<Payment>> getPaymentsByParentId(int parentId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<int> updatePayment(Payment payment) async {
    Database db = await database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    Database db = await database;
    return await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Driver
  Future<int> insertDriver(Driver driver) async {
    final Database db = await database;
    
    // Check if mobile number already exists
    if (await isMobileNumberExists(driver.mobileNumber)) {
      throw Exception('Mobile number already registered');
    }

    // Use a transaction to ensure both operations succeed or fail together
    return await db.transaction((txn) async {
      // Insert into drivers table
      final driverId = await txn.insert('drivers', driver.toMap());

      // Insert into users table
      await txn.insert('users', {
        'name': driver.name,
        'mobileNumber': driver.mobileNumber,
        'role': 'driver',
      });

      return driverId;
    });
  }

  Future<List<Driver>> getDrivers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('drivers');
    return List.generate(maps.length, (i) => Driver.fromMap(maps[i]));
  }

  Future<int> updateDriver(Driver driver) async {
    Database db = await database;
    return await db.update(
      'drivers',
      driver.toMap(),
      where: 'id = ?',
      whereArgs: [driver.id],
    );
  }

  Future<int> deleteDriver(int id) async {
    Database db = await database;
    // First, update all parents to remove this driver
    await db.update(
      'parents',
      {'driverId': null},
      where: 'driverId = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'drivers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Parent
  Future<int> insertParent(Parent parent) async {
    final Database db = await database;
    
    // Check if mobile number already exists
    if (await isMobileNumberExists(parent.mobileNumber)) {
      throw Exception('Mobile number already registered');
    }

    // Use a transaction to ensure all operations succeed or fail together
    return await db.transaction((txn) async {
      // Insert into parents table
      final parentId = await txn.insert('parents', parent.toMap());

      // Insert into users table
      await txn.insert('users', {
        'name': parent.name,
        'mobileNumber': parent.mobileNumber,
        'role': 'parent',
      });

      // Create payment record for current month
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0);
      
      final payment = Payment(
        id: 0,
        parentId: parentId,
        month: now.month,
        year: now.year,
        amount: 0.0, // Default amount, to be set by driver
        isPaid: false,
        dueDate: lastDay.toIso8601String(),
        paidDate: null,
      );
      
      await txn.insert('payments', payment.toMap());

      return parentId;
    });
  }

  Future<List<Parent>> getParents() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('parents');
    return List.generate(maps.length, (i) => Parent.fromMap(maps[i]));
  }

  Future<List<Parent>> getParentsByDriverId(int driverId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'parents',
      where: 'driverId = ?',
      whereArgs: [driverId],
    );
    return List.generate(maps.length, (i) => Parent.fromMap(maps[i]));
  }

  Future<int> updateParent(Parent parent) async {
    Database db = await database;
    return await db.update(
      'parents',
      parent.toMap(),
      where: 'id = ?',
      whereArgs: [parent.id],
    );
  }

  Future<int> deleteParent(int id) async {
    Database db = await database;
    try {
      // Start a transaction to ensure all operations complete or none do
      await db.transaction((txn) async {
        // First, delete all payments associated with this parent
        await txn.delete(
          'payments',
          where: 'parentId = ?',
          whereArgs: [id],
        );

        // Then delete the parent
        await txn.delete(
          'parents',
          where: 'id = ?',
          whereArgs: [id],
        );

        // Update the driver's parentIds list to remove this parent
        final drivers = await txn.query('drivers');
        for (final driverMap in drivers) {
          final driver = Driver.fromMap(driverMap);
          if (driver.parentIds.contains(id)) {
            final updatedParentIds = driver.parentIds.where((pid) => pid != id).toList();
            await txn.update(
              'drivers',
              {'parentIds': updatedParentIds.isEmpty ? '' : updatedParentIds.join(',')},
              where: 'id = ?',
              whereArgs: [driver.id],
            );
          }
        }
      });
      return 1; // Success
    } catch (e) {
      throw Exception('Failed to delete parent: $e');
    }
  }

  // Add method to check if mobile number exists
  Future<bool> isMobileNumberExists(String mobileNumber) async {
    final Database db = await database;
    final result = await db.query(
      'users',
      where: 'mobileNumber = ?',
      whereArgs: [mobileNumber],
    );
    return result.isNotEmpty;
  }
} 